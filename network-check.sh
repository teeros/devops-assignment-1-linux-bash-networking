#!/usr/bin/env bash
#
# network-check.sh - Basic network diagnostics for a host (and optional port).
# Usage: ./network-check.sh <hostname-or-ip> [port]
#
# Exit codes:
#   0 - host resolved and all requested checks succeeded
#   1 - host resolved but a connectivity/port check failed (operational failure)
#   2 - invalid input (missing/invalid host or port)
#
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
LOG_FILE="$LOG_DIR/network-check.log"

log() {
    mkdir -p "$LOG_DIR"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] network-check.sh: $1" >> "$LOG_FILE"
}

usage() {
    echo "Usage: $0 <hostname-or-ip> [port]" >&2
}

HOST="${1:-}"
PORT="${2:-}"
STATUS=0

# --- Validate host ---
if [[ -z "$HOST" ]]; then
    echo "Error: host argument is required." >&2
    usage
    log "Rejected: missing host argument"
    exit 2
fi

# Allow letters, digits, dots, hyphens, underscores, and colons (IPv6)
if ! [[ "$HOST" =~ ^[A-Za-z0-9.:_-]+$ ]]; then
    echo "Error: '$HOST' is not a valid hostname or IP address." >&2
    log "Rejected invalid host: $HOST"
    exit 2
fi

# --- Validate port (if supplied) ---
if [[ -n "$PORT" ]]; then
    if ! [[ "$PORT" =~ ^[0-9]+$ ]]; then
        echo "Error: port must be numeric." >&2
        usage
        log "Rejected non-numeric port: $PORT"
        exit 2
    fi
    if (( PORT < 1 || PORT > 65535 )); then
        echo "Error: port must be between 1 and 65535." >&2
        usage
        log "Rejected out-of-range port: $PORT"
        exit 2
    fi
fi

echo "=========================================="
echo "          NETWORK CONNECTIVITY CHECK"
echo "=========================================="
echo "Target Host     : $HOST"
[[ -n "$PORT" ]] && echo "Target Port     : $PORT"
echo

# --- Resolve host ---
RESOLVED=""
if command -v getent >/dev/null 2>&1; then
    RESOLVED=$(getent hosts "$HOST" 2>/dev/null | awk '{print $1}' | head -n1)
fi
if [[ -z "$RESOLVED" ]] && command -v dig >/dev/null 2>&1; then
    RESOLVED=$(dig +short "$HOST" 2>/dev/null | head -n1)
fi
if [[ -z "$RESOLVED" ]] && command -v host >/dev/null 2>&1; then
    RESOLVED=$(host "$HOST" 2>/dev/null | awk '/has address/ {print $4; exit}')
fi
if [[ -z "$RESOLVED" ]] && command -v python3 >/dev/null 2>&1; then
    RESOLVED=$(python3 -c "import socket,sys
try:
    print(socket.gethostbyname(sys.argv[1]))
except Exception:
    pass" "$HOST" 2>/dev/null)
fi
# Already an IP address? Accept as-is.
if [[ -z "$RESOLVED" ]] && [[ "$HOST" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    RESOLVED="$HOST"
fi

if [[ -n "$RESOLVED" ]]; then
    echo "Resolved Address: $RESOLVED"
    log "Resolved host $HOST -> $RESOLVED"
else
    echo "Resolved Address: UNRESOLVED"
    log "Failed to resolve host: $HOST"
    STATUS=1
fi

# --- Basic connectivity check (ICMP ping) ---
echo
echo "------------------------------------------"
echo "Connectivity (ping) check:"
if command -v ping >/dev/null 2>&1; then
    if ping -c 1 -W 2 "$HOST" >/dev/null 2>&1; then
        echo "  Host is reachable (ping)."
        log "Ping to $HOST succeeded"
    else
        echo "  Host did not respond to ping (may be blocked by firewall)."
        log "Ping to $HOST failed"
        STATUS=1
    fi
else
    echo "  ping command not available; skipping."
fi

# --- Network interface information ---
echo
echo "------------------------------------------"
echo "Network interfaces:"
if command -v ip >/dev/null 2>&1; then
    ip -brief addr show 2>/dev/null || ip addr show
elif command -v ifconfig >/dev/null 2>&1; then
    ifconfig
else
    echo "  No interface tool (ip/ifconfig) available."
fi

# --- TCP port check ---
if [[ -n "$PORT" ]]; then
    echo
    echo "------------------------------------------"
    echo "TCP port check ($HOST:$PORT):"
    if timeout 3 bash -c "echo > /dev/tcp/$HOST/$PORT" >/dev/null 2>&1; then
        echo "  Port $PORT is OPEN on $HOST."
        log "TCP check $HOST:$PORT succeeded"
    else
        echo "  Port $PORT is CLOSED or unreachable on $HOST."
        log "TCP check $HOST:$PORT failed"
        STATUS=1
    fi
fi

echo "=========================================="

log "Completed check for host=$HOST port=${PORT:-none} exit_status=$STATUS"

exit "$STATUS"
