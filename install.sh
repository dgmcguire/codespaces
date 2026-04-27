#!/bin/bash
# install deps
sudo apk update
sudo apk add --no-cache \
	gcc \
	unzip \
	make \
	nerd-fonts \
	stylua \
	eza \
	fzf \
	xclip \
	tmux \
	postgresql-client \
	gzip \
	tree-sitter-cli \
	npm \
	mosh

sudo apk add --upgrade --repository=https://dl-cdn.alpinelinux.org/alpine/edge/main libuv
sudo apk add --upgrade --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community neovim
sudo apk add --repository=https://dl-cdn.alpinelinux.org/alpine/edge/testing openfortivpn
sudo apk add age
sudo apk add tailscale

# install lua lsp
if [ -z "$( ls -A ~/lsp/lua )" ]; then
  mkdir -p ~/lsp/lua
  wget https://github.com/LuaLS/lua-language-server/releases/download/3.13.9/lua-language-server-3.13.9-linux-x64-musl.tar.gz;
  tar -xzvf lua-language-server-3.13.9-linux-x64-musl.tar.gz -C ~/lsp/lua/;
  rm lua-language-server-3.13.9-linux-x64-musl.tar.gz;
fi

# install cloud-sql-proxy
   if command -v cloud-sql-proxy &> /dev/null; then
       echo "cloud-sql-proxy is already installed at: $(which cloud-sql-proxy)"
       cloud-sql-proxy --version
   else
       echo "cloud-sql-proxy not found, installing..."
       wget https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.20.0/cloud-sql-proxy.linux.amd64 -O /tmp/cloud-sql-proxy
       chmod +x /tmp/cloud-sql-proxy
       sudo mv /tmp/cloud-sql-proxy /usr/local/bin/cloud-sql-proxy
       echo "Installation complete!"
       cloud-sql-proxy --version
   fi

# install tpm tmux plugin manager
if [ -f "$HOME/.tmux/plugins/tpm/scripts/install_plugins.sh" ]; then
  echo "tpm already installed"
else
  echo "installing tpm"
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  # start a server but don't attach to it
  tmux start-server
  # create a new session but don't attach to it either
  tmux new-session -d
  # install the plugins
  "$HOME/.tmux/plugins/tpm/scripts/install_plugins.sh"
  # killing the server is not really required
  tmux kill-server
fi

# install nvim and tmux config from my personal nix config repo
if [ -z "$(ls -A ~/nixconfig)" ]; then
  echo "cloning nixconfig repo";
  git clone "https://dgmcguire:$GITLAB_TOKEN@gitlab.com/dgmcguire/nixconfig.git" ~/nixconfig;
  rm -rf ~/.config/nvim
  rm ~/.tmux.conf
  cp -rf ~/nixconfig/hosts/yoga-nix/home/nvim ~/.config/nvim;
  cp -f ~/nixconfig/hosts/yoga-nix/home/tmux.conf ~/.tmux.conf;
else
  echo "pulling nixconfig repo";
  cd ~/nixconfig || exit;
  git pull;
  rm -rf ~/.config/nvim
  rm ~/.tmux.conf
  cp -rf ~/nixconfig/hosts/yoga-nix/home/nvim ~/.config/;
  cp -f ~/nixconfig/hosts/yoga-nix/home/tmux.conf ~/.tmux.conf;
fi

# install zplug
if [ ! -d "$HOME/.zplug" ]; then
  echo "installing zplug"
  curl -sL --proto-redir -all,https https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | zsh
fi

# move some config and scripts into place
dotfiles_dir="/workspaces/.codespaces/.persistedshare/dotfiles"
cd $dotfiles_dir || exit;
git pull;
cp -rf "$dotfiles_dir/scripts" ~/
cp -f "$dotfiles_dir/zshrc.zsh" ~/.zshrc
# make sure this exists to prevent an annoying debug message on ssh
touch ~/.profile

