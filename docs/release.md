# Release and Deployment

Secure Web App Master is currently pre-release. `main` is the active development line; no long-term supported production version has been declared yet.

## Release policy

Semantic Versioning is the intended versioning model once tagged releases begin. Release candidates should be created only from reviewed commits with required CI/security checks passing.

## Pre-release checklist

1. Run the full development verification path: `./install.sh --dev`.
2. Confirm Ruff, Pytest, Bandit, strict `pip-audit`, CodeQL, installer validation, and repository checks pass.
3. Review dependency/CodeQL/security alerts and unresolved exceptions.
4. Update `CHANGELOG.md`, `ROADMAP.md`, and affected operational/security documentation.
5. Generate and retain the CycloneDX SBOM for the release candidate.
6. Build the Docker image from a clean checkout and verify localhost-only exposure and runtime hardening.
7. Validate environment-specific secrets, TLS ingress, backup/restore, monitoring, and rollback procedures before production deployment.
8. Tag/publish only from trusted automation and record the exact commit used.

## Deployment paths

### Docker

```bash
./install.sh --docker
```

This builds and starts the Compose deployment with read-only root filesystem, tmpfs for `/tmp`, persistent application data, dropped capabilities, `no-new-privileges`, resource constraints, and `127.0.0.1:8000` host binding.

### Linux/systemd

```bash
sudo ./install.sh --production --systemd
```

This installs the application under `/opt/secure-webapp`, persistent state under `/var/lib/secure-webapp`, a protected environment file, and a sandboxed `secure-webapp.service` using a dedicated service account.

## Production ingress

Do not expose the bundled Uvicorn process directly to the public Internet. Terminate TLS through a trusted reverse proxy/load balancer, explicitly configure trusted forwarded-header behavior, and apply deployment-appropriate network/request controls.

## Rollback

Before production release, operators must define and test how to restore the last known-good application version and database state. Rollback planning must account for data compatibility, dependency/image replacement, session or credential revocation when required, and security-incident containment.

## Release security gaps

Artifact signing/attestation, container vulnerability scanning, formal supported-version SLAs, centralized monitoring, production database migrations/backups, and tested disaster recovery are not yet complete. These remain explicit roadmap items and should not be assumed by downstream deployments.
