# Secure Web App Master Implementation Checklist

This checklist separates capabilities already present in `main` from work that must still be completed or verified before treating a deployment as production-ready.

## Implemented foundation

- [x] FastAPI backend and browser frontend.
- [x] Argon2 password hashing.
- [x] Opaque server-side sessions with hashed stored tokens.
- [x] CSRF verification on authenticated state changes.
- [x] Object-level authorization for user-owned notes.
- [x] Parameterized SQLite queries.
- [x] Strict Pydantic request validation.
- [x] Security headers, request-size checks, rate limiting, safe errors, and security-event logging.
- [x] Security regression tests for core authentication/authorization/input boundaries.
- [x] Ruff, Bandit, strict `pip-audit`, CodeQL, Dependabot, and CycloneDX SBOM automation.
- [x] Development installer and safe automated lint/format fix mode.
- [x] Hardened Docker Compose path.
- [x] Hardened Linux/systemd path.

## Repository governance

- [ ] Review `.github/CODEOWNERS` for actual maintainers.
- [ ] Configure branch protection/rulesets for `main`.
- [ ] Require appropriate pull-request review and passing status checks.
- [ ] Enable private vulnerability reporting.
- [ ] Confirm Dependabot alerts/security updates are enabled.
- [ ] Enable secret scanning and push protection where available.
- [ ] Review GitHub Actions permissions and third-party action pinning policy.

## Verification before production

- [ ] Confirm all GitHub Actions workflows pass on the intended release commit.
- [ ] Run `./install.sh --dev` from a clean clone.
- [ ] Build and smoke-test the Docker deployment from a clean clone.
- [ ] Verify no `.env`, database, token, private-key, or credential-bearing files are tracked.
- [ ] Review all dependency and code-scanning alerts.
- [ ] Review authentication/authorization rules against the real business domain.
- [ ] Perform a deployment-specific threat model.
- [ ] Perform an independent security review/penetration test appropriate to risk.

## Production infrastructure

- [ ] Configure trusted TLS reverse proxy/load balancer.
- [ ] Define trusted forwarded-header/IP behavior.
- [ ] Replace the process-local rate limiter for multi-instance deployment.
- [ ] Define production database/migration strategy if SQLite is not sufficient.
- [ ] Configure secrets management and rotation.
- [ ] Configure centralized logs, metrics, security alerts, and operational ownership.
- [ ] Define and test backup/restore and disaster-recovery procedures.
- [ ] Define resource sizing, availability targets, and scaling behavior.
- [ ] Configure deployment environments, approvals, and least-privilege deployment credentials.

## Release and supply chain

- [ ] Establish supported-version and vulnerability-response SLAs.
- [ ] Add container vulnerability scanning.
- [ ] Add artifact/container provenance and signing/attestation.
- [ ] Verify SBOM retention/distribution policy.
- [ ] Test release rollback with representative persistent data.
- [ ] Update `CHANGELOG.md` and release notes for each release.

## Documentation

- [x] Project README reflects the actual Secure Web App Master implementation.
- [x] `ABOUT.md` describes project scope and lifecycle.
- [x] `docs/architecture.md` documents components and trust boundaries.
- [x] `docs/development.md` documents the real development/security workflow.
- [x] `docs/release.md` documents release/deployment boundaries.
- [x] `SECURITY.md` documents the current security model and reporting policy.
- [x] `ROADMAP.md` distinguishes implemented controls from planned hardening.
- [ ] Add ADRs for future material architectural/security decisions.

A checked repository control does not automatically make every downstream application secure; application-specific threat modeling, authorization, infrastructure, operations, and testing remain mandatory.
