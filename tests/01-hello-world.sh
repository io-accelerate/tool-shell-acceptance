#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CACHE_DIR="${SCRIPT_DIR}/.cache"

source "${CACHE_DIR}/functions.sh"

capture_and_compare hello-world echo "Hello, World!"
