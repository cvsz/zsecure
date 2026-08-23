# Secure Web App Master Checklist Completion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete every repository-controlled item in `IMPLEMENTATION-CHECKLIST.md`, add executable production/security runbooks for environment-dependent items, and preserve evidence-based status rather than marking external validations complete without proof.

**Architecture:** Keep the existing FastAPI/SQLite starter small and secure by default, while adding a production deployment profile around it: trusted reverse proxy/TLS, explicit proxy trust configuration, optional Redis-backed rate limiting for multi-instance deployments, backup/restore tooling, supply-chain workflows, threat-model/ADR/operations documentation, and verification automation. Repository governance settings that require GitHub account-level toggles are documented and verified where the available API exposes evidence; they are not falsely marked complete when the connector cannot mutate or confirm them.

**Tech Stack:** FastAPI, Python 3.14, SQLite, Redis, Docker Compose, Caddy, GitHub Actions, Trivy, GitHub artifact attestations, CycloneDX, Ruff, pytest, Bandit, pip-audit, CodeQL.

**Spec:** `IMPLEMENTATION-CHECKLIST.md`

## Global Constraints

- Keep authorization deny-by-default and server-side.
- Do not weaken Ruff, Bandit, pip-audit, CodeQL, Dependency Review, installer validation, or CI gates.
- Production cookies remain secure and `SameSite=Strict`.
- Production database storage must remain outside temporary filesystems.
- Forwarded client identity is trusted only from configured proxy networks.
- External/human-only checks remain explicitly pending until evidence exists.

---

### Task 1: Governance and architecture evidence

**Files:**
- Modify: `.github/CODEOWNERS`
- Create: `docs/security/threat-model.md`
- Create: `docs/security/github-settings.md`
- Create: `docs/adr/0001-security-boundaries.md`
- Create: `docs/adr/README.md`

**Interfaces:**
- Consumes: existing repository ownership, security model, and GitHub workflows.
- Produces: explicit ownership and repeatable governance/threat-model evidence.

- [ ] **Step 1:** Replace generated CODEOWNERS text with project-specific ownership for source, workflows, security docs, deployment files, and dependency manifests.
- [ ] **Step 2:** Document assets, actors, trust boundaries, threats, controls, residual risks, and review triggers in the threat model.
- [ ] **Step 3:** Document exact GitHub repository settings required for branch protection, private vulnerability reporting, Dependabot, secret scanning, push protection, least-privilege workflow permissions, and action pinning.
- [ ] **Step 4:** Add ADR index/template policy and record the initial security-boundary ADR.

### Task 2: Production edge and multi-instance controls

**Files:**
- Modify: `app/main.py`
- Modify: `requirements.txt`
- Modify: `compose.yaml`
- Modify: `Dockerfile`
- Create: `Caddyfile`
- Modify: `tests/test_security.py`

**Interfaces:**
- Consumes: `TRUSTED_PROXY_NETWORKS`, `RATE_LIMIT_REDIS_URL` environment variables.
- Produces: `client_key(request) -> str` that accepts forwarded identity only from trusted proxies and `rate_limit(...)` that uses Redis atomically when configured, otherwise process-local limiting for single-instance development.

- [ ] **Step 1:** Add tests proving untrusted `X-Forwarded-For` is ignored and trusted proxy forwarding selects the first valid client address.
- [ ] **Step 2:** Add tests proving production startup requires shared Redis rate limiting when `REQUIRE_SHARED_RATE_LIMIT=true`.
- [ ] **Step 3:** Implement CIDR-based trusted proxy evaluation and optional Redis fixed-window counters with expiry.
- [ ] **Step 4:** Add Caddy TLS reverse proxy and Docker Compose production services for app + Redis + Caddy with health checks and private backend networking.
- [ ] **Step 5:** Remove unconditional Uvicorn proxy-header trust; proxy semantics are handled explicitly by the application.

### Task 3: Backup, restore, rollback, and operations

**Files:**
- Create: `scripts/backup.sh`
- Create: `scripts/restore.sh`
- Create: `scripts/smoke-test.sh`
- Create: `docs/operations/production.md`
- Create: `docs/operations/backup-restore.md`
- Create: `docs/operations/observability.md`
- Create: `docs/operations/release-sla.md`

**Interfaces:**
- Consumes: SQLite `DB_PATH` and deployment configuration.
- Produces: atomic SQLite online backup, integrity-checked restore, deployment smoke checks, explicit RTO/RPO/resource/ownership/secrets/monitoring guidance.

- [ ] **Step 1:** Implement SQLite `.backup`-based backup with restrictive permissions and integrity verification.
- [ ] **Step 2:** Implement restore with pre-restore safety copy and `PRAGMA integrity_check` before replacement.
- [ ] **Step 3:** Implement HTTPS health/security-header smoke test.
- [ ] **Step 4:** Document RPO/RTO, scaling boundary, SQLite single-writer constraint, secret rotation, centralized logs/metrics/alerts, resource sizing, deployment approvals, and rollback procedure.

### Task 4: Supply-chain security gates

**Files:**
- Create: `.github/workflows/container-security.yml`
- Create: `.github/workflows/release-attestation.yml`
- Modify: `.github/workflows/security.yml`
- Modify: `docs/release.md`

**Interfaces:**
- Consumes: repository Dockerfile and release tags.
- Produces: Trivy image vulnerability gate, retained SBOM artifact, and GitHub build provenance attestation for release images.

- [ ] **Step 1:** Build the container in CI and fail on HIGH/CRITICAL fixable vulnerabilities.
- [ ] **Step 2:** Generate and retain CycloneDX SBOM with explicit retention.
- [ ] **Step 3:** On version tags, build an immutable image artifact and generate GitHub provenance attestation using least-privilege `id-token`/`attestations` permissions.
- [ ] **Step 4:** Document SBOM distribution/retention and release rollback evidence requirements.

### Task 5: Checklist evidence and CI verification

**Files:**
- Modify: `IMPLEMENTATION-CHECKLIST.md`
- Modify: `CHANGELOG.md`
- Modify: `.github/workflows/ci.yml`

**Interfaces:**
- Consumes: all controls added in Tasks 1-4.
- Produces: evidence-linked checklist status and CI validation for newly required files/shell syntax.

- [ ] **Step 1:** Extend repository baseline validation to require production/security/ADR/runbook files and shell-check their syntax.
- [ ] **Step 2:** Mark repository-controlled checklist items complete only when implemented; label deployment/account/human assessment items as `external evidence required` rather than falsely completing them.
- [ ] **Step 3:** Record the hardening changes in `CHANGELOG.md`.
- [ ] **Step 4:** Run all GitHub Actions on the PR and merge only when every required workflow is green.
