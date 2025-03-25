alias dockerpsf='docker ps --format "table {{.Names}}	{{.Status}}	{{.Ports}}"'
alias ta="tmux new-session -A -s";
alias tl="tmux -u list-sessions";

function csinstall() {
  if [ -f "/workspaces/.codespaces/.persistedshare/dotfiles/install.sh" ]; then
    echo "installing dotfiles"
    (cd /workspaces/.codespaces/.persistedshare/dotfiles && git pull && echo "here")
  else
    ls  /workspaces/.codespaces/.persistedshare/dotfiles
    echo "dotfiles not found"
  fi
}

