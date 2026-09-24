#!/usr/bin/env bash
#
# disk-check.sh - Check disk usage against a threshold.
# Usage: ./disk-check.sh <threshold> [path]
#   threshold : integer 1-100 (percent)
#   path      : filesystem path to check (default: /)
#
# Exit codes:
#   0 - usage is below threshold
#   1 - usage is at or above threshold
#   2 - invalid input
#
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
LOG_FILE="$LOG_DIR/disk-check.log"

log() {
    mkdir -p "$LOG_DIR"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] disk-check.sh: $1" >> "$LOG_FILE"
}

usage() {
    echo "Usage: $0 <threshold 1-100> [path]" >&2
}

THRESHOLD="${1:-}"
PATH_ARG="${2:-/}"

# Validate threshold: must be present and a positive integer
if [[ -z "$THRESHOLD" ]]; then
    echo "Error: threshold is required." >&2
    usage
    log "Rejected: missing threshold"
    exit 2
fi

if ! [[ "$THRESHOLD" =~ ^[0-9]+$ ]]; then
    echo "Error: threshold must be a positive integer." >&2
    usage
    log "Rejected invalid threshold: $THRESHOLD"
    exit 2
fi

if (( THRESHOLD < 1 || THRESHOLD > 100 )); then
    echo "Error: threshold must be between 1 and 100." >&2
    usage
    log "Rejected out-of-range threshold: $THRESHOLD"
    exit 2
fi

# Validate path
if [[ ! -e "$PATH_ARG" ]]; then
    echo "Error: path '$PATH_ARG' does not exist." >&2
    log "Rejected invalid path: $PATH_ARG"
    exit 2
fi

# Get disk usage percentage (POSIX -P output is portable across Linux/macOS)
USAGE_LINE=$(df -P "$PATH_ARG" 2>/dev/null | awk 'NR==2 {print $5}' | tr -d '%')

if [[ -z "$USAGE_LINE" || ! "$USAGE_LINE" =~ ^[0-9]+$ ]]; then
    echo "Error: unable to determine disk usage for '$PATH_ARG'." >&2
    log "Failed to determine disk usage for path: $PATH_ARG"
    exit 2
fi

USAGE="$USAGE_LINE"

echo "=========================================="
echo "            DISK USAGE CHECK"
echo "=========================================="
echo "Path            : $PATH_ARG"
echo "Threshold       : ${THRESHOLD}%"
echo "Current Usage   : ${USAGE}%"
echo "=========================================="

log "Checked path=$PATH_ARG threshold=${THRESHOLD}% usage=${USAGE}%"

if (( USAGE >= THRESHOLD )); then
    echo "WARNING: Disk usage (${USAGE}%) has reached or exceeded the threshold (${THRESHOLD}%)."
    log "Result: usage ${USAGE}% >= threshold ${THRESHOLD}% (FAIL)"
    exit 1
else
    echo "OK: Disk usage (${USAGE}%) is below the threshold (${THRESHOLD}%)."
    log "Result: usage ${USAGE}% < threshold ${THRESHOLD}% (OK)"
    exit 0
fi
