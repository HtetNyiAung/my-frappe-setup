#!/usr/bin/env bash
# Shared lifecycle and output logging for docker-setup operational scripts.

script_logging_write() {
    local message="$1"

    if [ "${SCRIPT_LOG_MODE:-capture}" = "metadata" ]; then
        printf '%s\n' "$message"
        printf '%s\n' "$message" >>"$SCRIPT_LOG_FILE"
    else
        printf '%s\n' "$message"
    fi
}

script_logging_finish() {
    local exit_status="${1:-0}"
    local finished_at
    local finished_epoch
    local duration

    trap - EXIT
    finished_at=$(date '+%Y-%m-%d %H:%M:%S %z')
    finished_epoch=$(date +%s)
    duration=$((finished_epoch - SCRIPT_LOG_START_EPOCH))
    script_logging_write "[$finished_at] END script=$SCRIPT_LOG_NAME status=$exit_status duration_seconds=$duration"
}

apply_script_log_retention() {
    local retention_days="${1:-30}"
    local log_dir

    log_dir="$(dirname "$SCRIPT_LOG_FILE")"
    if [[ "$retention_days" =~ ^[1-9][0-9]*$ ]]; then
        find "$log_dir" -maxdepth 1 -type f -name '*.log' \
            -mtime +"$retention_days" -delete
    else
        script_logging_write \
            "Warning: SCRIPT_LOG_RETENTION_DAYS ($retention_days) must be a positive integer; skipping log cleanup."
    fi
}

init_script_logging() {
    local base_dir="$1"
    local script_name="$2"
    local mode="${3:-capture}"
    local log_root="${SCRIPT_LOG_DIR:-$base_dir/logs/scripts}"
    local log_dir="$log_root/$script_name"
    local started_at
    local timestamp

    mkdir -p "$log_dir"
    chmod 750 "$log_root" "$log_dir" 2>/dev/null || true

    timestamp=$(date '+%Y-%m-%d_%H-%M-%S')
    SCRIPT_LOG_FILE="$log_dir/${timestamp}_$$.log"
    SCRIPT_LOG_NAME="$script_name"
    SCRIPT_LOG_MODE="$mode"
    SCRIPT_LOG_START_EPOCH=$(date +%s)

    : >"$SCRIPT_LOG_FILE"
    chmod 640 "$SCRIPT_LOG_FILE" 2>/dev/null || true

    if [ "$mode" = "capture" ]; then
        exec > >(tee -a "$SCRIPT_LOG_FILE") 2>&1
    fi

    started_at=$(date '+%Y-%m-%d %H:%M:%S %z')
    script_logging_write "[$started_at] START script=$script_name user=$(id -un) host=$(hostname) pid=$$"
    script_logging_write "Log file: $SCRIPT_LOG_FILE"
    trap 'script_logging_finish "$?"' EXIT
}
