from __future__ import annotations

import hashlib
import logging
import os
import secrets
import sqlite3
import time
from collections import defaultdict, deque
from contextlib import contextmanager
from pathlib import Path
from typing import Annotated

from argon2 import PasswordHasher
from argon2.exceptions import VerifyMismatchError
from fastapi import Cookie, Depends, FastAPI, Header, HTTPException, Request, Response
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, ConfigDict, Field, field_validator

APP_ENV = os.getenv("APP_ENV", "development")
DB_PATH = Path(os.getenv("DB_PATH", "/tmp/secure_webapp.db"))
SESSION_COOKIE = "__Host-session" if APP_ENV == "production" else "session"
SESSION_TTL_SECONDS = int(os.getenv("SESSION_TTL_SECONDS", "3600"))
MAX_BODY_BYTES = int(os.getenv("MAX_BODY_BYTES", "1048576"))
FRONTEND_DIR = Path(__file__).resolve().parent.parent / "frontend"

logger = logging.getLogger("secure_webapp")
logging.basicConfig(
    level=os.getenv("LOG_LEVEL", "INFO"),
    format="%(asctime)s %(levelname)s %(name)s %(message)s",
)

password_hasher = PasswordHasher()
app = FastAPI(
    title="Secure Web Application Starter",
    docs_url=None if APP_ENV == "production" else "/docs",
    redoc_url=None,
)

# Demo-only, single-process limiter. Use a shared store (e.g. Redis) in multi-instance deployments.
_rate_buckets: dict[str, deque[float]] = defaultdict(deque)


def client_key(request: Request) -> str:
    # Do not trust X-Forwarded-For unless your trusted reverse proxy strips/sets it.
    return request.client.host if request.client else "unknown"


def rate_limit(request: Request, limit: int = 30, window_seconds: int = 60) -> None:
    key = client_key(request)
    now = time.monotonic()
    bucket = _rate_buckets[key]
    while bucket and bucket[0] < now - window_seconds:
        bucket.popleft()
    if len(bucket) >= limit:
        raise HTTPException(status_code=429, detail="Too many requests")
    bucket.append(now)


@contextmanager
def db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    try:
        yield conn
        conn.commit()
    finally:
        conn.close()


def init_db() -> None:
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    with db() as conn:
        conn.executescript(
            """
            PRAGMA journal_mode=WAL;
            PRAGMA foreign_keys=ON;

            CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                email TEXT NOT NULL UNIQUE,
                password_hash TEXT NOT NULL,
                role TEXT NOT NULL DEFAULT 'user'
                    CHECK(role IN ('user','admin')),
                created_at INTEGER NOT NULL
            );

            CREATE TABLE IF NOT EXISTS sessions (
                token_hash TEXT PRIMARY KEY,
                user_id INTEGER NOT NULL,
                csrf_token TEXT NOT NULL,
                expires_at INTEGER NOT NULL,
                FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
            );

            CREATE TABLE IF NOT EXISTS notes (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                owner_id INTEGER NOT NULL,
                title TEXT NOT NULL,
                body TEXT NOT NULL,
                FOREIGN KEY(owner_id) REFERENCES users(id) ON DELETE CASCADE
            );
            """
        )


@app.on_event("startup")
def startup() -> None:
    if APP_ENV == "production" and str(DB_PATH).startswith("/tmp/"):
        raise RuntimeError("Production DB_PATH must use persistent protected storage")
    init_db()


class RegisterRequest(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)
    email: str = Field(min_length=5, max_length=254)
    password: str = Field(min_length=14, max_length=256)

    @field_validator("email")
    @classmethod
    def normalize_email(cls, value: str) -> str:
        value = value.lower()
        if value.count("@") != 1 or value.startswith("@") or value.endswith("@"):
            raise ValueError("invalid email")
        local, domain = value.split("@", 1)
        if not local or "." not in domain or any(c.isspace() for c in value):
            raise ValueError("invalid email")
        return value


class LoginRequest(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)
    email: str = Field(min_length=5, max_length=254)
    password: str = Field(min_length=1, max_length=256)


