# Observability and Security Alerting

## Logging

Application logs go to stdout/stderr and include explicit `security_event=` records for account creation, login success/failure, and logout. The TLS edge emits structured access logs. Production must ship container/service logs to centralized storage with access control, retention, search, and tamper-resistance appropriate to the deployment.

Do not log passwords, raw session cookies, CSRF tokens, authorization headers, Redis passwords, private keys, or full secret values. Treat request bodies as sensitive by default.

## Metrics

Collect at minimum:

- HTTP request rate, latency percentiles, 4xx/5xx counts, and saturation.
- Login success/failure and rate-limit rejection counts.
- Application process CPU, memory, restarts, file descriptors, and health status.
- SQLite database size, backup age, backup success/failure, and restore-test age.
- Redis availability, memory, evictions, command latency, and connection count.
- Reverse-proxy TLS/certificate health and 4xx/5xx rates.
- Container image/release version currently deployed.

## Alerts

Page or otherwise escalate according to service criticality for:

- Sustained health-check failure or elevated 5xx rate.
- Redis unavailable while shared production limiting is required.
- Repeated failed logins/rate-limit spikes inconsistent with baseline.
- Backup failure, backup age beyond RPO, or failed integrity check.
- TLS certificate renewal/expiry risk.
- Critical code/dependency/container vulnerability affecting a supported release.
- Unexpected application restarts, memory pressure, disk exhaustion, or database corruption.

## Ownership

Every production deployment records the operations owner, security escalation contact, alert destination, log/metric platform, retention period, and incident-response link in its deployment configuration/ticket. The reusable repository intentionally does not hard-code organization-specific endpoints or credentials.

## Validation

Before production approval, generate at least one test alert for application health and one security-event query. Confirm the responsible operator can find the deployed release version, failed-login events, current backup age, and latest vulnerability scan without shell access to the application host.