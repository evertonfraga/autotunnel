#!/bin/bash
# check_ports.sh — Runs on the remote host. Discovers listening ports,
# excludes well-known services, writes the rest to TUNNEL_PORTS_FILE.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONF="$SCRIPT_DIR/autotunnel.conf"
[ -f "$CONF" ] && source "$CONF"

REMOTE_HOME="${REMOTE_HOME:-/home/ec2-user}"
TUNNEL_PORTS_FILE="${TUNNEL_PORTS_FILE:-.TUNNEL_PORTS}"
EXCLUDE_PORTS="${EXCLUDE_PORTS:-22}"

# Build grep exclusion pattern
EXCLUDE_PATTERN=$(echo "$EXCLUDE_PORTS" | tr ' ' '\n' | paste -sd'|' | sed 's/|/\\|/g')

/usr/sbin/ss -tlnp 2>/dev/null \
  | awk 'NR>1 && $1=="LISTEN" {print $4}' \
  | grep -o '[0-9]*$' \
  | grep -vE "^($EXCLUDE_PATTERN)$" \
  | sort -u > "$REMOTE_HOME/$TUNNEL_PORTS_FILE"
