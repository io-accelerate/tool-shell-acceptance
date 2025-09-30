#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

CONF_FILE="${SCRIPT_DIR}/run.conf"
CACHE_DIR="${SCRIPT_DIR}/.cache/"
PREVIOUS_URL_FILE="${CACHE_DIR}/previous_distribution_url"

# Parse localLib and distributionUrl from run.conf
LOCAL_LIB="$(grep '^localLib=' "$CONF_FILE" | cut -d'=' -f2- || true)"
DISTRIBUTION_URL="$(grep '^distributionUrl=' "$CONF_FILE" | cut -d'=' -f2- || true)"

# Ensure .cache directory exists
mkdir -p "$CACHE_DIR"

# Handle missing distributionUrl
if [[ -n "$DISTRIBUTION_URL" ]]; then
  CACHED_FILE="${CACHE_DIR}/$(basename "$DISTRIBUTION_URL")"

  # Read the previously used URL
  PREVIOUS_URL=""
  if [[ -f "$PREVIOUS_URL_FILE" ]]; then
    PREVIOUS_URL="$(<"$PREVIOUS_URL_FILE")"
  fi

  # Invalidate cache if DISTRIBUTION_URL has changed
  if [[ "$DISTRIBUTION_URL" != "$PREVIOUS_URL" ]]; then
    echo "DISTRIBUTION_URL has changed. Clearing old cache and refreshing..."
    rm -f "${CACHE_DIR}"/*
    echo "$DISTRIBUTION_URL" > "$PREVIOUS_URL_FILE"
  fi

  # Download and cache the artifact if it doesn't exist
  if [[ ! -f "$CACHED_FILE" ]]; then
    echo "Downloading and caching artifact from $DISTRIBUTION_URL → $CACHED_FILE"
    curl -L -o "$CACHED_FILE" "$DISTRIBUTION_URL"
  fi
else
  echo "DISTRIBUTION_URL is not set. Ensuring LOCAL_LIB is configured..."
  
  if [[ -z "$LOCAL_LIB" ]]; then
    echo "Error: LOCAL_LIB must be set if distributionUrl is not defined." >&2
    exit 1
  fi
fi

# Sync local library if LOCAL_LIB is set
if [[ -n "$LOCAL_LIB" ]]; then
  echo "Syncing harness from $LOCAL_LIB → $CACHE_DIR"
  rsync -a --delete "${LOCAL_LIB}/" "$CACHE_DIR/"
fi

# --- source harness code ---
source "${CACHE_DIR}/functions.sh"

# --- delegate to harness runner ---
run_manual_acceptance_tests "$@"