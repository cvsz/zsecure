#!/usr/bin/env sh
set -eu
python -m ruff check .
python -m pytest -q
python -m bandit -q -r app -x tests
python -m pip_audit -r requirements.txt --strict
cyclonedx-py requirements requirements.txt --output-file sbom.json
echo "Security checks passed; SBOM written to sbom.json"
