#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

CONF_FILE="${SCRIPT_DIR}/run.conf"
LOCAL_LIB="$(grep '^localLib=' "$CONF_FILE" | cut -d'=' -f2-)"

CACHE_DIR="${SCRIPT_DIR}/.cache/"

# --- ensure harness copied into local .cache ---
if [[ -n "$LOCAL_LIB" ]]; then
  mkdir -p "$CACHE_DIR"
  echo "Syncing harness from $LOCAL_LIB → $CACHE_DIR"
  rsync -a --delete "${LOCAL_LIB}/" "$CACHE_DIR/"
else
  echo "Error: run.conf must set localLib when testing locally" >&2
  exit 1
fi

# --- source harness code ---
source "${CACHE_DIR}/functions.sh"

# --- delegate to harness runner ---
run_manual_acceptance_tests "$@"
