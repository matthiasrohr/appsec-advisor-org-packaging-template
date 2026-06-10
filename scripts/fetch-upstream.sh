#!/usr/bin/env bash
set -euo pipefail

URL="${APPSEC_ADVISOR_URL:-https://github.com/matthiasrohr/appsec-advisor.git}"
REF="${APPSEC_ADVISOR_REF:-latest}"
DEST="${APPSEC_ADVISOR_DEST:-upstream/appsec-advisor}"

case "${URL}" in
  *"github.com/matthiasrohr?tab=repositories"*)
    echo "ERROR: APPSEC_ADVISOR_URL must be the repository clone URL, not the GitHub repositories overview." >&2
    echo "Use: https://github.com/matthiasrohr/appsec-advisor.git" >&2
    exit 2
    ;;
esac

if [ -e "${DEST}" ]; then
  if ! git -C "${DEST}" rev-parse --git-dir >/dev/null 2>&1; then
    echo "ERROR: ${DEST} exists but is not a git checkout" >&2
    exit 2
  fi
else
  mkdir -p "$(dirname "${DEST}")"
  git clone --filter=blob:none --no-checkout "${URL}" "${DEST}"
fi

if git -C "${DEST}" remote get-url origin >/dev/null 2>&1; then
  git -C "${DEST}" remote set-url origin "${URL}"
else
  git -C "${DEST}" remote add origin "${URL}"
fi

if [ "${REF}" = "latest" ]; then
  RESOLVED_REF="$(
    git -C "${DEST}" ls-remote --tags --refs origin 'v[0-9]*' |
      awk -F/ '{print $NF}' |
      sort -V |
      tail -n 1
  )"
  if [ -z "${RESOLVED_REF}" ]; then
    echo "ERROR: could not resolve latest appsec-advisor release tag from ${URL}" >&2
    exit 2
  fi
  echo "==> Resolved APPSEC_ADVISOR_REF=latest to ${RESOLVED_REF}"
else
  RESOLVED_REF="${REF}"
fi

if git -C "${DEST}" ls-remote --exit-code --tags origin "refs/tags/${RESOLVED_REF}" >/dev/null 2>&1; then
  git -C "${DEST}" fetch --depth 1 origin "refs/tags/${RESOLVED_REF}:refs/tags/${RESOLVED_REF}"
  git -C "${DEST}" checkout --detach "refs/tags/${RESOLVED_REF}"
elif git -C "${DEST}" ls-remote --exit-code --heads origin "refs/heads/${RESOLVED_REF}" >/dev/null 2>&1; then
  git -C "${DEST}" fetch --depth 1 origin "refs/heads/${RESOLVED_REF}"
  git -C "${DEST}" checkout --detach FETCH_HEAD
else
  git -C "${DEST}" fetch --depth 1 origin "${RESOLVED_REF}"
  git -C "${DEST}" checkout --detach FETCH_HEAD
fi

echo "==> Upstream ready at ${DEST}: $(git -C "${DEST}" rev-parse --short HEAD)"
