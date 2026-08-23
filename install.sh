#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'
umask 077

PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
MODE="dev"
RUN_APP=0
USE_DOCKER=0
INSTALL_SYSTEMD=0
AUTO_FIX=0
SKIP_AUDIT=0
VENV="${PROJECT_ROOT}/.venv"

log()  { printf '\033[1;34m[secure-installer]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warning]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<'EOF'
Secure Web App master installer

Usage:
  ./install.sh [options]

Options:
  --dev              Local Python virtualenv install (default)
  --docker           Build and run hardened Docker Compose deployment
  --production       Production-oriented validation and .env generation
  --systemd          Install a systemd unit (Linux, requires sudo/root)
  --fix              Apply safe lint/format fixes before verification
  --run              Start the application after installation
  --skip-audit       Skip dependency audit (not recommended)
  --help             Show help

Examples:
  ./install.sh --dev --run
  ./install.sh --dev --fix
  ./install.sh --docker
  sudo ./install.sh --production --systemd
EOF
}

for arg in "$@"; do
  case "$arg" in
    --dev) MODE="dev" ;;
    --docker) MODE="docker"; USE_DOCKER=1 ;;
    --production) MODE="production" ;;
    --systemd) INSTALL_SYSTEMD=1; MODE="production" ;;
    --fix) AUTO_FIX=1 ;;
    --run) RUN_APP=1 ;;
    --skip-audit) SKIP_AUDIT=1 ;;
    --help|-h) usage; exit 0 ;;
    *) die "Unknown option: $arg" ;;
  esac
done

command_exists() { command -v "$1" >/dev/null 2>&1; }

detect_os() {
  if [[ "$(uname -s)" != "Linux" && "$INSTALL_SYSTEMD" -eq 1 ]]; then
    die "--systemd is supported only on Linux."
  fi
  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    log "Detected OS: ${PRETTY_NAME:-Linux}"
  else
    log "Detected OS: $(uname -s)"
  fi
}

require_python() {
  command_exists python3 || die "Python 3 is required."
  python3 - <<'PY'
import sys
if sys.version_info < (3, 11):
    raise SystemExit("Python 3.11+ is required")
print("Python:", sys.version.split()[0])
PY
}

ensure_env() {
  local env_file="${PROJECT_ROOT}/.env"
  if [[ ! -f "$env_file" ]]; then
    cp "${PROJECT_ROOT}/.env.example" "$env_file"
    chmod 600 "$env_file"
    if [[ "$MODE" == "production" ]]; then
      sed -i.bak 's/^APP_ENV=.*/APP_ENV=production/' "$env_file" 2>/dev/null || true
      rm -f "${env_file}.bak"
      if grep -q '^DB_PATH=/tmp/' "$env_file"; then
        sed -i.bak 's#^DB_PATH=.*#DB_PATH=/var/lib/secure-webapp/app.db#' "$env_file" 2>/dev/null || true
        rm -f "${env_file}.bak"
      fi
    fi
    log "Created protected .env from .env.example"
  else
    chmod 600 "$env_file" || true
    log "Using existing .env"
  fi
}

install_dev() {
  require_python
  if [[ ! -d "$VENV" ]]; then
    log "Creating virtual environment"
    python3 -m venv "$VENV"
  fi
  # shellcheck disable=SC1091
  source "${VENV}/bin/activate"
  python -m pip install --upgrade pip
  python -m pip install -r "${PROJECT_ROOT}/requirements-dev.txt"
}

run_checks() {
  # shellcheck disable=SC1091
  [[ -f "${VENV}/bin/activate" ]] && source "${VENV}/bin/activate"
  cd "$PROJECT_ROOT"

  if [[ "$AUTO_FIX" -eq 1 ]]; then
    log "Applying safe source-format/lint fixes"
    python -m ruff check . --fix
    python -m ruff format .
  fi

  log "Running lint"
  python -m ruff check .

  log "Running tests"
  python -m pytest -q

  log "Running SAST"
  python -m bandit -q -r app -x tests

  if [[ "$SKIP_AUDIT" -eq 0 ]]; then
    log "Auditing dependencies"
    python -m pip_audit -r requirements.txt --strict
  else
    warn "Dependency audit skipped by request."
  fi

  log "Generating SBOM"
  cyclonedx-py requirements requirements.txt --output-file sbom.json
  chmod 600 sbom.json || true
}

