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
  apply-sequential  apply stacks in order: doks → wait for Kube API DNS → traefik → dns → argocd (local; not CI)
  apply-traefik     apply only traefik (clears k8s cache); streams kubectl logs -f during apply; on failure: diagnostics + helm uninstall
                    For logs in a second terminal instead: TG_TRAEFIK_LOG_STREAM=0 ./scripts/tg.sh apply-traefik  and  ./scripts/traefik-logs.sh
  destroy-all     run-all init -reconfigure, export live kubeconfig from doks, run-all destroy (destructive)
  graph           Print terragrunt graph-dependencies (DOT)
  graph-mermaid   Print a Mermaid flowchart derived from the graph
  env-check       Verify required TF_VAR_* / DO_TOKEN are set (non-empty)
  env-load-help   Show how to load .env into your shell

Environment:
  ENV_DEV         Override path to the stack dir (default: <repo>/environments/dev)
  LIVE_DEV        Deprecated alias for ENV_DEV (backward compatibility)
  TG_TRAEFIK_LOG_STREAM  Set to 0 to disable live kubectl logs during ./scripts/tg.sh apply-traefik
  TF_VAR_email            If set in your shell, it overrides env.hcl email for Traefik ACME; apply scripts unset it
  TG_DO_TOKEN_FROM_GITHUB  Set to 1 to load DO_TOKEN from GitHub Actions (gh secret get DO_TOKEN), overriding .env

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
  # Use TG_NON_INTERACTIVE / env so run-all is non-interactive without passing flags that some Terragrunt versions forward to Terraform.
  (
    unset TF_VAR_email || true
    cd "$ENV_DEV" && TG_NON_INTERACTIVE=true terragrunt run-all "$cmd" "$@"
  )
}

# Load .env without tripping `set -u` on empty optional vars (e.g. commented DO_TOKEN).
load_repo_env() {
  if [[ ! -f "$ROOT/.env" ]]; then
    return 0
  fi
  set +u
  set -a
  # shellcheck source=/dev/null
  source "$ROOT/.env"
  set +a
  set -u
}

# Match CI: .github/workflows/terragrunt-apply.yml uses secrets.DO_TOKEN as TF_VAR_do_token / DO_TOKEN.
# If TF_VAR_do_token and DO_TOKEN are unset after .env, try `gh secret get DO_TOKEN` (same secret name).
# Set TG_DO_TOKEN_FROM_GITHUB=1 to always take the GitHub secret (overrides .env) when you fixed the token in GitHub only.
try_load_do_token_from_github() {
  local t need_fetch=0
  if [[ "${TG_DO_TOKEN_FROM_GITHUB:-}" == "1" ]]; then
    need_fetch=1
  elif [[ -z "${TF_VAR_do_token// }" ]] && [[ -z "${DO_TOKEN// }" ]]; then
    need_fetch=1
  fi
  if [[ "$need_fetch" -ne 1 ]]; then
    return 0
  fi
  if ! command -v gh >/dev/null 2>&1; then
    if [[ "${TG_DO_TOKEN_FROM_GITHUB:-}" == "1" ]]; then
      echo "TG_DO_TOKEN_FROM_GITHUB=1 but gh is not in PATH." >&2
      return 1
    fi
    return 0
  fi
  if ! t="$(GH_PROMPT_DISABLED=1 gh secret get DO_TOKEN 2>/dev/null)"; then
    if [[ "${TG_DO_TOKEN_FROM_GITHUB:-}" == "1" ]]; then
      echo "Could not read DO_TOKEN via gh secret get. Use: gh auth login && gh secret list" >&2
      return 1
    fi
    return 0
  fi
  t="${t//$'\r'/}"
  if [[ -z "${t// }" ]]; then
    return 0
  fi
  export TF_VAR_do_token="$t"
  export DO_TOKEN="$t"
  echo "Using DO_TOKEN from GitHub Actions secret (gh secret get DO_TOKEN)." >&2
}

load_repo_credentials() {
  load_repo_env
  try_load_do_token_from_github
}

