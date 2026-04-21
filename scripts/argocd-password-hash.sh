#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./scripts/argocd-password-hash.sh <plain-text-password>

Prints an Argo CD-compatible bcrypt hash (for ARGOCD_ADMIN_PASSWORD_HASH).
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -ne 1 ]]; then
  usage >&2
  exit 1
fi

if ! command -v htpasswd >/dev/null 2>&1; then
  echo "Error: htpasswd not found. Install apache2-utils (or httpd-tools)." >&2
  exit 1
fi

PASSWORD="$1"
htpasswd -bnBC 10 "" "${PASSWORD}" | tr -d ':\n' | sed 's/$2y/$2a/'