# setup openfortivpn config
mkdir -p ~/.config
mkdir -p ~/.config/agenix

# Check if we need to decrypt the master key
if [ ! -f "$HOME/.config/agenix/master.key" ]; then
  if [ -f "$HOME/nixconfig/hosts/yoga-windows/home/secrets/master.key.age" ]; then
    echo "Decrypting master key (password required)..."
    age --decrypt --output "$HOME/.config/agenix/master.key" "$HOME/nixconfig/hosts/yoga-windows/home/secrets/master.key.age"
    if [ $? -ne 0 ]; then
      echo "Error: Failed to decrypt master key"
      exit 1
    fi
    chmod 600 "$HOME/.config/agenix/master.key"
  else
    echo "Warning: master.key.age not found in nixconfig repo"
  fi
else
  echo "Master key already decrypted at ~/.config/agenix/master.key"
fi

# Decrypt openfortivpn config using the master key
if [ -f "$HOME/.config/agenix/master.key" ] && [ -f "$HOME/nixconfig/hosts/yoga-windows/home/secrets/openfortivpn.age" ]; then
  echo "Setting up openfortivpn config from yoga-windows (encrypted)"
  age --decrypt -i "$HOME/.config/agenix/master.key" "$HOME/nixconfig/hosts/yoga-windows/home/secrets/openfortivpn.age" > ~/.config/openfortivpn.config
  chmod 600 "$HOME/.config/openfortivpn.config"
else
  echo "Warning: Could not decrypt openfortivpn config - master key or config file not found"
fi

# connect to tailnet via OAuth client secret (ephemeral, pre-approved)
if [ -n "$TAILSCALE_AUTHKEY" ]; then
  sudo mkdir -p /var/lib/tailscale
  if ! pgrep -x tailscaled > /dev/null; then
    # kernel/TUN mode so UDP (mosh 60000-61000) is reachable on the tailnet IP
    sudo tailscaled \
      --state=/var/lib/tailscale/tailscaled.state > /tmp/tailscaled.log 2>&1 &
    # give the daemon a moment to come up before `tailscale up`
    sleep 2
  fi
  sudo tailscale up \
    --authkey="${TAILSCALE_AUTHKEY}?ephemeral=true&preauthorized=true" \
    --advertise-tags=tag:codespace \
    --hostname="codespace-${CODESPACE_NAME:-$(hostname)}" \
    --ssh \
    --accept-routes
else
  echo "TAILSCALE_AUTHKEY not set — skipping tailscale setup"
fi

# finally source zshrc for convenience when I'm running this manually
if [ ! -f "$HOME/.zshrc" ]; then
  #shellcheck disable=1091
  #disable file not found, which is fine since I expect this on codespaces, not locally
  source "$HOME/.zshrc"
fi

# config npm and install auggie after zsh source
export NPM_GLOBAL="$HOME/.npm-global"
export PATH="$NPM_GLOBAL/bin:$PATH"
mkdir -p "$HOME/.npm-global"
npm config set prefix "$NPM_GLOBAL"
npm install -g @augmentcode/auggie
npm install -g @pchuri/jira-cli
npm install -g confluence-cli

# Docker MCP server (PyPI: mcp-server-docker, https://github.com/ckreiling/mcp-server-docker)
# Cursor: add MCP server with command "mcp-server-docker" (needs Docker socket / DOCKER_HOST).
export PATH="$HOME/.local/bin:$PATH"
if ! command -v uv &> /dev/null; then
	echo "installing uv (required for mcp-server-docker)..."
	curl -LsSf https://astral.sh/uv/install.sh | sh
	export PATH="$HOME/.local/bin:$PATH"
fi
if command -v mcp-server-docker &> /dev/null; then
	echo "mcp-server-docker already installed at: $(command -v mcp-server-docker)"
else
	echo "installing mcp-server-docker..."
	uv tool install mcp-server-docker
fi