# After a new DOKS cluster, *.k8s.ondigitalocean.com may not resolve yet; Kubernetes provider fails with "no such host".
wait_for_kube_api_dns() {
  local kc api_host i
  kc="$(cd "$ENV_DEV/doks" && TG_NON_INTERACTIVE=true terragrunt output -raw kubeconfig)"
  api_host="$(echo "$kc" | awk '/^[[:space:]]*server:/{gsub(/https:\/\//,""); print $2}' | tr -d '\r' | head -1)"
  api_host="${api_host%%/*}"
  if [[ -z "$api_host" ]]; then
    echo "Could not parse kube-apiserver host from doks kubeconfig" >&2
    return 1
  fi
  for i in $(seq 1 90); do
    if dig +short "$api_host" 2>/dev/null | grep -q '[.0-9]'; then
      echo "Kube API DNS ready: $api_host"
      return 0
    fi
    echo "Waiting for Kube API DNS ($i/90): $api_host ..."
    sleep 20
  done
  echo "Timeout waiting for DNS: $api_host" >&2
  return 1
}

# Shell exports override Terragrunt inputs; clear stale test values before every apply.
unset_terragrunt_overrides() {
  unset TF_VAR_k8s_kubeconfig_yaml || true
  unset TF_VAR_email || true
}

apply_stack() {
  local name="$1"
  echo ""
  echo "=============================="
  echo ">>> terragrunt apply: $name"
  echo "=============================="
  (
    cd "$ENV_DEV/$name" || exit 1
    unset_terragrunt_overrides
    TG_NON_INTERACTIVE=true terragrunt init -input=false -reconfigure
    TG_NON_INTERACTIVE=true terragrunt apply -input=false -auto-approve
  )
}

# Stacks that read dependency.doks.outputs.kubeconfig can keep a stale .terragrunt-cache after the cluster is recreated.
apply_k8s_stack() {
  local name="$1"
  rm -rf "${ENV_DEV:?}/${name}/.terragrunt-cache"
  apply_stack "$name"
}

