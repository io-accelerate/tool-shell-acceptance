#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CACHE_DIR="${SCRIPT_DIR}/.cache"

source "${CACHE_DIR}/functions.sh"

capture_and_compare normalize-example bash -lc "set -euo pipefail
printf '%s\n' \\
  '12:34:56.789 [runner] STEP Running command' \\
  '12:34:56.790 [runner] INFO Completed action 1234567890123456' \\
  'Attachment ID: 202012311234567890' \\
  'Secret token: dGhpc2lzYXZlcnlsb25nZ2FsbGllZHVzZWN1cmV0ZXh0'"
