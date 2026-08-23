#!/usr/bin/env sh
set -eu
ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$ROOT_DIR"
VENV_DIR="${VENV_DIR:-.venv}"
PY="$VENV_DIR/bin/python"
if [ ! -x "$PY" ]; then echo "Virtual environment not found. Running installer..."; sh scripts/install.sh; fi
export APP_ENV="${APP_ENV:-development}"
export DB_PATH="${DB_PATH:-/tmp/secure_webapp.db}"
export SESSION_TTL_SECONDS="${SESSION_TTL_SECONDS:-3600}"
export MAX_BODY_BYTES="${MAX_BODY_BYTES:-1048576}"
exec "$PY" -m uvicorn app.main:app --host "${HOST:-127.0.0.1}" --port "${PORT:-8000}"
