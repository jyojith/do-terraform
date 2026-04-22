#!/usr/bin/env bash
# Run in a second terminal while ./scripts/tg.sh apply-traefik runs in the first (use TG_TRAEFIK_LOG_STREAM=0 on apply).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_DEV="${ENV_DEV:-$ROOT/environments/dev}"

if [[ -f "$ROOT/.env" ]]; then
  set +u
  set -a
  # shellcheck source=/dev/null
  source "$ROOT/.env"
  set +a
  set -u
fi

KC="$(cd "$ENV_DEV/doks" && TG_NON_INTERACTIVE=true terragrunt output -raw kubeconfig)"
KCFG="$(mktemp /tmp/doks-kubeconfig.XXXXXX)"
printf '%s\n' "$KC" > "$KCFG"
export KUBECONFIG="$KCFG"
# shellcheck disable=SC2064
trap 'rm -f "$KCFG"' EXIT

echo "Waiting for namespace traefik..."
for _ in $(seq 1 300); do
  kubectl get ns traefik &>/dev/null && break
  sleep 2
done

echo "Waiting for Traefik pod Ready (up to 10m)..."
kubectl wait --for=condition=ready pod -n traefik -l app.kubernetes.io/name=traefik --timeout=600s 2>/dev/null || \
kubectl wait --for=condition=ready pod -n traefik -l app.kubernetes.io/instance=traefik --timeout=600s 2>/dev/null || \
  { echo "No ready pod yet; try: kubectl get pods -n traefik"; exit 1; }

echo "Following logs (Ctrl+C to stop)..."
exec kubectl logs -n traefik -f deploy/traefik --all-containers=true --tail=100 --prefix=true
