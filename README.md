# zSecure Web App Master

Security-first full-stack web application starter and DevSecOps reference implementation built around FastAPI, a lightweight browser frontend, SQLite, hardened deployment defaults, and continuous security verification.

The project treats security as an application-lifecycle concern: **Develop → Scan → Find → Fix → Test → Audit → Update → Upgrade → Verify → Build → Deploy → Monitor → Repeat**.

## Current status

The working implementation is present on `main`. It includes the application, security regression tests, automated installer, Docker/systemd deployment paths, dependency automation, CodeQL, Bandit, `pip-audit`, Ruff, and CycloneDX SBOM generation.

This repository is a secure foundation, not a claim of automatic perfect security. Production deployments still require environment-specific threat modeling, authorization review, secret management, monitoring, backup/recovery, incident response, TLS termination, and penetration testing.

## Security controls

- Argon2 password hashing
- Opaque server-side sessions with hashed session tokens
- HttpOnly, SameSite=Strict cookies; Secure/`__Host-` cookie behavior in production
- CSRF validation for state-changing authenticated requests
- Object-level authorization enforced in database queries
- Parameterized SQLite queries
- Pydantic validation with unknown fields rejected
- Request-size limits and rate limiting
- Restrictive CSP and security headers
- Generic client errors with server-side security logging
- Production startup guard against `/tmp` database storage

## Automation and supply-chain security

- Ruff linting/formatting
- Pytest security regression tests
- Bandit SAST
- `pip-audit --strict` dependency vulnerability gate
- GitHub CodeQL for Python
- Dependabot for Python, Docker, and GitHub Actions
- CycloneDX SBOM generation
- Installer syntax/bootstrap validation in GitHub Actions
- Pre-commit security/lint hooks

## Installation

Requirements: Python 3.11+ for local/systemd installation. Docker deployment requires Docker with Compose v2.

```bash
./install.sh --dev --run
```

Apply safe mechanical lint/format fixes and run verification:

```bash
./install.sh --dev --fix
```

Run the hardened Docker Compose deployment:

```bash
./install.sh --docker
```

Install the hardened Linux systemd service:

```bash
sudo ./install.sh --production --systemd
```

The Docker and systemd deployment paths bind the application to `127.0.0.1:8000`; terminate TLS at a trusted reverse proxy or load balancer before public exposure.

## Repository layout

```text
app/                    FastAPI application and security controls
frontend/               Browser frontend
tests/                  Application/security regression tests
scripts/                Security check/fix helpers
.github/workflows/       CI, CodeQL, security and installer validation
install.sh               Master installer
uninstall.sh             Safe uninstall helper
Dockerfile               Non-root container image
compose.yaml             Hardened local container deployment
requirements*.txt        Runtime/development dependency sets
docs/                    Architecture, development and release docs
SECURITY.md              Vulnerability reporting and security policy
ROADMAP.md               Prioritized project hardening roadmap
```

## Design principles

- Enforce controls server-side at trust boundaries.
- Deny by default and apply least privilege.
- Prefer safe, explicit, reviewable changes over blind auto-remediation.
- Do not weaken security gates merely to make CI pass.
- Keep secrets and sensitive runtime data out of source control.
- Treat dependencies, browsers, headers, identifiers, cookies and submitted data as potentially manipulated.

## Known constraints

The built-in rate limiter is intentionally single-process and in-memory; multi-instance production deployments need a shared rate-limit store. SQLite is suitable for this reference implementation but larger/high-availability deployments should define a production persistence design. The included frontend and notes domain are deliberately small so the security boundaries remain easy to inspect.

See `docs/architecture.md`, `docs/development.md`, `SECURITY.md`, `IMPLEMENTATION-CHECKLIST.md`, and `ROADMAP.md` for deeper project guidance.

## License

MIT. See `LICENSE`.