docker_install() {
  command_exists docker || die "Docker is required for --docker."
  docker compose version >/dev/null 2>&1 || die "Docker Compose v2 is required."

  log "Building hardened container"
  docker compose -f "${PROJECT_ROOT}/compose.yaml" build --pull

  log "Starting deployment"
  docker compose -f "${PROJECT_ROOT}/compose.yaml" up -d

  log "Container status"
  docker compose -f "${PROJECT_ROOT}/compose.yaml" ps
}

install_systemd() {
  [[ "$EUID" -eq 0 ]] || die "--systemd requires sudo/root."

  local app_user="secureweb"
  local install_dir="/opt/secure-webapp"
  local state_dir="/var/lib/secure-webapp"

  if ! id "$app_user" >/dev/null 2>&1; then
    useradd --system --home "$install_dir" --shell /usr/sbin/nologin "$app_user"
  fi

  mkdir -p "$install_dir" "$state_dir"
  rsync -a --delete \
    --exclude '.git' --exclude '.venv' --exclude '.env' \
    "${PROJECT_ROOT}/" "${install_dir}/"

  chown -R root:root "$install_dir"
  chown -R "$app_user":"$app_user" "$state_dir"
  chmod 750 "$install_dir" "$state_dir"

  python3 -m venv "${install_dir}/.venv"
  "${install_dir}/.venv/bin/python" -m pip install --upgrade pip
  "${install_dir}/.venv/bin/python" -m pip install -r "${install_dir}/requirements.txt"

  install -m 600 "${PROJECT_ROOT}/.env" /etc/secure-webapp.env
  sed -i 's#^APP_ENV=.*#APP_ENV=production#' /etc/secure-webapp.env
  sed -i 's#^DB_PATH=.*#DB_PATH=/var/lib/secure-webapp/app.db#' /etc/secure-webapp.env

  cat >/etc/systemd/system/secure-webapp.service <<EOF
[Unit]
Description=Secure Web Application
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=${app_user}
Group=${app_user}
WorkingDirectory=${install_dir}
EnvironmentFile=/etc/secure-webapp.env
ExecStart=${install_dir}/.venv/bin/uvicorn app.main:app --host 127.0.0.1 --port 8000 --no-server-header
Restart=on-failure
RestartSec=5
NoNewPrivileges=true
PrivateTmp=true
PrivateDevices=true
ProtectSystem=strict
ProtectHome=true
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectKernelLogs=true
ProtectControlGroups=true
RestrictSUIDSGID=true
LockPersonality=true
MemoryDenyWriteExecute=true
RestrictRealtime=true
SystemCallArchitectures=native
ReadWritePaths=${state_dir}
UMask=0077

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable --now secure-webapp.service
  systemctl --no-pager --full status secure-webapp.service || true

  warn "The service listens only on 127.0.0.1:8000."
  warn "Terminate TLS at a trusted reverse proxy before public exposure."
}

main() {
  detect_os
  ensure_env

  if [[ "$USE_DOCKER" -eq 1 ]]; then
    docker_install
    log "Docker installation complete."
    exit 0
  fi

  install_dev
  run_checks

  if [[ "$INSTALL_SYSTEMD" -eq 1 ]]; then
    command_exists rsync || die "rsync is required for --systemd."
    install_systemd
    log "Hardened systemd installation complete."
    exit 0
  fi

  if [[ "$RUN_APP" -eq 1 ]]; then
    # shellcheck disable=SC1091
    source "${VENV}/bin/activate"
    set -a
    # shellcheck disable=SC1091
    source "${PROJECT_ROOT}/.env"
    set +a
    log "Starting application on http://127.0.0.1:8000"
    exec uvicorn app.main:app --host 127.0.0.1 --port 8000 --no-server-header
  fi

  log "Installation and verification complete."
  log "Run: ./install.sh --dev --run"
}

main
