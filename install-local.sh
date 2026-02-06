#!/bin/bash
# install-local.sh — Sets up the local launchd scheduled task (macOS).

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONF="$SCRIPT_DIR/autotunnel.conf"
[ -f "$CONF" ] && source "$CONF"

CHECK_INTERVAL="${CHECK_INTERVAL:-30}"
PLIST_NAME="com.autotunnel.monitor"
PLIST_PATH="$HOME/Library/LaunchAgents/$PLIST_NAME.plist"

echo "Installing autotunnel local monitor..."

# Make scripts executable
chmod +x "$SCRIPT_DIR/local/tunnel-monitor.sh"

cat > "$PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$PLIST_NAME</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>$SCRIPT_DIR/local/tunnel-monitor.sh</string>
    </array>
    <key>StartInterval</key>
    <integer>$CHECK_INTERVAL</integer>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardErrorPath</key>
    <string>/tmp/autotunnel.err</string>
</dict>
</plist>
EOF

launchctl unload "$PLIST_PATH" 2>/dev/null || true
launchctl load "$PLIST_PATH"

echo "Installed: $PLIST_PATH (every ${CHECK_INTERVAL}s)"
echo "Logs: ${LOG_FILE:-$HOME/.autotunnel.log}"
echo "Errors: /tmp/autotunnel.err"
