# Backup, Restore, and Disaster Recovery

## Objectives

The starter baseline is **RPO <= 24 hours** and **RTO <= 4 hours** for a single-host deployment, provided backups are copied off-host and operators rehearse restore. Deployments with stricter requirements must shorten backup intervals and adopt storage/database infrastructure that can meet those targets.

## Backup

Run from a host/container with Python access to the live SQLite file:

```bash
DB_PATH=/data/app.db BACKUP_DIR=/secure-backups ./scripts/backup.sh
```

The script uses SQLite's online backup API rather than a raw live-file copy, runs `PRAGMA integrity_check` on the produced database, writes with restrictive permissions, and prints the final backup path.

Copy successful backups to encrypted storage in a separate failure domain. Apply retention appropriate to legal/business requirements; a baseline is 7 daily, 4 weekly, and 12 monthly copies. Backup storage credentials must be separate from application credentials where practical.

## Restore rehearsal

At least quarterly and before a material storage migration:

1. Select a representative backup.
2. Restore into an isolated non-production environment.
3. Run `PRAGMA integrity_check` (the restore script does this automatically).
4. Start the application and execute `scripts/smoke-test.sh`.
5. Validate representative authentication and owned-object access without exposing production secrets.
6. Record duration, backup timestamp, resulting RPO/RTO, and operator.

## Production restore

Stop all application writers before replacing SQLite state.

```bash
docker compose stop app
./scripts/restore.sh /secure-backups/app-YYYYMMDDTHHMMSSZ.db /path/to/app.db
docker compose start app
./scripts/smoke-test.sh https://app.example.com
```

The restore script validates the source, creates a restrictive pre-restore copy of an existing target, writes a validated temporary database, then atomically replaces the target.

## Release rollback with persistent data

Code rollback and data rollback are separate decisions. Prefer rolling application code back while retaining forward-compatible data. If a future release introduces a schema change, its ADR/release plan must define both forward and reverse migration semantics before deployment. Do not restore an older database merely to roll back application code unless the release documentation explicitly proves compatibility and the accepted data-loss window.

## Disaster scenarios

- **Application/container loss:** recreate from the immutable release and reattach persistent data.
- **Host loss:** provision a replacement host, restore the latest off-host backup, restore runtime secrets from the secret manager, then smoke-test.
- **Database corruption:** stop writers, preserve forensic copy, restore latest verified backup, validate integrity and application behavior.
- **Credential compromise:** rotate affected credentials first, then redeploy; assume copied backups/configs containing the credential are exposed according to incident policy.
- **Redis loss:** rate-limit state may reset; production configured with shared rate limiting fails closed until Redis is healthy.

Every real deployment must record backup location, owner, encryption/key ownership, schedule, retention, restore rehearsal evidence, RPO, and RTO.