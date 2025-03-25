alias dockerpsf='docker ps --format "table {{.Names}}	{{.Status}}	{{.Ports}}"'
alias ta="tmux new-session -A -s";
alias tl="tmux -u list-sessions";

function csinstall() {
  if [ -f  "/workspaces/.codespaces/.persistedshare/dotfiles/scripts/install.sh" ]; then
    echo "installing dotfiles"
    /workspaces/.codespaces/.persistedshare/dotfiles/scripts/install.sh
  else
    echo "dotfiles not found"
  fi
}

