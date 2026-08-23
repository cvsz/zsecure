# Architecture

## System context

Secure Web App Master is a compact security-first web application reference implementation. A browser frontend is served by the same FastAPI application that exposes the HTTP API. SQLite stores users, sessions, and user-owned notes.

## Components

- `frontend/`: static HTML, CSS, and JavaScript client.
- `app/main.py`: FastAPI routing, validation, authentication, session handling, CSRF, authorization, persistence, rate limiting, security headers, and logging.
- SQLite database: users, hashed server-side session records, and notes.
- `tests/`: application/security regression coverage.
- `install.sh` and `scripts/`: bootstrap, validation, safe fixes, auditing, and SBOM generation.
- Docker/systemd deployment definitions: constrained runtime environments.
- GitHub Actions: repository, installer, SAST, dependency, CodeQL, and SBOM checks.

## Data and authentication model

Passwords are hashed with Argon2. Successful login creates a random opaque session token and CSRF token. Only a SHA-256 hash of the session token is stored in SQLite. The browser receives the raw session token in an HttpOnly, SameSite=Strict cookie. In production the application uses Secure cookie behavior and a `__Host-` cookie name.

Authenticated state-changing operations require a matching CSRF header. Resource ownership is enforced in the database query itself; note reads/deletes are scoped by both note ID and authenticated user ID.

## Trust boundaries

Primary trust boundaries are:

1. Browser/client → HTTP application: all request data is untrusted and validated server-side.
2. Authentication cookie/CSRF token → session store: token values are verified against server-side state.
3. Application → SQLite: queries are parameterized; authorization predicates are included where resource ownership matters.
4. Public network → deployment ingress: the bundled production paths bind only to localhost and expect a trusted TLS reverse proxy/load balancer for public ingress.
5. Source/dependency ecosystem → build/runtime: dependency auditing, CodeQL, Bandit, Dependabot, SBOM generation, and reviewable upgrades reduce supply-chain risk.

## Deployment topology

### Development

`./install.sh --dev --run` creates a virtual environment, installs development dependencies, runs verification, and starts Uvicorn on `127.0.0.1:8000`.

### Docker

`compose.yaml` builds the application image and uses a read-only root filesystem, tmpfs for `/tmp`, persistent `/data`, dropped Linux capabilities, `no-new-privileges`, PID/memory limits, and localhost-only port binding.

### systemd

The production installer creates a dedicated `secureweb` service account, protected state directory, application virtual environment, and a sandboxed systemd service. The unit uses controls including `NoNewPrivileges`, `ProtectSystem=strict`, `ProtectHome`, private devices/tmp, kernel/control-group protections, restricted writable paths, and a restrictive umask.

## Security boundaries and constraints

The in-memory rate limiter is process-local and intended only for this compact reference implementation. Multi-instance deployments require a shared rate-limit backend. SQLite is intentionally simple; high-availability or high-write deployments should define a production database, migration, backup, restore, and isolation model.

Forwarded client headers are not trusted by default. A production proxy design must define exactly which proxy is trusted and how client IP/protocol headers are sanitized.

## Observability and recovery

The application logs security-relevant authentication events and unhandled exceptions. Full production observability, centralized log collection, alerting, backup/restore, disaster recovery, and availability objectives are not yet implemented and are tracked in `ROADMAP.md`.

Material architectural/security changes should be recorded as ADRs under `docs/adr/`.
