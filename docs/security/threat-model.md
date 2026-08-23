# Threat Model

## Scope

This model covers the Secure Web App Master application, its browser client, FastAPI service, SQLite data store, optional Redis rate-limit store, TLS reverse proxy, CI/CD workflows, dependency supply chain, and deployment credentials. It must be re-reviewed whenever authentication, authorization, session handling, storage, proxy trust, deployment topology, or externally reachable functionality materially changes.

## Security objectives

1. Only authenticated users can access protected data.
2. Users can access only objects they own unless an explicitly reviewed role grants more access.
3. State-changing authenticated requests require a valid CSRF token.
4. Session tokens, password hashes, deployment credentials, and private data are not exposed to untrusted clients or logs.
5. Untrusted input cannot become SQL, shell, path, template, or header instructions.
6. The production service fails closed when required durable storage, proxy trust, or shared rate limiting is misconfigured.
7. Builds and releases are reproducible enough to audit their source, dependencies, SBOM, image scan, and provenance.

## Assets

- User credentials and Argon2 password hashes.
- Opaque server-side session tokens and CSRF tokens.
- User-owned notes and account metadata.
- SQLite database and backups.
- Redis rate-limit state when multi-instance mode is enabled.
- TLS private keys managed by the reverse proxy/runtime.
- CI credentials, GitHub tokens, provenance identity, and deployment credentials.
- Source code, dependency manifests, container images, SBOMs, and release artifacts.

## Trust boundaries

### Browser to TLS edge

All browser-controlled values are untrusted: URL components, body fields, cookies, headers, identifiers, and content. HTTPS terminates at the configured reverse proxy. Direct public access to the application backend is not an intended production topology.

### TLS edge to application

Only explicitly configured proxy networks may influence forwarded client identity. The application must ignore `X-Forwarded-For` from untrusted peers. Proxy networks must strip incoming forwarding headers and set authoritative values before forwarding.

### Application to SQLite

Database access uses parameterized queries. Object ownership is enforced in protected queries. The production database must live on persistent protected storage, not a temporary directory.

### Application to Redis

Redis is optional for single-instance development but required when production is configured for shared/multi-instance rate limiting. Redis is private to the deployment network and is not exposed publicly.

### CI/CD to repository and registry

Workflow permissions are least privilege. Dependency review, SAST, vulnerability audit, container scanning, and provenance generation are release gates. Third-party actions must be reviewed and should be pinned to immutable commit SHAs when the repository adopts an immutable-action policy.

## Threats and controls

| Threat | Primary controls | Residual risk / required follow-up |
| --- | --- | --- |
| Credential stuffing / brute force | Argon2, rate limiting, generic login failure | Add MFA/account lockout policy when business requirements exist |
| Session theft | HttpOnly/Secure production cookie, hashed server-side tokens, short TTL, no-store | TLS/key compromise remains infrastructure risk |
| CSRF | SameSite=Strict + explicit CSRF token on state changes | Review if cross-site integrations are introduced |
| IDOR/BOLA | Owner ID included in object queries; 404 on unauthorized object | Every new resource requires equivalent authorization tests |
| SQL injection | Parameterized SQLite queries | Future storage adapters must preserve parameterization |
| XSS/content injection | CSP, no inline scripts, frontend text rendering expectations | Rich-text/HTML features require dedicated sanitization design |
| Proxy spoofing | CIDR allowlist for trusted proxies; untrusted forwarded headers ignored | Misconfigured proxy networks can still weaken attribution/rate limits |
| DoS | Body limit, rate limits, process/container resource limits | Volumetric DoS requires upstream network protection |
| Dependency compromise | Dependabot, Dependency Review, pip-audit, CodeQL/Bandit, SBOM, container scanning | Zero-day and malicious-but-not-vulnerable packages remain possible |
| Malicious CI change | CODEOWNERS, PR review policy, least-privilege workflow permissions | GitHub account/repository compromise remains an external risk |
| Secret leakage | Secret-file checks, GitHub secret scanning/push protection where enabled, no secrets in repo | Runtime secret stores and operator handling require deployment controls |
| Data loss | Persistent volume, online backup, integrity-checked restore, rollback runbook | RPO/RTO depend on deployment schedule and off-host backup copy |
| Release tampering | Versioned source, SBOM, image scan, provenance attestation | Production registry policy must verify/retain attestations |

## Abuse cases to test

- Login with invalid credentials and SQL-like input.
- State-changing request with missing or mismatched CSRF token.
- Access another user's object by guessed identifier.
- Submit unexpected JSON fields, oversized bodies, invalid identifiers, and malformed email values.
- Send spoofed `X-Forwarded-For` from an untrusted source.
- Exhaust login/register rate limits from one client.
- Start production with a temporary database path.
- Start shared-rate-limit production mode without Redis.
- Restore a corrupted or invalid database backup.
- Build an image containing a HIGH/CRITICAL fixable vulnerability.

## Review triggers

Re-run threat modeling and update this document before merging changes to authentication, roles/permissions, cookies/session storage, upload handling, HTML rendering, database technology, proxy topology, multi-instance scaling, deployment credentials, registry/release flow, or any new externally reachable endpoint.

## External validation still required

This repository threat model is not an independent penetration test. Each production deployment still requires a risk-appropriate independent security review and validation of infrastructure, IAM, network boundaries, TLS, secrets, backups, monitoring, and incident response.