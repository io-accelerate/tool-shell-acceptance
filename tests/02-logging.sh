#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CACHE_DIR="${SCRIPT_DIR}/.cache"

source "${CACHE_DIR}/functions.sh"

capture_and_compare logging-functions \
  --with-env "LOG_LEVEL=debug" \
  -- bash -lc "set -euo pipefail
source \"${CACHE_DIR}/functions.sh\"
log_debug 'Debug message when LOG_LEVEL=debug'
log_info 'Informational message'
log_warn 'Something worth warning about'
log_error 'An error occurred'
log_step 1 'Logging step output'
log_cmd echo 'hello from log_cmd'"
