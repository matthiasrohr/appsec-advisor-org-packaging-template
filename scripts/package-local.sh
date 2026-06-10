#!/usr/bin/env bash
set -euo pipefail

SOURCE="${APPSEC_ADVISOR_SOURCE:-}"
DEST="${APPSEC_ADVISOR_DEST:-upstream/appsec-advisor}"
INTERNAL_NAME="${INTERNAL_NAME:-example-appsec}"
VERSION="${VERSION:-0.4.0-local}"
ARCHIVE="${ARCHIVE:-0}"
DESCRIPTION="${DESCRIPTION:-Internal packaged build of appsec-advisor with Example Corp defaults.}"

if [ -z "${SOURCE}" ]; then
  scripts/fetch-upstream.sh
  SOURCE="${DEST}"
fi

if [ ! -f "${SOURCE}/scripts/package_internal_plugin.py" ]; then
  echo "ERROR: APPSEC_ADVISOR_SOURCE is not an appsec-advisor checkout: ${SOURCE}" >&2
  exit 2
fi

EXTRA_ARGS="--skip-archive"
if [ "${ARCHIVE}" = "1" ] || [ "${ARCHIVE}" = "true" ]; then
  EXTRA_ARGS=""
fi

# shellcheck disable=SC2086
python3 "${SOURCE}/scripts/package_internal_plugin.py" \
  --source "${SOURCE}" \
  --org-profile org-profile \
  --name "${INTERNAL_NAME}" \
  --version "${VERSION}" \
  --description "${DESCRIPTION}" \
  ${EXTRA_ARGS}

python3 "${SOURCE}/scripts/smoke_test_package.py" \
  "build/${INTERNAL_NAME}" \
  --name "${INTERNAL_NAME}"
