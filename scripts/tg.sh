#!/usr/bin/env bash
# Terragrunt helpers for this repo. Run from repo root: ./scripts/tg.sh <command>
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Default stack dir; override with ENV_DEV, or legacy LIVE_DEV.
ENV_DEV="${ENV_DEV:-${LIVE_DEV:-$ROOT/environments/dev}}"

usage() {
  sed -n '1,80p' <<'EOF'
Usage: ./scripts/tg.sh <command> [args...]

Commands:
  clean-cache     Remove all .terragrunt-cache directories under environments/
  init-all        terragrunt run-all init (from environments/dev)
  validate-all    terragrunt run-all validate
  plan-all        terragrunt run-all plan
  apply-all       terragrunt run-all apply
  graph           Print terragrunt graph-dependencies (DOT)
  graph-mermaid   Print a Mermaid flowchart derived from the graph
  env-check       Verify required TF_VAR_* / DO_TOKEN are set (non-empty)
  env-load-help   Show how to load .env into your shell

Environment:
  ENV_DEV         Override path to the stack dir (default: <repo>/environments/dev)
  LIVE_DEV        Deprecated alias for ENV_DEV (backward compatibility)

Typical workflow:
  cp .env.example .env   # fill in secrets
  set -a && source .env && set +a
  ./scripts/tg.sh clean-cache
  ./scripts/tg.sh init-all
  ./scripts/tg.sh plan-all
EOF
}

clean_cache() {
  local found=0
  while IFS= read -r -d '' dir; do
    rm -rf "$dir"
    found=1
  done < <(find "$ROOT/environments" -name .terragrunt-cache -type d -print0 2>/dev/null || true)
  if [[ "$found" -eq 1 ]]; then
    echo "Removed .terragrunt-cache under environments/"
  else
    echo "No .terragrunt-cache directories found under environments/"
  fi
}

run_in_env_dev() {
  local cmd="$1"
  shift
  (cd "$ENV_DEV" && terragrunt "run-all" "$cmd" --non-interactive "$@")
}

env_check() {
  local ok=1
  local token="${TF_VAR_do_token:-${DO_TOKEN:-}}"
  if [[ -z "${token// }" ]]; then
    echo "Missing: set TF_VAR_do_token or DO_TOKEN" >&2
    ok=0
  fi
  if [[ -z "${TF_VAR_argocd_admin_password_hash:-}" ]]; then
    echo "Missing: TF_VAR_argocd_admin_password_hash (required for argocd stack)" >&2
    ok=0
  fi
  if [[ "$ok" -eq 1 ]]; then
    echo "Environment looks OK for plan/apply (tokens present)."
  else
    echo "Tip: cp .env.example .env && set -a && source .env && set +a" >&2
    return 1
  fi
}

graph_mermaid() {
  cat <<'EOF'
%% Match ./scripts/tg.sh graph (terragrunt graph-dependencies)
flowchart TD
  doks["doks"]
  traefik["traefik"]
  dns["dns"]
  argo["argocd"]
  traefik --> doks
  dns --> traefik
  argo --> doks
  argo --> traefik
  argo --> dns
EOF
}

case "${1:-}" in
  clean-cache)
    clean_cache
    ;;
  init-all)
    shift || true
    run_in_env_dev init "$@"
    ;;
  validate-all)
    shift || true
    run_in_env_dev validate "$@"
    ;;
  plan-all)
    shift || true
    run_in_env_dev plan -input=false "$@"
    ;;
  apply-all)
    shift || true
    env_check
    run_in_env_dev apply -input=false -auto-approve "$@"
    ;;
  graph)
    (cd "$ENV_DEV" && terragrunt graph-dependencies)
    ;;
  graph-mermaid)
    graph_mermaid
    ;;
  env-check)
    env_check
    ;;
  env-load-help)
    cat <<'EOF'
Load secrets from a repo-root .env file (do not commit .env):

  set -a
  source .env
  set +a

Or one line:

  set -a && source .env && set +a
EOF
    ;;
  -h | --help | help | "")
    usage
    ;;
  *)
    echo "Unknown command: $1" >&2
    usage >&2
    exit 1
    ;;
esac
