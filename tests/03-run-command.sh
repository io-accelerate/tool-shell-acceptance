#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CACHE_DIR="${SCRIPT_DIR}/.cache"

source "${CACHE_DIR}/functions.sh"

require_tool cat

run_command sample-run bash -lc 'printf "Saved output from run_command\\nReusable content verified via capture_and_compare\\n"'

capture_and_compare reuse-run-command cat "$RUN_COMMAND_OUTPUT"
