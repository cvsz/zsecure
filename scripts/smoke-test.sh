#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${1:-${BASE_URL:-}}"
if [[ -z "$BASE_URL" ]]; then
  echo "usage: $0 https://app.example.com" >&2
  exit 2
fi
if [[ "$BASE_URL" != https://* && "${ALLOW_HTTP_SMOKE:-false}" != "true" ]]; then
  echo "refusing non-HTTPS smoke test; set ALLOW_HTTP_SMOKE=true only for local testing" >&2
  exit 2
fi

headers="$(mktemp)"
body="$(mktemp)"
trap 'rm -f "$headers" "$body"' EXIT

curl --fail --silent --show-error \
  --connect-timeout 5 --max-time 15 \
  --dump-header "$headers" \
  --output "$body" \
  "$BASE_URL/healthz"

grep -Eq '"status"[[:space:]]*:[[:space:]]*"ok"' "$body"
grep -Eiq '^x-content-type-options:[[:space:]]*nosniff' "$headers"
grep -Eiq '^x-frame-options:[[:space:]]*DENY' "$headers"
grep -Eiq '^content-security-policy:' "$headers"
grep -Eiq '^cache-control:[[:space:]]*no-store' "$headers"

if [[ "$BASE_URL" == https://* ]]; then
  grep -Eiq '^strict-transport-security:' "$headers"
fi

echo "smoke test passed: $BASE_URL"
