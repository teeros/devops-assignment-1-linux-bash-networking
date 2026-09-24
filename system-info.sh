#!/usr/bin/env bash
#
# system-info.sh - Display key Linux system information.
# Usage: ./system-info.sh
#
set -u

LOG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/logs"
LOG_FILE="$LOG_DIR/system-info.log"

log() {
    mkdir -p "$LOG_DIR"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] system-info.sh: $1" >> "$LOG_FILE"
}

log "Collecting system information"

echo "=========================================="
echo "            SYSTEM INFORMATION"
echo "=========================================="

# Hostname
echo "Hostname        : $(hostname 2>/dev/null || cat /etc/hostname 2>/dev/null || echo "unknown")"

# Current user
echo "Current User    : $(whoami 2>/dev/null || id -un 2>/dev/null || echo "$USER")"

# Date / time
echo "Date/Time       : $(date '+%Y-%m-%d %H:%M:%S %Z')"

# Operating system
if [[ -f /etc/os-release ]]; then
    OS_NAME="$(. /etc/os-release && echo "$PRETTY_NAME")"
else
    OS_NAME="$(uname -s)"
fi
echo "Operating System: $OS_NAME"

# Kernel version
echo "Kernel Version  : $(uname -r)"

# Uptime
if command -v uptime >/dev/null 2>&1; then
    echo "Uptime          : $(uptime -p 2>/dev/null || uptime)"
else
    echo "Uptime          : unavailable"
fi

# CPU information
echo "------------------------------------------"
echo "CPU INFORMATION"
echo "------------------------------------------"
if [[ -f /proc/cpuinfo ]]; then
    CPU_MODEL=$(grep -m1 "model name" /proc/cpuinfo 2>/dev/null | cut -d: -f2 | sed 's/^ *//')
    [[ -z "$CPU_MODEL" ]] && CPU_MODEL="unknown"
    CPU_CORES=$(grep -c "^processor" /proc/cpuinfo 2>/dev/null)
    echo "CPU Model       : $CPU_MODEL"
    echo "CPU Cores       : ${CPU_CORES:-unknown}"
elif command -v nproc >/dev/null 2>&1; then
    echo "CPU Cores       : $(nproc)"
else
    echo "CPU Information : unavailable"
fi

# Memory information
echo "------------------------------------------"
echo "MEMORY INFORMATION"
echo "------------------------------------------"
if command -v free >/dev/null 2>&1; then
    free -h
elif [[ -f /proc/meminfo ]]; then
    grep -E "^(MemTotal|MemFree|MemAvailable)" /proc/meminfo
else
    echo "Memory information unavailable"
fi

# Current working directory
echo "------------------------------------------"
echo "Current Working Directory: $(pwd)"
echo "=========================================="

log "System information displayed successfully"

exit 0
