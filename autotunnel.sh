#!/bin/bash
# autotunnel.sh — Discovers listening ports on remote host via SSH,
# creates missing local tunnels via ControlMaster multiplexing.
#
# Usage:
#   autotunnel.sh              # run once
#   autotunnel.sh loop         # run continuously until SSH session ends

PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONF="$SCRIPT_DIR/autotunnel.conf"
[ -f "$CONF" ] && source "$CONF"

REMOTE="${REMOTE_HOST:-devbox}"
EXCLUDE_PORTS="${EXCLUDE_PORTS:-22}"
CHECK_INTERVAL="${CHECK_INTERVAL:-30}"
LOG_FILE="${LOG_FILE:-$HOME/.autotunnel.log}"
SOCKET="${AUTOTUNNEL_SOCKET:-$HOME/.ssh/autotunnel-$REMOTE.sock}"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"; }

has_session() {
  ssh -S "$SOCKET" -O check "$REMOTE" 2>/dev/null
}

check_tunnels() {
  has_session || return 1

  EXCLUDE_RE=$(echo "$EXCLUDE_PORTS" | tr ' ' '|')

  PORTS=$(ssh -S "$SOCKET" "$REMOTE" \
    "ss -tlnp 2>/dev/null | awk 'NR>1 && \$1==\"LISTEN\" {print \$4}' | grep -o '[0-9]*$' | sort -u" \
    2>/dev/null | grep -vE "^($EXCLUDE_RE)$" | tr '\n' ' ')

  [ -z "$PORTS" ] && return 0

  log "Ports: $PORTS"
  for PORT in $PORTS; do
    if ! ssh -S "$SOCKET" -O check "$REMOTE" 2>&1 | grep -q "$PORT"; then
      # Try forwarding — fails silently if already bound
      ssh -S "$SOCKET" -O forward -L "$PORT:localhost:$PORT" "$REMOTE" 2>/dev/null && \
        log "Port $PORT: tunnel created"
    fi
  done
}

if [ "$1" = "loop" ]; then
  log "Starting autotunnel loop for $REMOTE (every ${CHECK_INTERVAL}s)"
  while has_session; do
    check_tunnels
    sleep "$CHECK_INTERVAL"
  done
  log "SSH session to $REMOTE ended. Exiting loop."
else
  if has_session; then
    check_tunnels
  else
    log "No active SSH session to $REMOTE. Skipping."
  fi
fi
