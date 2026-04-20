#!/usr/bin/env bash
# Mirror of the inline "Checkout" step in .github/workflows/*.yml
# Do not call this as the first CI step — the repo is not checked out yet.
# Use for local testing: GITHUB_WORKSPACE=$PWD GITHUB_REPOSITORY=owner/repo GITHUB_SHA=… bash ci-checkout.sh shallow
set -euo pipefail

MODE="${1:?usage: ci-checkout.sh <shallow|full>}"
REPO_URL="https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"

cd "${GITHUB_WORKSPACE}"

if [ "${GITHUB_EVENT_NAME}" = "pull_request" ]; then
  if [ -z "${PR_NUMBER:-}" ]; then
    echo "PR_NUMBER is required for pull_request events" >&2
    exit 1
  fi
  git init -q
  git remote add origin "${REPO_URL}"
  git fetch --depth=1 origin "refs/pull/${PR_NUMBER}/merge"
  git checkout --detach FETCH_HEAD
elif [ "${MODE}" = "full" ]; then
  git clone "${REPO_URL}" .
  git checkout "${GITHUB_SHA}"
else
  git init -q
  git remote add origin "${REPO_URL}"
  git fetch --depth=1 origin "${GITHUB_SHA}"
  git checkout --detach FETCH_HEAD
fi