class NoteCreate(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)
    title: str = Field(min_length=1, max_length=120)
    body: str = Field(min_length=1, max_length=5000)


class NoteOut(BaseModel):
    id: int
    title: str
    body: str


class UserOut(BaseModel):
    id: int
    email: str
    role: str


def hash_session_token(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


def new_session(user_id: int) -> tuple[str, str]:
    raw = secrets.token_urlsafe(32)
    csrf = secrets.token_urlsafe(32)
    expiry = int(time.time()) + SESSION_TTL_SECONDS
    with db() as conn:
        conn.execute("DELETE FROM sessions WHERE expires_at < ?", (int(time.time()),))
        conn.execute(
            "INSERT INTO sessions(token_hash, user_id, csrf_token, expires_at) VALUES (?, ?, ?, ?)",
            (hash_session_token(raw), user_id, csrf, expiry),
        )
    return raw, csrf


def set_session_cookie(response: Response, raw_token: str) -> None:
    response.set_cookie(
        key=SESSION_COOKIE,
        value=raw_token,
        max_age=SESSION_TTL_SECONDS,
        secure=(APP_ENV == "production"),
        httponly=True,
        samesite="strict",
        path="/",
    )


def delete_session_cookie(response: Response) -> None:
    response.delete_cookie(
        key=SESSION_COOKIE,
        secure=(APP_ENV == "production"),
        httponly=True,
        samesite="strict",
        path="/",
    )


def current_user(
    session: Annotated[str | None, Cookie(alias=SESSION_COOKIE)] = None,
) -> sqlite3.Row:
    if not session:
        raise HTTPException(status_code=401, detail="Authentication required")
    with db() as conn:
        row = conn.execute(
            """
            SELECT u.id, u.email, u.role, s.csrf_token, s.expires_at
            FROM sessions s
            JOIN users u ON u.id = s.user_id
            WHERE s.token_hash = ?
            """,
            (hash_session_token(session),),
        ).fetchone()
    if not row or row["expires_at"] < int(time.time()):
        raise HTTPException(status_code=401, detail="Authentication required")
    return row


def require_csrf(
    user: Annotated[sqlite3.Row, Depends(current_user)],
    x_csrf_token: Annotated[str | None, Header()] = None,
) -> sqlite3.Row:
    if not x_csrf_token or not secrets.compare_digest(x_csrf_token, user["csrf_token"]):
        raise HTTPException(status_code=403, detail="CSRF validation failed")
    return user


@app.middleware("http")
async def security_middleware(request: Request, call_next):
    content_length = request.headers.get("content-length")
    if content_length:
        try:
            if int(content_length) > MAX_BODY_BYTES:
                return JSONResponse(status_code=413, content={"detail": "Request too large"})
        except ValueError:
            return JSONResponse(status_code=400, content={"detail": "Invalid request"})

    try:
        response = await call_next(request)
    except Exception:
        # Log the exception server-side; never expose stack traces to clients.
        logger.exception("Unhandled application error")
        return JSONResponse(status_code=500, content={"detail": "Internal server error"})

    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["Referrer-Policy"] = "no-referrer"
    response.headers["Permissions-Policy"] = "camera=(), microphone=(), geolocation=()"
    response.headers["Content-Security-Policy"] = (
        "default-src 'self'; "
        "script-src 'self'; "
        "style-src 'self'; "
        "img-src 'self' data:; "
        "connect-src 'self'; "
        "object-src 'none'; "
        "frame-ancestors 'none'; "
        "base-uri 'none'; "
        "form-action 'self'"
    )
    response.headers["Cache-Control"] = "no-store"
    if APP_ENV == "production":
        response.headers["Strict-Transport-Security"] = "max-age=63072000; includeSubDomains"
    return response


if FRONTEND_DIR.exists():
    app.mount("/static", StaticFiles(directory=FRONTEND_DIR), name="static")


@app.get("/", include_in_schema=False)
def frontend_index():
    index = FRONTEND_DIR / "index.html"
    if not index.exists():
        raise HTTPException(status_code=404, detail="Not found")
    return FileResponse(index)


@app.get("/static/app.js", include_in_schema=False)
def frontend_js():
    return FileResponse(FRONTEND_DIR / "app.js", media_type="application/javascript")


@app.get("/static/app.css", include_in_schema=False)
def frontend_css():
    return FileResponse(FRONTEND_DIR / "app.css", media_type="text/css")


@app.get("/healthz")
def healthz():
    return {"status": "ok"}


@app.post("/register", status_code=201)
def register(payload: RegisterRequest, request: Request):
    rate_limit(request, limit=5, window_seconds=60)
    try:
        password_hash = password_hasher.hash(payload.password)
        with db() as conn:
            cur = conn.execute(
                (
                    "INSERT INTO users(email, password_hash, role, created_at) "
                    "VALUES (?, ?, 'user', ?)"
                ),
                (payload.email, password_hash, int(time.time())),
            )
            user_id = int(cur.lastrowid)
    except sqlite3.IntegrityError:
        # Avoid leaking whether a specific account exists in more sensitive deployments.
        raise HTTPException(status_code=409, detail="Account cannot be created") from None
    logger.info("security_event=account_created user_id=%s", user_id)
    return {"created": True}


@app.post("/login")
def login(payload: LoginRequest, request: Request, response: Response):
    rate_limit(request, limit=8, window_seconds=60)
    with db() as conn:
        row = conn.execute(
            "SELECT id, password_hash FROM users WHERE email = ?",
            (payload.email.lower(),),
        ).fetchone()

    valid = False
    if row:
        try:
            valid = password_hasher.verify(row["password_hash"], payload.password)
        except VerifyMismatchError:
            valid = False

    if not valid:
        logger.warning("security_event=login_failed client=%s", client_key(request))
        raise HTTPException(status_code=401, detail="Invalid credentials")

    raw, csrf = new_session(int(row["id"]))
    set_session_cookie(response, raw)
    logger.info("security_event=login_success user_id=%s", row["id"])
    return {"authenticated": True, "csrf_token": csrf}


@app.post("/logout", status_code=204)
def logout(
    response: Response,
    user: Annotated[sqlite3.Row, Depends(require_csrf)],
    session: Annotated[str | None, Cookie(alias=SESSION_COOKIE)] = None,
):
    if session:
        with db() as conn:
            conn.execute(
                "DELETE FROM sessions WHERE token_hash = ?",
                (hash_session_token(session),),
            )
    delete_session_cookie(response)
    response.status_code = 204
    logger.info("security_event=logout user_id=%s", user["id"])
    return response


@app.get("/me", response_model=UserOut)
def me(user: Annotated[sqlite3.Row, Depends(current_user)]):
    return UserOut(id=user["id"], email=user["email"], role=user["role"])


@app.post("/notes", response_model=NoteOut, status_code=201)
def create_note(
    payload: NoteCreate,
    user: Annotated[sqlite3.Row, Depends(require_csrf)],
):
    with db() as conn:
        cur = conn.execute(
            "INSERT INTO notes(owner_id, title, body) VALUES (?, ?, ?)",
            (user["id"], payload.title, payload.body),
        )
        note_id = int(cur.lastrowid)
    return NoteOut(id=note_id, title=payload.title, body=payload.body)


@app.get("/notes/{note_id}", response_model=NoteOut)
def get_note(
    note_id: int,
    user: Annotated[sqlite3.Row, Depends(current_user)],
):
    if note_id < 1:
        raise HTTPException(status_code=404, detail="Not found")
    with db() as conn:
        # Object-level authorization is enforced in the query itself.
        row = conn.execute(
            "SELECT id, title, body FROM notes WHERE id = ? AND owner_id = ?",
            (note_id, user["id"]),
        ).fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Not found")
    return NoteOut(id=row["id"], title=row["title"], body=row["body"])


@app.delete("/notes/{note_id}", status_code=204)
def delete_note(
    note_id: int,
    user: Annotated[sqlite3.Row, Depends(require_csrf)],
):
    with db() as conn:
        cur = conn.execute(
            "DELETE FROM notes WHERE id = ? AND owner_id = ?",
            (note_id, user["id"]),
        )
    if cur.rowcount != 1:
        raise HTTPException(status_code=404, detail="Not found")
    return Response(status_code=204)
