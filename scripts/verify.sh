#!/usr/bin/env sh
set -eu
ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"; cd "$ROOT_DIR"
VENV_DIR="${VENV_DIR:-.venv}"; PY="$VENV_DIR/bin/python"
if [ ! -x "$PY" ]; then echo "Virtual environment not found. Run scripts/install.sh first."; exit 1; fi
echo "== Runtime =="; "$PY" --version
echo "== Lint =="; "$PY" -m ruff check .
echo "== Tests =="; "$PY" -m pytest -q
echo "== SAST =="; "$PY" -m bandit -q -r app -x tests
echo "== Dependency audit =="; "$PY" -m pip_audit -r requirements.txt --strict
echo "== Import check =="; APP_ENV=test DB_PATH=/tmp/secure_webapp_verify.db "$PY" -c "import app.main; print('Application import OK')"
echo "All verification checks passed."