# After a failed traefik apply: show helm/kubectl diagnostics, then remove a stuck release so the next apply is clean.
traefik_apply_failure_cleanup() {
  local kc kcfg pod
  echo "" >&2
  echo "=== traefik apply failed — diagnostics, then helm uninstall if present ===" >&2
  kc="$(cd "$ENV_DEV/doks" && TG_NON_INTERACTIVE=true terragrunt output -raw kubeconfig 2>/dev/null)" || {
    echo "Could not read doks kubeconfig; skipping kubectl/helm cleanup." >&2
    return 0
  }
  kcfg="$(mktemp)"
  printf '%s\n' "$kc" > "$kcfg"
  export KUBECONFIG="$kcfg"

  echo "--- helm status traefik -n traefik ---" >&2
  helm status traefik -n traefik 2>&1 || true
  echo "--- kubectl get pods,svc,pvc -n traefik ---" >&2
  kubectl get pods,svc,pvc -n traefik 2>&1 || true
  if kubectl get pvc -n traefik traefik &>/dev/null && ! helm status traefik -n traefik &>/dev/null; then
    echo "Hint: stuck PVC from a failed install (chart uses resource-policy: keep). To wipe: kubectl delete pvc -n traefik traefik" >&2
  fi
  while IFS= read -r pod; do
    [[ -n "$pod" ]] || continue
    echo "--- kubectl logs -n traefik $pod (last 120 lines, all containers) ---" >&2
    kubectl logs -n traefik "$pod" --tail=120 --all-containers=true 2>&1 || true
  done < <(kubectl get pods -n traefik -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' 2>/dev/null || true)

  if helm status traefik -n traefik &>/dev/null; then
    echo "--- helm uninstall traefik -n traefik ---" >&2
    helm uninstall traefik -n traefik 2>&1 || true
  else
    echo "(no failed Helm release traefik in namespace traefik)" >&2
  fi

  rm -f "$kcfg"
  unset KUBECONFIG
}

# While terragrunt apply runs, follow pod logs. Call this only after init — do not poll the cluster before apply starts.
traefik_logs_follow_bg() {
  local kcfg="$1"
  (
    export KUBECONFIG="$kcfg"
    echo "[traefik] live logs: waiting for namespace traefik (created during apply)..." >&2
    local i
    for i in $(seq 1 360); do
      kubectl get ns traefik &>/dev/null || {
        sleep 2
        continue
      }
      kubectl get deploy -n traefik traefik &>/dev/null && break
      kubectl get pods -n traefik -o name 2>/dev/null | grep -q . && break
      sleep 2
    done
    if kubectl get deploy -n traefik traefik &>/dev/null; then
      echo "[traefik] live logs: kubectl logs -f deploy/traefik (all containers)" >&2
      # -f on Deployment follows the current pod across restarts (kubectl 1.28+)
      exec kubectl logs -n traefik -f deploy/traefik --all-containers=true --tail=60 --prefix=true
    fi
    local p
    p=$(kubectl get pods -n traefik -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
    if [[ -n "$p" ]]; then
      echo "[traefik] live logs: kubectl logs -f pod/$p" >&2
      exec kubectl logs -n traefik -f "$p" --all-containers=true --tail=60 --prefix=true
    fi
    echo "[traefik] live logs: no traefik pods found to follow" >&2
  ) &
  echo $!
}

apply_traefik_stack() {
  rm -rf "${ENV_DEV:?}/traefik/.terragrunt-cache"
  echo ""
  echo "=============================="
  echo ">>> terragrunt apply: traefik"
  echo "=============================="

  local kc kcfg="" logpid=""
  kc="$(cd "$ENV_DEV/doks" && TG_NON_INTERACTIVE=true terragrunt output -raw kubeconfig 2>/dev/null)" || kc=""

  cleanup_traefik_log_stream() {
    if [[ -n "${logpid:-}" ]]; then
      kill "$logpid" 2>/dev/null || true
      wait "$logpid" 2>/dev/null || true
      logpid=""
    fi
    if [[ -n "${kcfg:-}" ]]; then
      rm -f "$kcfg"
      kcfg=""
    fi
  }

  local init_rc=0
  (
    cd "$ENV_DEV/traefik" || exit 1
    unset_terragrunt_overrides
    TG_NON_INTERACTIVE=true terragrunt init -input=false -reconfigure
  ) || init_rc=$?

  if [[ "$init_rc" -ne 0 ]]; then
    echo "terragrunt init failed for traefik; not starting log stream or apply." >&2
    return 1
  fi

  # Start log follower only once init is done and apply is about to run (namespace does not exist yet).
  if [[ -n "$kc" && "${TG_TRAEFIK_LOG_STREAM:-1}" != "0" && -x "$(command -v kubectl || true)" ]]; then
    kcfg="$(mktemp)"
    printf '%s\n' "$kc" > "$kcfg"
    logpid="$(traefik_logs_follow_bg "$kcfg")"
    trap cleanup_traefik_log_stream EXIT INT TERM
  fi

  local apply_rc=0
  (
    cd "$ENV_DEV/traefik" || exit 1
    unset_terragrunt_overrides
    TG_NON_INTERACTIVE=true terragrunt apply -input=false -auto-approve
  ) || apply_rc=$?

  trap - EXIT INT TERM
  cleanup_traefik_log_stream

  if [[ "$apply_rc" -ne 0 ]]; then
    traefik_apply_failure_cleanup
    return 1
  fi
  return 0
}

env_check() {
  load_repo_credentials
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
    load_repo_credentials
    run_in_env_dev init "$@"
    ;;
  validate-all)
    shift || true
    load_repo_credentials
    run_in_env_dev validate "$@"
    ;;
  plan-all)
    shift || true
    load_repo_credentials
    run_in_env_dev plan -input=false "$@"
    ;;
  apply-all)
    shift || true
    env_check
    run_in_env_dev apply -input=false -auto-approve "$@"
    ;;
  apply-sequential)
    shift || true
    env_check
    apply_stack doks
    wait_for_kube_api_dns
    apply_traefik_stack
    apply_stack dns
    apply_k8s_stack argocd
    echo "Sequential apply finished."
    ;;
  apply-traefik)
    shift || true
    env_check
    wait_for_kube_api_dns || true
    apply_traefik_stack
    ;;
  destroy-all)
    shift || true
    env_check
    (
      cd "$ENV_DEV" || exit 1
      unset_terragrunt_overrides
      TG_NON_INTERACTIVE=true terragrunt run-all init -reconfigure -input=false --non-interactive
      if KC="$(cd doks && terragrunt output -raw kubeconfig 2>/dev/null)"; then
        export TF_VAR_k8s_kubeconfig_yaml="$KC"
      fi
      TG_NON_INTERACTIVE=true terragrunt run-all destroy --non-interactive -auto-approve "$@"
    )
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

Same token as CI (repository secret DO_TOKEN): install GitHub CLI, run `gh auth login`,
then either omit TF_VAR_do_token from .env and run ./scripts/tg.sh (it will run
`gh secret get DO_TOKEN` when the vars are empty), or force the GitHub value with:

  export TG_DO_TOKEN_FROM_GITHUB=1
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
