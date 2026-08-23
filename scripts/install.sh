#!/usr/bin/env sh
set -eu
ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"; cd "$ROOT_DIR"
PYTHON_BIN="${PYTHON_BIN:-python3}"; VENV_DIR="${VENV_DIR:-.venv}"
echo "[1/6] Checking Python..."
command -v "$PYTHON_BIN" >/dev/null 2>&1 || { echo "Error: $PYTHON_BIN not found. Install Python 3.14+ and retry."; exit 1; }
"$PYTHON_BIN" - <<'PY'
import sys
if sys.version_info < (3, 14): raise SystemExit(f"Python 3.14+ required; found {sys.version.split()[0]}")
print("Python:", sys.version.split()[0])
PY
echo "[2/6] Creating virtual environment..."; "$PYTHON_BIN" -m venv "$VENV_DIR"
[ -x "$VENV_DIR/bin/python" ] || { echo "Error: virtual environment creation failed."; exit 1; }
PY="$VENV_DIR/bin/python"
echo "[3/6] Upgrading installer tooling..."; "$PY" -m pip install --upgrade pip setuptools wheel
echo "[4/6] Installing application and security tooling..."; "$PY" -m pip install -r requirements-dev.txt
echo "[5/6] Running automated security verification..."; "$PY" -m ruff check .; "$PY" -m pytest -q; "$PY" -m bandit -q -r app -x tests; "$PY" -m pip_audit -r requirements.txt --strict
echo "[6/6] Generating SBOM..."; "$PY" -m cyclonedx_py requirements requirements.txt --output-file sbom.json 2>/dev/null || cyclonedx-py requirements requirements.txt --output-file sbom.json
echo "Installation complete. Run: sh scripts/run.sh"
