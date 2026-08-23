#!/usr/bin/env bash
set -Eeuo pipefail
if [[ "${1:-}" != "--systemd" ]]; then
  echo "Usage: sudo ./uninstall.sh --systemd"
  echo "This removes the installed service and application files, but preserves /var/lib/secure-webapp."
  exit 1
fi
[[ "$EUID" -eq 0 ]] || { echo "Run with sudo/root."; exit 1; }
systemctl disable --now secure-webapp.service 2>/dev/null || true
rm -f /etc/systemd/system/secure-webapp.service
rm -f /etc/secure-webapp.env
rm -rf /opt/secure-webapp
systemctl daemon-reload
echo "Removed service and /opt/secure-webapp."
echo "Preserved application data at /var/lib/secure-webapp."
