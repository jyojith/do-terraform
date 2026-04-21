#!/usr/bin/env bash
# Create and push a deploy/* tag on main to trigger .github/workflows/terragrunt-apply.yml
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

usage() {
  sed -n '1,120p' <<'EOF'
Usage: ./scripts/tag-deploy.sh [options] [TAG] [COMMIT]

Creates an annotated git tag matching deploy/** and pushes it to origin.
Pushing the tag triggers GitHub Actions: terragrunt run-all apply for environments/dev
(only if the tagged commit is on main).

  TAG       Tag name. If omitted, defaults to deploy/YYYYMMDD-HHMMSS (UTC).
            Must start with deploy/ (e.g. deploy/20250421-143000 or deploy/v1.2.0).

  COMMIT    Optional commit-ish to tag (default: HEAD after updating main).
            Must be an ancestor of origin/main after fetch.

Options:
  -n, --dry-run   Print actions only; do not create or push a tag.
  -h, --help      Show this help.

Examples:
  ./scripts/tag-deploy.sh
  ./scripts/tag-deploy.sh deploy/release-2025-04-21
  ./scripts/tag-deploy.sh deploy/hotfix-1 abcdef1

Prerequisites:
  - Clean working tree recommended.
  - git remote "origin" must exist; you must have push access for tags.
EOF
}

DRY_RUN=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    -n | --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    -*)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
    *)
      break
      ;;
  esac
done

TAG="${1:-}"
COMMIT="${2:-HEAD}"

if [[ $# -gt 2 ]]; then
  echo "Too many arguments." >&2
  usage >&2
  exit 1
fi

if [[ -z "${TAG}" ]]; then
  TAG="deploy/$(date -u +%Y%m%d-%H%M%S)"
fi

if [[ "${TAG}" != deploy/* ]]; then
  echo "Tag must start with deploy/ (GitHub workflow matches deploy/**). Got: ${TAG}" >&2
  exit 1
fi

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "Not a git repository." >&2
  exit 1
fi

git fetch origin main

if [[ "${DRY_RUN}" -eq 1 ]]; then
  echo "[dry-run] Would verify ${COMMIT} is on origin/main, then:"
  echo "[dry-run]   git tag -a ${TAG} ${COMMIT} -m \"...\""
  echo "[dry-run]   git push origin ${TAG}"
  exit 0
fi

if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
  echo "Warning: working tree is not clean. Continue? (Tags the given COMMIT, not uncommitted files.)" >&2
fi

if ! git merge-base --is-ancestor "${COMMIT}" "origin/main"; then
  echo "Refusing: ${COMMIT} is not an ancestor of origin/main." >&2
  exit 1
fi

git tag -a "${TAG}" "${COMMIT}" -m "deploy: trigger CI terragrunt apply (${COMMIT})"
git push origin "${TAG}"
echo "Pushed tag ${TAG} — CI will run terragrunt apply for that commit if workflows are enabled."
