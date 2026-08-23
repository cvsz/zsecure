import importlib
import os
import sys
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

REPO_ROOT = Path(__file__).resolve().parents[1]
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

TEST_DB = "/tmp/secure_webapp_test.db"
os.environ["APP_ENV"] = "test"
os.environ["DB_PATH"] = TEST_DB

main = importlib.import_module("app.main")
client = TestClient(main.app)


def setup_module():
    try:
        os.remove(TEST_DB)
    except FileNotFoundError:
        pass
    main.init_db()


def register_and_login(email="alice@example.com"):
    password = "correct horse battery staple 2026!"
    r = client.post("/register", json={"email": email, "password": password})
    assert r.status_code in (201, 409)
    r = client.post("/login", json={"email": email, "password": password})
    assert r.status_code == 200
    return r.json()["csrf_token"]


def test_security_headers():
    r = client.get("/healthz")
    assert r.headers["x-content-type-options"] == "nosniff"
    assert r.headers["x-frame-options"] == "DENY"
    assert "default-src 'self'" in r.headers["content-security-policy"]


def test_rejects_extra_fields():
    r = client.post(
        "/register",
        json={
            "email": "extra@example.com",
            "password": "correct horse battery staple 2026!",
            "is_admin": True,
        },
    )
    assert r.status_code == 422


def test_auth_csrf_and_object_authorization():
    csrf = register_and_login()
    r = client.post(
        "/notes",
        json={"title": "private", "body": "<script>alert(1)</script>"},
        headers={"X-CSRF-Token": csrf},
    )
    assert r.status_code == 201
    note_id = r.json()["id"]

    r = client.post("/notes", json={"title": "blocked", "body": "no csrf"})
    assert r.status_code == 403

    client.cookies.clear()
    register_and_login("bob@example.com")
    r = client.get(f"/notes/{note_id}")
    assert r.status_code == 404


def test_parameterized_lookup_resists_sql_injection():
    client.cookies.clear()
    r = client.post(
        "/login",
        json={"email": "' OR 1=1 --@example.com", "password": "irrelevant"},
    )
    assert r.status_code in (401, 422)


def test_untrusted_peer_cannot_spoof_forwarded_client_ip():
    assert (
        main.extract_client_ip(
            peer_ip="198.51.100.9",
            forwarded_for="203.0.113.8",
            trusted_proxy_networks=("10.0.0.0/8",),
        )
        == "198.51.100.9"
    )


def test_trusted_proxy_uses_first_valid_forwarded_client_ip():
    assert (
        main.extract_client_ip(
            peer_ip="10.0.0.2",
            forwarded_for="203.0.113.8, 10.0.0.3",
            trusted_proxy_networks=("10.0.0.0/8",),
        )
        == "203.0.113.8"
    )


def test_production_shared_rate_limit_requires_redis():
    with pytest.raises(RuntimeError, match="RATE_LIMIT_REDIS_URL"):
        main.validate_runtime_configuration(
            app_env="production",
            db_path=Path("/data/app.db"),
            temp_dir=Path("/tmp"),
            require_shared_rate_limit=True,
            rate_limit_redis_url="",
        )
