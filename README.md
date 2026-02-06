# autotunnel

Auto-discovers listening ports on a remote host and creates SSH tunnels for them locally. Nothing to install on the remote — everything runs from your Mac.

## How it works

1. Triggers automatically when you SSH into the configured host
2. Discovers listening TCP ports remotely via `ss`
3. Multiplexes `-L` tunnels over your existing SSH connection
4. Re-checks every `CHECK_INTERVAL` seconds until you disconnect

All tunnels share the single SSH connection and die automatically when you disconnect.

## Setup

Edit `autotunnel.conf`, then add this to your `~/.ssh/config`:

```
Host devbox
    ControlMaster auto
    ControlPath ~/.ssh/autotunnel-%r@%h:%p.sock
    ControlPersist yes
    PermitLocalCommand yes
    LocalCommand /path/to/autotunnel.sh loop &
```

Make sure `AUTOTUNNEL_SOCKET` in `autotunnel.conf` matches the `ControlPath` above (or use the defaults — they already match for host `devbox`).

## Usage

```bash
# One-shot check
./autotunnel.sh

# Continuous loop (used by LocalCommand)
./autotunnel.sh loop
```

## Uninstall

Remove the SSH config block above from `~/.ssh/config`.

## Configuration

All settings live in `autotunnel.conf`:

| Variable | Default | Description |
|---|---|---|
| `REMOTE_HOST` | `devbox` | SSH host alias or address |
| `EXCLUDE_PORTS` | `22` | Ports to never tunnel (space-separated) |
| `CHECK_INTERVAL` | `30` | Seconds between checks |
| `LOG_FILE` | `~/.autotunnel.log` | Local log path |
| `AUTOTUNNEL_SOCKET` | `~/.ssh/autotunnel-$REMOTE.sock` | ControlMaster socket path |
