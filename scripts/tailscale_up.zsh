#!/bin/zsh
# Ensure tailscaled is running and the tailnet is up.
# Idempotent — safe to source on every shell login. No-op when already up.

if ! tailscale status >/dev/null 2>&1; then
  if [ -z "$TAILSCALE_AUTHKEY" ]; then
    echo "TAILSCALE_AUTHKEY not set — skipping tailscale setup" >&2
  else
    sudo mkdir -p /var/lib/tailscale
    if ! pgrep -x tailscaled > /dev/null; then
      # kernel/TUN mode so UDP (mosh 60000-61000) is reachable on the tailnet IP
      sudo tailscaled --state=/var/lib/tailscale/tailscaled.state > /tmp/tailscaled.log 2>&1 &
      sleep 2
    fi
    sudo tailscale up \
      --authkey="${TAILSCALE_AUTHKEY}?ephemeral=true&preauthorized=true" \
      --advertise-tags=tag:codespace \
      --hostname="codespace-${CODESPACE_NAME:-$(hostname)}" \
      --ssh \
      --accept-routes
  fi
fi
