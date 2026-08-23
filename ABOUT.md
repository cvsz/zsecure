# About Secure Web App Master

**Secure Web App Master (`zsecure`)** is a security-first full-stack web application starter designed to make secure development, deployment, maintenance, vulnerability management, and continuous verification part of the application lifecycle from the beginning.

Rather than treating security as a final penetration-testing step, the project integrates **prevention → detection → remediation → testing → updating → verification → deployment** into one workflow.

## What it includes

The implementation combines a FastAPI backend, a lightweight browser frontend, and SQLite persistence with secure authentication and authorization controls. The current application includes Argon2 password hashing, server-side sessions, CSRF protection, object-level authorization, parameterized queries, strict Pydantic validation, security headers, request-size limits, rate limiting, protected error handling, and security-event logging.

The automation layer adds:

- One-command development, Docker, and Linux/systemd installation.
- Ruff linting and formatting.
- Bandit and CodeQL SAST.
- Dependency vulnerability detection with `pip-audit`.
- Dependabot updates for Python, Docker, and GitHub Actions.
- Security regression tests for authentication, CSRF, authorization, validation, headers, and injection resistance.
- CycloneDX SBOM generation.
- CI security gates and installer validation.
- Container hardening with non-root execution, dropped capabilities, read-only filesystem, resource limits, and `no-new-privileges`.
- Linux service hardening through systemd sandboxing and least-privilege controls.

## Security philosophy

Anything outside the current trust boundary may be manipulated. Browsers, API requests, identifiers, cookies, headers, submitted content, dependencies, and stored values originating from external systems must therefore be treated as untrusted until validated and authorized.

Security controls are enforced primarily server-side. The design favors deny-by-default authorization, least privilege, defense in depth, secure defaults, explicit validation, minimal exposure, and continuous verification.

## Automated lifecycle

**Develop → Scan → Find → Fix → Test → Audit → Update → Upgrade → Verify → Build → Deploy → Monitor → Repeat**

Safe mechanical changes may be automated. High-impact dependency upgrades, authorization changes, architecture changes, and production security decisions remain reviewable rather than being blindly auto-applied.

## Deployment model

Local development uses a Python virtual environment. Docker Compose provides a hardened container path, while Linux hosts can install a sandboxed systemd service. Production-oriented paths bind Uvicorn to `127.0.0.1:8000`; a trusted reverse proxy or load balancer should provide TLS termination and public ingress controls.

## Intended use

`zsecure` is suitable as a secure application foundation, DevSecOps reference implementation, internal application template, security training project, or starting point for authorized security-sensitive web systems.

It remains a foundation. Application-specific business authorization, infrastructure, secrets management, threat models, monitoring, backups, incident response, availability design, and penetration testing must be designed for the actual production environment.
