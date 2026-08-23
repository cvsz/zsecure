# ADR 0001: Security Boundaries and Production Topology

- Status: Accepted
- Date: 2026-08-23

## Context

Secure Web App Master is intended to be a reusable security-first starter. A starter must make insecure deployment states difficult without pretending that repository code can configure every production control. The application currently uses FastAPI, server-side SQLite state, secure cookies in production, CSRF validation, object ownership checks, and hardened container settings.

## Decision

1. Public production traffic terminates at a trusted TLS reverse proxy. The application backend is not exposed directly to the public network.
2. Forwarded client identity is accepted only from explicitly configured trusted proxy CIDRs. Client-supplied forwarding headers from other peers are ignored.
3. Single-instance development may use the in-process limiter. Multi-instance/production deployments that opt into `REQUIRE_SHARED_RATE_LIMIT=true` must provide Redis and fail closed when it is unavailable.
4. SQLite remains the default starter database because it keeps the reference implementation small. Production deployments must use persistent protected storage, backups, and integrity-tested restore. Workloads requiring multiple writers, high write concurrency, cross-region replication, or managed failover should migrate to a transactional server database through an explicitly reviewed adapter/migration plan.
5. GitHub Actions remain least privilege. Security scanning, dependency review, container scanning, SBOM generation, and provenance are part of the release evidence.
6. External repository settings and independent penetration testing are tracked as external evidence, not represented as completed merely by adding source files.

## Security consequences

This reduces spoofed client identity, accidental public backend exposure, multi-instance rate-limit bypass, and ambiguous deployment responsibility. It preserves a small starter architecture while making the scaling boundary explicit.

Residual risks include reverse-proxy misconfiguration, Redis or database compromise, account-level GitHub configuration drift, and application-specific authorization requirements not represented by the starter domain.

## Alternatives considered

- Trust all proxy headers: rejected because direct or misrouted access could spoof client identity.
- Require Redis for all development: rejected because it unnecessarily increases local setup cost.
- Replace SQLite with PostgreSQL immediately: rejected for the starter because it materially increases scope; deployments that need multi-writer semantics must make that choice explicitly.
- Mark account-level controls complete from documentation alone: rejected because that would create false security evidence.

## Rollback

The proxy/rate-limit additions are configuration-driven. A single-instance deployment can omit Redis and shared-rate-limit enforcement. Any rollback must retain secure cookie, CSRF, authorization, persistent-storage, and CI security guarantees.

## Validation

Validation is provided by security regression tests, CI, container scanning, deployment smoke tests, backup/restore procedures, and the release checklist.