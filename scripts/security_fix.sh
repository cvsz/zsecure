#!/usr/bin/env sh
set -eu
python -m ruff check . --fix
python -m ruff format .
python -m pip_audit -r requirements.txt --strict || {
  echo "Known vulnerable dependency detected."
  echo "Review the advisory and merge the tested Dependabot security update PR."
  exit 1
}
echo "Automated formatting/lint fixes applied. Run scripts/security_check.sh."
