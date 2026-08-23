#!/usr/bin/env bash
set -euo pipefail

umask 077
if [[ $# -lt 1 ]]; then
  echo "usage: $0 BACKUP_DB [TARGET_DB]" >&2
  exit 2
fi

BACKUP_DB="$1"
TARGET_DB="${2:-${DB_PATH:-/data/app.db}}"

python3 - "$BACKUP_DB" "$TARGET_DB" <<'PY'
import os
import shutil
import sqlite3
import sys
import time
from pathlib import Path

source = Path(sys.argv[1]).resolve()
target = Path(sys.argv[2]).resolve()
if not source.is_file():
    raise SystemExit(f"backup not found: {source}")

with sqlite3.connect(source) as conn:
    result = conn.execute("PRAGMA integrity_check").fetchone()
    if not result or result[0] != "ok":
        raise SystemExit(f"source integrity check failed: {result}")

if target.exists():
    safety = target.with_name(f"{target.name}.pre-restore-{int(time.time())}")
    shutil.copy2(target, safety)
    os.chmod(safety, 0o600)
    print(f"pre-restore copy: {safety}")

target.parent.mkdir(parents=True, exist_ok=True)
tmp = target.with_name(f".{target.name}.restore-{os.getpid()}")
try:
    with sqlite3.connect(source) as src, sqlite3.connect(tmp) as dst:
        src.backup(dst)
        result = dst.execute("PRAGMA integrity_check").fetchone()
        if not result or result[0] != "ok":
            raise SystemExit(f"restored database integrity check failed: {result}")
    os.chmod(tmp, 0o600)
    os.replace(tmp, target)
finally:
    if tmp.exists():
        tmp.unlink()

print(f"restored: {target}")
PY
