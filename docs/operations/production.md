# Production Operations Runbook

## Supported topology

Production traffic terminates at Caddy (or an equivalent trusted TLS load balancer), then crosses a private network to FastAPI. The backend must not be publicly reachable. `compose.yaml` supplies an explicit private subnet, Caddy, Redis, and the application. Set `APP_DOMAIN` to the public DNS name and set a strong random `REDIS_PASSWORD` outside the repository.

The application trusts `X-Forwarded-For` only when the direct peer belongs to `TRUSTED_PROXY_NETWORKS`. Any replacement proxy/load balancer must strip client-supplied forwarding headers and set authoritative forwarding values.

## Start

```bash
export APP_DOMAIN=app.example.com
export REDIS_PASSWORD="$(python3 -c 'import secrets; print(secrets.token_urlsafe(48))')"
docker compose up -d --build
./scripts/smoke-test.sh "https://$APP_DOMAIN"
```

Store secrets in the deployment platform's secret manager rather than shell history or committed `.env` files. Rotate Redis/deployment/TLS credentials according to organizational policy and immediately after suspected exposure.

## Database strategy

SQLite is the supported default for a single application writer with persistent storage. It is not the recommended choice for multi-writer active/active deployments, high sustained write concurrency, cross-region replication, or managed automatic failover. Before those requirements arise, create a reviewed ADR and migration plan for a transactional server database (normally PostgreSQL), including schema migrations, rollback, tenant/authorization preservation, backup/restore, connection limits, and fail-closed startup behavior.

Do not place the production SQLite database on tmpfs, ephemeral container layers, or network filesystems with unsafe SQLite locking semantics.

## Resource and availability baseline

The reference Compose limits the app to 256 MiB and Redis/Caddy to 128 MiB each. These are starter limits, not universal production sizing. Load-test the real workload and record CPU, memory, latency, error-rate, Redis memory, database size/write latency, and connection saturation before setting SLOs.

Initial availability target for a single-host starter deployment should not exceed what a single failure domain can deliver. Higher availability requires redundant edge/application/storage infrastructure and a database design suitable for that topology.

## Scaling

Scale application replicas only with `REQUIRE_SHARED_RATE_LIMIT=true` and a reachable Redis backend. All replicas must share the same durable application database semantics; SQLite on a local volume is therefore a single-writer/single-host boundary, not an active/active database solution.

## Deployment approvals and credentials

Use a GitHub Environment or deployment platform equivalent for production. Require an explicit approval for production deployment. Deployment identities receive only the permissions needed to update the target workload and read the specific runtime secrets; they must not receive repository administration or broad cloud-owner permissions.

## Rollout

1. Confirm release commit and all required GitHub Actions are green.
2. Review dependency/code/container alerts and SBOM/provenance evidence.
3. Create and verify a database backup.
4. Deploy to a non-production environment and run `scripts/smoke-test.sh`.
5. Apply production approval.
6. Deploy the immutable release artifact.
7. Run the production smoke test and inspect logs/metrics/security alerts.
8. If health or data validation fails, execute the rollback procedure in `docs/operations/backup-restore.md` and `docs/release.md`.

## Operational ownership

Every deployment must name an on-call/operational owner, security escalation contact, backup owner, and release approver. Those identities are deployment-specific and must be recorded in the deployment system rather than hard-coded into this reusable starter.