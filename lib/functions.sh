#!/usr/bin/env bash
set -euo pipefail

__MA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARTIFACTS_DIR="${ARTIFACTS_DIR:-${__MA_DIR}/artifacts}"
SNAPSHOTS_DIR="${SNAPSHOTS_DIR:-${__MA_DIR}/snapshots}"
mkdir -p "$ARTIFACTS_DIR" "$SNAPSHOTS_DIR"

__MA_DEFAULT_LOG_LEVEL="info"
if [[ ${LOG_LEVEL+x} ]]; then
  __MA_ORIGINAL_LOG_LEVEL_SET=1
  __MA_ORIGINAL_LOG_LEVEL_VALUE="${LOG_LEVEL}"
else
  __MA_ORIGINAL_LOG_LEVEL_SET=0
  __MA_ORIGINAL_LOG_LEVEL_VALUE=""
fi
LOG_LEVEL="${LOG_LEVEL:-$__MA_DEFAULT_LOG_LEVEL}"

__log_level_value() {
  local level
  level="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
  case "$level" in
    trace) echo 10 ;;
    debug) echo 20 ;;
    info) echo 30 ;;
    notice) echo 35 ;;
    step) echo 35 ;;
    warn|warning) echo 40 ;;
    error|err) echo 50 ;;
    fatal|critical|crit) echo 60 ;;
    quiet|off|silent) echo 100 ;;
    *) return 1 ;;
  esac
}

__LOG_THRESHOLD="$(__log_level_value "$LOG_LEVEL" 2>/dev/null || true)"
if [[ -z "$__LOG_THRESHOLD" ]]; then
  printf '[WARN] Unknown LOG_LEVEL "%s", falling back to "info"\n' "$LOG_LEVEL" >&2
  LOG_LEVEL=info
  __LOG_THRESHOLD="$(__log_level_value "$LOG_LEVEL")"
fi

__should_log() {
  local level
  level="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
  case "$level" in
    error|err|fatal|critical) return 0 ;;
  esac
  local value
  value="$(__log_level_value "$level" 2>/dev/null || true)"
  [[ -n "$value" && "$value" -ge "$__LOG_THRESHOLD" ]]
}

__log_stream() {
  local level="$1"
  case "$level" in
    warn|warning|error|err|fatal|critical) echo stderr ;;
    *) echo stdout ;;
  esac
}

__log_prefix() {
  local level
  level="$(printf '%s' "$1" | tr '[:lower:]' '[:upper:]')"
  case "$level" in
    STEP) printf '[STEP]' ;;
    CMD) printf '[CMD]' ;;
    *) printf '[%s]' "$level" ;;
  esac
}

log_message() {
  local level="$1"; shift
  if __should_log "$level"; then
    local stream
    stream="$(__log_stream "$level")"
    local prefix
    prefix="$(__log_prefix "$level")"
    if [[ "$stream" == "stderr" ]]; then
      printf '%s %s\n' "$prefix" "$*" >&2
    else
      printf '%s %s\n' "$prefix" "$*"
    fi
  fi
}

log_debug() { log_message debug "$@"; }
log_info() { log_message info "$@"; }
log_warn() { log_message warn "$@"; }
log_error() { log_message error "$@"; }

log_step() {
  local number="$1"; shift
  if __should_log info; then
    printf '\n[STEP %s] %s\n' "$number" "$*"
  fi
}

log_cmd() {
  if __should_log info; then
    local quoted
    quoted="$(printf '%q ' "$@")"
    printf '⚙️ [CMD] %s\n' "$quoted"
  fi
}

fail() {
  log_error "$*"
  exit 1
}

require_env() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    fail "Environment variable $name must be set"
  fi
}

require_tool() {
  local tool="$1"
  if ! command -v "$tool" >/dev/null 2>&1; then
    fail "Required tool '$tool' is not installed or not on PATH"
  fi
}

timestamp() {
  date -u +"%Y%m%dT%H%M%SZ"
}

normalize() {
  sed -E \
    -e 's/^[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3} \[[^]]+\] ([A-Z]+[[:space:]]+)/\1/' \
    -e 's/[0-9]{12,}//g' \
    -e 's/[A-Za-z0-9+/=]{20,}/<REDACTED>/g'
}

__sanitize_label() {
  local label="$1"
  label="$(printf '%s' "$label" | tr ' ' '-' | tr -cd 'A-Za-z0-9._-')"
  if [[ -z "$label" ]]; then
    label="command"
  fi
  printf '%s' "$label"
}

