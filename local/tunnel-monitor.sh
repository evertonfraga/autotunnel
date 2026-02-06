#!/bin/bash
# tunnel-monitor.sh — Runs locally. Checks for active SSH session to remote,
# reads discovered ports, and creates missing tunnels.

PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONF="$SCRIPT_DIR/autotunnel.conf"
[ -f "$CONF" ] && source "$CONF"

REMOTE="${REMOTE_HOST:-devbox}"
REMOTE_HOME="${REMOTE_HOME:-/home/ec2-user}"
TUNNEL_PORTS_FILE="${TUNNEL_PORTS_FILE:-.TUNNEL_PORTS}"
LOG_FILE="${LOG_FILE:-$HOME/.autotunnel.log}"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"; }

log "Checking SSH connection to $REMOTE"

# Exit if no interactive SSH session (exclude background tunnels)
if ! pgrep -lf "ssh.*$REMOTE" | grep -v "ssh -fNT" > /dev/null; then
  log "No active SSH session found. Exiting."
  exit 0
fi

log "Active SSH session found"

PORTS=$(ssh "$REMOTE" "cat $REMOTE_HOME/$TUNNEL_PORTS_FILE 2>/dev/null" | tr '\n' ' ')
if [ -z "$PORTS" ]; then
  log "No ports found. Exiting."
  exit 0
fi

log "Ports to monitor: $PORTS"

for PORT in $PORTS; do
  if pgrep -f "ssh.*-L $PORT:localhost:$PORT.*$REMOTE" > /dev/null; then
    log "Port $PORT: tunnel exists"
  else
    log "Port $PORT: creating tunnel"
    ssh -fNT -L "$PORT:localhost:$PORT" "$REMOTE"
  fi
done

log "Done"
