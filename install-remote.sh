#!/bin/bash
# install-remote.sh — Deploys check_ports.sh to the remote host and sets up a cron job.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONF="$SCRIPT_DIR/autotunnel.conf"
[ -f "$CONF" ] && source "$CONF"

REMOTE="${REMOTE_HOST:-devbox}"
REMOTE_HOME="${REMOTE_HOME:-/home/ec2-user}"
CHECK_INTERVAL="${CHECK_INTERVAL:-30}"

echo "Deploying to $REMOTE..."

# Copy files
scp "$SCRIPT_DIR/remote/check_ports.sh" "$SCRIPT_DIR/autotunnel.conf" "$REMOTE:$REMOTE_HOME/"
ssh "$REMOTE" "chmod +x $REMOTE_HOME/check_ports.sh"

# Install cron (run every minute — cron minimum granularity)
CRON_LINE="* * * * * $REMOTE_HOME/check_ports.sh"
ssh "$REMOTE" "(crontab -l 2>/dev/null | grep -v check_ports.sh; echo '$CRON_LINE') | crontab -"

echo "Deployed check_ports.sh to $REMOTE:$REMOTE_HOME/"
echo "Cron installed (every minute)"
