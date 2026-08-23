# Secure Web App Master Roadmap

The roadmap prioritizes verifiable security improvements over feature volume. Completed items describe capabilities already present in `main`; unchecked items are planned or environment-specific work and must not be treated as implemented.

## Foundation — implemented

- [x] FastAPI backend and lightweight browser frontend.
- [x] Argon2 password hashing.
- [x] Opaque server-side sessions and CSRF protection.
- [x] Object-level authorization for protected resources.
- [x] Parameterized SQLite access and strict request validation.
- [x] Security headers, request-size controls, local rate limiting, safe error responses, and security-event logging.
- [x] Security regression tests.
- [x] Ruff, Bandit, `pip-audit`, CodeQL, Dependabot, and pre-commit checks.
- [x] CycloneDX SBOM generation.
- [x] Automated development installer and safe-fix mode.
- [x] Hardened Docker Compose deployment.
- [x] Hardened Linux/systemd deployment.
- [x] Project-specific architecture, security, development, release, and implementation documentation.

## Near-term hardening

- [ ] Replace remaining generic repository-template placeholders in engineering helpers and community files where applicable.
- [ ] Make the Makefile execute the real formatter, linter, tests, security checks, and container build rather than placeholder commands.
- [ ] Add a supported Python-version CI matrix and explicitly document runtime support policy.
- [ ] Add container image vulnerability scanning.
- [ ] Add secret scanning/push-protection verification to repository setup documentation and rulesets.
- [ ] Add OpenSSF Scorecard or equivalent repository-security posture checks.
- [ ] Pin or policy-manage third-party GitHub Actions according to the repository's supply-chain policy.
- [ ] Add artifact attestations/provenance for release artifacts and container images.
- [ ] Expand tests for session expiry, logout/revocation, rate-limit behavior, request-size edge cases, production cookie attributes, and failure paths.

## Production-readiness extensions

- [ ] Define a trusted reverse-proxy reference configuration with TLS, forwarded-header trust rules, and request limits.
- [ ] Replace the single-process in-memory rate limiter with a shared store for multi-instance deployments.
- [ ] Define a production database option, migrations, backup/restore, and recovery testing.
- [ ] Add structured/centralized security-event logging and operational alerting.
- [ ] Add health/readiness separation and deployment smoke tests.
- [ ] Add backup, restore, disaster-recovery, and rollback runbooks.
- [ ] Add deployment environments with approvals and least-privilege credentials.
- [ ] Add DAST and targeted fuzz/property testing where appropriate.

## Application-security maturity

- [ ] Maintain a repository threat model covering assets, trust boundaries, abuse cases, and attacker goals.
- [ ] Map relevant controls/tests to OWASP ASVS requirements.
- [ ] Add authorization-matrix tests as the domain grows.
- [ ] Add security tests for any future file uploads, external integrations, background jobs, webhooks, or privileged admin functions.
- [ ] Establish vulnerability response SLAs and a supported-version policy before the first production release.
- [ ] Schedule independent security review/penetration testing for production deployments.

Security gates should be fixed when they fail, not weakened to obtain a green build.