run_command() {
  if [[ $# -lt 2 ]]; then
    fail "run_command requires a label and a command"
  fi
  local label="$1"; shift
  local -a env_pairs=()
  if [[ "${1:-}" == "--with-env" ]]; then
    shift
    while [[ $# -gt 0 && "${1:-}" != "--" ]]; do
      env_pairs+=("$1")
      shift
    done
    if [[ "${1:-}" != "--" ]]; then
      fail "run_command '${label}' is missing '--' after --with-env"
    fi
    shift
  fi
  if [[ $# -eq 0 ]]; then
    fail "run_command '${label}' requires a command to execute"
  fi
  local ts
  ts="$(timestamp)"
  local safe_label
  safe_label="$(__sanitize_label "$label")"
  local output_file="${ARTIFACTS_DIR}/${ts}_${safe_label}.out"
  local -a cmd=("$@")

  if __should_log info; then
    local env_display=""
    if (( ${#env_pairs[@]} > 0 )); then
      env_display="$(printf '%s ' "${env_pairs[@]}")"
      env_display="${env_display% }"
    fi
    local cmd_string
    cmd_string="$(printf '%q ' "${cmd[@]}")"
    cmd_string="${cmd_string% }"
    if [[ -n "$cmd_string" ]]; then
      if [[ -n "$env_display" ]]; then
        printf '⚙️ [CMD] %s %s\n' "$env_display" "$cmd_string"
      else
        printf '⚙️ [CMD] %s\n' "$cmd_string"
      fi
    fi
  fi

  local -a exec_cmd
  if (( ${#env_pairs[@]} > 0 )); then
    exec_cmd=(env "${env_pairs[@]}" "${cmd[@]}")
  else
    exec_cmd=("${cmd[@]}")
  fi

  if ! "${exec_cmd[@]}" >"$output_file" 2>&1; then
    local exit_code=$?
    cat "$output_file" >&2 || true
    fail "Command '${label}' failed (exit status ${exit_code}); see $output_file"
  fi

  if __should_log info; then
    cat "$output_file"
  fi

  log_debug "Command '${label}' output saved to $output_file"
  RUN_COMMAND_OUTPUT="$output_file"
}


capture_and_compare() {
  local name="$1"; shift
  log_debug "Capturing output for snapshot '${name}'"

  run_command "$name" "$@"
  local raw_output="$RUN_COMMAND_OUTPUT"
  local normalized_output="${raw_output}.norm"

  normalize <"$raw_output" >"$normalized_output"

  local snapshot_file="$SNAPSHOTS_DIR/${name}.snap"

  if [[ "${UPDATE_SNAPSHOTS:-0}" == "1" ]]; then
    cp "$normalized_output" "$snapshot_file"
    log_info "📝 Snapshot updated: ${snapshot_file}"
  else
    if [[ ! -f "$snapshot_file" ]]; then
      log_error "❌ Snapshot missing: ${snapshot_file}"
      return 1
    fi
    if ! diff -u "$snapshot_file" "$normalized_output"; then
      log_error "❌ Snapshot mismatch for '${name}'"
      return 1
    fi
    log_info "✅ Snapshot '${name}' matches"
  fi

  return 0
}

sanitize_session_name() {
  local raw="$1"
  local cleaned
  cleaned="$(printf '%s' "$raw" | tr -cd 'A-Za-z0-9+=,.@-')"
  if [[ -z "$cleaned" ]]; then
    cleaned="manual-acceptance"
  fi
  printf '%s' "${cleaned:0:64}"
}

run_manual_acceptance_tests() {
  local using_default_suite=0
  local -a tests=()

  local restore_nullglob=0
  if shopt -q nullglob; then
    restore_nullglob=0
  else
    shopt -s nullglob
    restore_nullglob=1
  fi

  trap 'if (( restore_nullglob == 1 )); then shopt -u nullglob; fi; trap - RETURN' RETURN

  if [[ $# -gt 0 ]]; then
    tests=("$@")
  else
    using_default_suite=1
    tests=([0-9][0-9]-*.sh)
  fi

  if (( ${#tests[@]} == 0 )); then
    printf 'No manual acceptance tests found\n' >&2
    return 1
  fi

  local effective_log_level="${LOG_LEVEL:-}"
  if (( using_default_suite == 1 )); then
    local original_level_empty=0
    if (( __MA_ORIGINAL_LOG_LEVEL_SET == 0 )) || [[ -z "${__MA_ORIGINAL_LOG_LEVEL_VALUE}" ]]; then
      original_level_empty=1
    fi
    if (( original_level_empty == 1 )) && [[ -z "$effective_log_level" || "$effective_log_level" == "$__MA_DEFAULT_LOG_LEVEL" ]]; then
      effective_log_level=warn
    fi
  fi

  local test_script
  for test_script in "${tests[@]}"; do
    if [[ ! -x "$test_script" ]]; then
      printf "Test script '%s' not found or not executable\n" "$test_script" >&2
      return 1
    fi

    if [[ -n "$effective_log_level" ]]; then
      printf '▶️  Running %s (log level: %s)\n' "$test_script" "$effective_log_level"
      if LOG_LEVEL="$effective_log_level" "./$test_script"; then
        printf '✅ %s PASSED\n\n' "$test_script"
      else
        printf '❌ %s FAILED\n' "$test_script" >&2
        return 1
      fi
    else
      printf '▶️  Running %s\n' "$test_script"
      if "./$test_script"; then
        printf '✅ %s PASSED\n\n' "$test_script"
      else
        printf '❌ %s FAILED\n' "$test_script" >&2
        return 1
      fi
    fi
  done

  printf '✅ All selected manual acceptance tests passed.\n'
}
