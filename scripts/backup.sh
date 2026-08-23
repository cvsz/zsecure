#!/usr/bin/env bash
set -euo pipefail

umask 077
DB_PATH="${DB_PATH:-/data/app.db}"
BACKUP_DIR="${BACKUP_DIR:-./backups}"

mkdir -p "$BACKUP_DIR"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUT="$BACKUP_DIR/app-$STAMP.db"

python3 - "$DB_PATH" "$OUT" <<'PY'
import sqlite3
import sys
from pathlib import Path

source = Path(sys.argv[1])
target = Path(sys.argv[2])
if not source.is_file():
    raise SystemExit(f"database not found: {source}")

with sqlite3.connect(source) as src, sqlite3.connect(target) as dst:
    src.backup(dst)
    result = dst.execute("PRAGMA integrity_check").fetchone()
    if not result or result[0] != "ok":
        raise SystemExit(f"backup integrity check failed: {result}")
PY

chmod 600 "$OUT"
printf '%s\n' "$OUT"
