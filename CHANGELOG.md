# Changelog

All notable changes to Secure Web App Master are documented here. The project follows Keep a Changelog conventions and intends to use Semantic Versioning for tagged releases.

## [Unreleased]

### Added

- Secure FastAPI application with lightweight browser frontend.
- Argon2 password hashing and opaque server-side sessions.
- CSRF protection and object-level authorization for authenticated note operations.
- Strict Pydantic validation and parameterized SQLite queries.
- Security headers, request-size limits, rate limiting, protected error handling, and security-event logging.
- Security regression tests covering headers, unknown-field rejection, authentication, CSRF, object authorization, and SQL-injection resistance.
- Master installer supporting development, automated safe fixes, Docker deployment, and hardened Linux/systemd installation.
- Hardened Dockerfile and Compose configuration with non-root execution, read-only filesystem, dropped capabilities, `no-new-privileges`, process limits, memory limit, and protected writable storage.
- Ruff, Bandit, `pip-audit`, CycloneDX SBOM generation, and pre-commit hooks.
- GitHub Actions workflows for repository validation, security verification, installer validation, and Python CodeQL analysis.
- Dependabot configuration for Python, Docker, and GitHub Actions.

### Changed

- Converted the repository from the generic `ztemplate` baseline into the Secure Web App Master implementation.
- Replaced template documentation with project-specific installation, architecture, security, development, release, and roadmap documentation.

### Security

- Production startup rejects temporary `/tmp` database storage.
- Production session cookies use secure cookie behavior and the `__Host-` cookie name.
- Docker and systemd deployment paths bind Uvicorn to localhost so public TLS/ingress can be handled by a trusted reverse proxy.
- Automated dependency auditing is strict by default; skipping it requires an explicit installer option.

## Initial repository baseline — 2026-08-23

- Repository governance, security policy, issue/PR templates, CI baseline, CodeQL, dependency review, Dependabot, documentation skeleton, Docker placeholder, and engineering checklist created from the repository-template foundation.
