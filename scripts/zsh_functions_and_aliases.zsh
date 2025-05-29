alias dockerpsf='docker ps --format "table {{.Names}}	{{.Status}}	{{.Ports}}"'
alias ta="tmux new-session -A -s";
alias tl="tmux -u list-sessions";

function csinstall() {
  if [ -f "/workspaces/.codespaces/.persistedshare/dotfiles/install.sh" ]; then
    echo "installing dotfiles"
    (cd /workspaces/.codespaces/.persistedshare/dotfiles && git pull && bash ./install.sh)
  else
    ls  /workspaces/.codespaces/.persistedshare/dotfiles
    echo "dotfiles not found"
  fi
}

keepalive() {
  while true; do
      # Get current hour in 24-hour format
      current_hour=$(TZ=America/Chicago date +%H)
      
      if [ "$current_hour" -ge 5 ] && [ "$current_hour" -lt 17 ]; then
	echo "Keeping codespace alive at $(TZ=America/Chicago date)" >> ~/keep_alive.log
      fi
      
      sleep 900
  done
}

keepalivelate() {
  while true; do
      # Get current hour in 24-hour format
      current_hour=$(TZ=America/Chicago date +%H)
      
      if [ "$current_hour" -ge 5 ] && [ "$current_hour" -lt 24 ]; then
	echo "Keeping codespace alive at $(TZ=America/Chicago date)" >> ~/keep_alive.log
      fi
      
      sleep 900
  done
}
