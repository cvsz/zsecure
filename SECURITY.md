# Security Policy

Security is a core delivery requirement of Secure Web App Master. The repository is intended to demonstrate secure defaults and continuous verification, but every real deployment must still perform environment-specific security review and threat modeling.

## Reporting a vulnerability

Do not disclose exploitable vulnerabilities in public issues, pull requests, discussions, or commit messages. Prefer GitHub Private Vulnerability Reporting / Security Advisories when enabled for this repository. If that channel is unavailable, contact the repository owner through an agreed private channel.

A useful report includes affected commit/version, prerequisites, reproduction steps, expected and observed behavior, impact, and suggested remediation when known. Avoid including unnecessary sensitive data or real credentials.

## Supported versions

The project is currently pre-release and `main` is the active development line. No long-term supported production release has been declared yet. A formal supported-version and vulnerability-response policy should be established before the first production release.

## Security model

The application treats browsers, API inputs, identifiers, cookies, headers, submitted content, dependency artifacts, and data crossing trust boundaries as potentially attacker-controlled.

Current controls include:

- Argon2 password hashing.
- Random opaque session tokens stored only as SHA-256 hashes server-side.
- HttpOnly and SameSite=Strict session cookies, with Secure/`__Host-` behavior in production.
- CSRF-token verification for authenticated state-changing requests.
- Object-level authorization bound into protected-resource SQL queries.
- Parameterized SQL and strict Pydantic request models.
- Request-size limits and rate limiting.
- Restrictive CSP, frame, MIME, referrer, permissions, cache, and production HSTS headers.
- Generic error responses with server-side exception logging.
- Security-event logging for account creation, login success/failure, and logout.
- Production refusal to use `/tmp` as database storage.

## Automated security verification

The repository uses or configures:

- Pytest security regression tests.
- Ruff linting/formatting.
- Bandit SAST.
- `pip-audit --strict` dependency auditing.
- GitHub CodeQL for Python.
- Dependabot for Python, Docker, and GitHub Actions.
- CycloneDX SBOM generation.
- GitHub Actions installer/security checks.
- Pre-commit lint/security hooks.

Do not disable or weaken these gates merely to obtain a passing build. Fix the underlying issue or document and review a narrowly scoped exception.

## Deployment security

The Docker and systemd deployment paths expose Uvicorn only on `127.0.0.1:8000`. A production deployment should place a trusted reverse proxy/load balancer in front of the service, terminate TLS there, configure forwarded-header trust explicitly, and enforce environment-appropriate network controls.

The included rate limiter is single-process and in-memory and is not sufficient for a horizontally scaled deployment. Production deployments requiring multiple processes/instances should use a shared rate-limit backend.

Secrets and production credentials must not be committed. Use an appropriate secrets-management mechanism and restrict runtime/file permissions according to least privilege.

## Incident handling

A production operator should maintain procedures for detection, triage, containment, credential/session revocation, dependency or image replacement, data recovery, remediation verification, disclosure, and rollback. Security events should be retained and protected according to the deployment's threat model and compliance requirements.
