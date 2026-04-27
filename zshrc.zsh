export LUA_LSP="$HOME/lsp/lua/bin/lua-language-server"
export STYLUA_LINTER='/usr/bin/stylua'
export ZPLUG_HOME="$HOME/.zplug"
export NPM_GLOBAL="$HOME/.npm-global"
export PATH="$HOME/.local/bin:$NPM_GLOBAL/bin:$PATH"

[[ ! -f "$HOME/.zplug/init.zsh" ]] || source "$HOME/.zplug/init.zsh"

zplug "romkatv/powerlevel10k", as:theme, depth:1
zplug "zsh-users/zsh-autosuggestions", defer:2
zplug "zsh-users/zsh-history-substring-search", defer:3
zplug "dgmcguire/prezto-git-aliases"
zplug "z-shell/zsh-eza"
zplug "docker/compose", use:contrib/completion/zsh

if ! zplug check; then
  zplug install
fi
zplug load

# Initialize SSH agent
[[ ! -f "$HOME/scripts/ssh_agent_init.zsh" ]] || source "$HOME/scripts/ssh_agent_init.zsh"

# Ensure tailnet is up (no-op if already connected)
[[ ! -f "$HOME/scripts/tailscale_up.zsh" ]] || source "$HOME/scripts/tailscale_up.zsh"

[[ ! -f "$HOME/scripts/p10k.zsh" ]] || source "$HOME/scripts/p10k.zsh"
[[ ! -f "$HOME/scripts/zsh_functions_and_aliases.zsh" ]] || source "$HOME/scripts/zsh_functions_and_aliases.zsh"
source <(fzf --zsh)


HISTSIZE="10000"
SAVEHIST="10000"

HISTFILE="$HOME/.zsh_history"
mkdir -p "$(dirname "$HISTFILE")"

setopt HIST_FCNTL_LOCK
unsetopt APPEND_HISTORY
setopt HIST_IGNORE_DUPS
unsetopt HIST_IGNORE_ALL_DUPS
unsetopt HIST_SAVE_NO_DUPS
unsetopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_SPACE
unsetopt HIST_EXPIRE_DUPS_FIRST
setopt SHARE_HISTORY
unsetopt EXTENDED_HISTORY

# --- Jira CLI (@pchuri/jira-cli) ---
# Uses JIRA_API_TOKEN (set in Codespaces secrets). JIRA_HOST derived from JIRA_SERVER if unset.
if [[ -n "$JIRA_SERVER" && -z "$JIRA_HOST" ]]; then
  export JIRA_HOST="${JIRA_SERVER#https://}"
  export JIRA_HOST="${JIRA_HOST#http://}"
  export JIRA_HOST="${JIRA_HOST%%/*}"
fi

# --- Confluence CLI (confluence-cli) ---
# Same Atlassian token as Jira. Set CONFLUENCE_EMAIL in Codespaces secrets (your Atlassian email).
export CONFLUENCE_DOMAIN="${CONFLUENCE_DOMAIN:-revzilla.atlassian.net}"
export CONFLUENCE_API_PATH="${CONFLUENCE_API_PATH:-/wiki/rest/api}"
export CONFLUENCE_AUTH_TYPE="${CONFLUENCE_AUTH_TYPE:-basic}"
[[ -n "$JIRA_API_TOKEN" ]] && export CONFLUENCE_API_TOKEN="${CONFLUENCE_API_TOKEN:-$JIRA_API_TOKEN}"
