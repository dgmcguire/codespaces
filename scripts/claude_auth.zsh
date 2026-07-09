#!/usr/bin/env zsh
# Seed Claude Code's interactive-TUI auth from CLAUDE_CODE_OAUTH_TOKEN.
#
# Why this exists: the interactive `claude` TUI does NOT read
# CLAUDE_CODE_OAUTH_TOKEN — that env var only authenticates headless runs
# (`claude -p ...`). The TUI authenticates from ~/.claude/.credentials.json,
# which is normally written by an interactive browser `/login`. In a headless
# Codespace there's no browser, so a fresh codespace drops you at the OAuth
# sign-in screen. This writes that credentials file straight from the token
# (injected as a Codespaces secret via /etc/zsh/zprofile before zshrc runs),
# so the TUI starts already logged in.
#
# Idempotent + safe: only writes when the credential file is missing, so it
# never clobbers a real browser `/login` credential. No-op without the token.

emulate -L zsh
setopt no_unset 2>/dev/null || true

[[ -n "$CLAUDE_CODE_OAUTH_TOKEN" ]] || return 0
command -v jq >/dev/null 2>&1 || return 0

local cfg="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
local cred="$cfg/.credentials.json"
local dotjson
if [[ -n "${CLAUDE_CONFIG_DIR:-}" ]]; then
  dotjson="$CLAUDE_CONFIG_DIR/.claude.json"
else
  dotjson="$HOME/.claude.json"
fi

mkdir -p "$cfg"

if [[ ! -f "$cred" ]]; then
  # expiresAt is set far in the future on purpose: with no refresh token we do
  # NOT want the client to proactively trigger a browser re-login. When the
  # token itself expires (~1 year), API calls start returning 401 — at that
  # point re-mint it (`claude setup-token`), update the Codespaces secret, and
  # delete this file so it gets re-seeded.
  if jq -n --arg tok "$CLAUDE_CODE_OAUTH_TOKEN" \
    '{claudeAiOauth:{
        accessToken:$tok,
        refreshToken:"",
        expiresAt:9999999999999,
        scopes:["user:inference","user:profile","user:sessions:claude_code","user:mcp_servers","user:file_upload"],
        subscriptionType:"team"
      }}' > "$cred.tmp" 2>/dev/null; then
    chmod 600 "$cred.tmp"
    mv "$cred.tmp" "$cred"
  else
    rm -f "$cred.tmp"
    return 0
  fi
fi

# Skip first-run onboarding (theme + login prompts) without clobbering an
# existing config: merge the flag if the file exists, else create a minimal one.
if [[ -f "$dotjson" ]]; then
  local tmp
  tmp="$(mktemp)"
  if jq '.hasCompletedOnboarding = true' "$dotjson" > "$tmp" 2>/dev/null; then
    mv "$tmp" "$dotjson"
  else
    rm -f "$tmp"
  fi
else
  print -r -- '{"hasCompletedOnboarding":true,"theme":"dark"}' > "$dotjson"
  chmod 600 "$dotjson"
fi
