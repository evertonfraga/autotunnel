# autotunnel

Auto-discovers listening ports on a remote host and creates SSH tunnels for them locally.

## How it works

1. **Remote** (`check_ports.sh`): Periodically scans for listening TCP ports, excludes well-known services (SSH, nginx, redis, containerd), writes the rest to `~/.TUNNEL_PORTS`
2. **Local** (`tunnel-monitor.sh`): Runs on a schedule, checks if there's an active SSH session to the remote host, reads the port list, and creates any missing `-L` tunnels

Only creates tunnels when you already have an interactive SSH session open — no tunnels are created otherwise.

## Setup

Edit `autotunnel.conf` to match your environment, then:

```bash
# Install the local scheduled task (macOS launchd)
./install-local.sh

# Deploy check_ports.sh to remote and set up cron
./install-remote.sh
```

## Uninstall

```bash
# Local
launchctl unload ~/Library/LaunchAgents/com.autotunnel.monitor.plist
rm ~/Library/LaunchAgents/com.autotunnel.monitor.plist

# Remote
ssh devbox "crontab -l | grep -v check_ports.sh | crontab -"
```

## Configuration

All settings live in `autotunnel.conf`:

| Variable | Default | Description |
|---|---|---|
| `REMOTE_HOST` | `devbox` | SSH host alias or address |
| `REMOTE_USER` | `ec2-user` | Remote username |
| `REMOTE_HOME` | `/home/ec2-user` | Remote home directory |
| `EXCLUDE_PORTS` | `22` | Ports to never tunnel |
| `CHECK_INTERVAL` | `30` | Seconds between local checks |
| `LOG_FILE` | `~/.autotunnel.log` | Local log path |
