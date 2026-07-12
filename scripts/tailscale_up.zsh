#!/bin/zsh
# Ensure tailscaled is running and the tailnet is up.
# Idempotent — safe to source on every shell login. No-op when already up.

# `tailscale status` exits 0 even when logged out (the daemon can be Running off a
# cached netmap) and even when parked on a stale interactive AuthURL — so exit code
# alone is not a reliable "already up" signal. Treat logged-out / needs-login and a
# pending AuthURL as "needs bring-up" too. Re-running `tailscale up --authkey` when
# already up is a harmless no-op reconfigure, so a false positive costs nothing; a
# false negative (the old bug) leaves the node stuck offline.
needs_up=false
if ! tailscale status >/dev/null 2>&1; then
  needs_up=true
elif tailscale status 2>/dev/null | grep -qi 'logged out'; then
  needs_up=true
elif tailscale status --json 2>/dev/null | grep -q '"AuthURL": *"http'; then
  needs_up=true
fi

if $needs_up; then
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
