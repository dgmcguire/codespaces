export LUA_LSP="$HOME/lsp/lua/bin/lua-language-server"
export STYLUA_LINTER='/usr/bin/stylua'
export ZPLUG_HOME='~/.zplug'

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

[[ ! -f "$HOME/scripts/p10k.zsh" ]] || source "$HOME/scripts/p10k.zsh"
[[ ! -f "$HOME/scripts/zsh_functions_and_aliases.zsh" ]] || source "$HOME/scripts/zsh_functions_and_aliases.zsh"
source <(fzf --zsh)
