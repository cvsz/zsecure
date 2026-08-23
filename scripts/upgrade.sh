#!/usr/bin/env sh
set -eu
ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"; cd "$ROOT_DIR"
VENV_DIR="${VENV_DIR:-.venv}"; PY="$VENV_DIR/bin/python"
[ -x "$PY" ] || { echo "Virtual environment not found. Run scripts/install.sh first."; exit 1; }
echo "[1/5] Updating installer tooling..."; "$PY" -m pip install --upgrade pip setuptools wheel
echo "[2/5] Reinstalling declared dependencies..."; "$PY" -m pip install --upgrade -r requirements-dev.txt
echo "[3/5] Auditing dependencies..."; "$PY" -m pip_audit -r requirements.txt --strict
echo "[4/5] Running tests and static analysis..."; "$PY" -m ruff check .; "$PY" -m pytest -q; "$PY" -m bandit -q -r app -x tests
echo "[5/5] Regenerating SBOM..."; "$PY" -m cyclonedx_py requirements requirements.txt --output-file sbom.json 2>/dev/null || cyclonedx-py requirements requirements.txt --output-file sbom.json
echo "Upgrade verification completed successfully."
