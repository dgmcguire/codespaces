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
	mosh \
	ripgrep \
	libgcc \
	libstdc++

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

# Decrypt SSH private key from yoga-nix; ssh_agent_init.zsh expects it at ~/.ssh/tuelz-nixos
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
if [ -f "$HOME/.ssh/tuelz-nixos" ]; then
  echo "SSH private key already decrypted at ~/.ssh/tuelz-nixos"
elif [ -f "$HOME/.config/agenix/master.key" ] && [ -f "$HOME/nixconfig/hosts/yoga-nix/home/secrets/ssh-private.age" ]; then
  echo "Decrypting SSH private key from yoga-nix"
  age --decrypt -i "$HOME/.config/agenix/master.key" "$HOME/nixconfig/hosts/yoga-nix/home/secrets/ssh-private.age" > "$HOME/.ssh/tuelz-nixos"
  chmod 600 "$HOME/.ssh/tuelz-nixos"
  cp -f "$HOME/nixconfig/hosts/yoga-nix/home/secrets/ssh-public.key" "$HOME/.ssh/tuelz-nixos.pub"
  chmod 644 "$HOME/.ssh/tuelz-nixos.pub"
else
  echo "Warning: Could not decrypt SSH private key - master key or encrypted key not found"
fi

# Trust github.com host keys so ssh/git push works non-interactively
if ! ssh-keygen -F github.com >/dev/null 2>&1; then
  echo "Adding github.com to ~/.ssh/known_hosts"
  ssh-keyscan -t rsa,ecdsa,ed25519 github.com >> "$HOME/.ssh/known_hosts" 2>/dev/null
fi

# connect to tailnet (delegated to ~/scripts/tailscale_up.zsh, also sourced by .zshrc)
if [ -x "$HOME/scripts/tailscale_up.zsh" ]; then
  "$HOME/scripts/tailscale_up.zsh"
else
  echo "Warning: ~/scripts/tailscale_up.zsh missing — tailscale not started"
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
# Claude Code CLI. Installed via npm (Node 22+) to match the rest of this repo's
# global-install pattern; the package ships a native binary so Node isn't needed
# at runtime. On Alpine/musl this needs the ripgrep/libgcc/libstdc++ apk packages
# above plus USE_BUILTIN_RIPGREP=0 (exported in zshrc.zsh) so it uses system rg.
npm install -g @anthropic-ai/claude-code

# Claude Code auth (non-interactive): authentication comes from an env var that
# Codespaces injects from a Codespaces secret — we never store a token in git.
#   - Subscription (Pro/Max/Team/Enterprise): set CLAUDE_CODE_OAUTH_TOKEN.
#     Generate the 1-year token once locally with `claude setup-token`, then add
#     it as a Codespaces secret named CLAUDE_CODE_OAUTH_TOKEN.
#   - API billing instead: set ANTHROPIC_API_KEY as a Codespaces secret.
#     (ANTHROPIC_API_KEY takes precedence over CLAUDE_CODE_OAUTH_TOKEN if both set.)
# Gotcha: CLAUDE_CODE_OAUTH_TOKEN only authenticates headless `claude -p` runs.
# The interactive TUI ignores it and reads ~/.claude/.credentials.json instead,
# so a fresh codespace would still hit the browser sign-in screen. scripts/
# claude_auth.zsh (sourced from zshrc) seeds that credentials file from the
# token so the interactive CLI also starts logged in with no browser prompt.
if [ -z "$CLAUDE_CODE_OAUTH_TOKEN" ] && [ -z "$ANTHROPIC_API_KEY" ]; then
	echo "Warning: neither CLAUDE_CODE_OAUTH_TOKEN nor ANTHROPIC_API_KEY is set —"
	echo "         Claude Code will require an interactive login. Add one as a"
	echo "         Codespaces secret to auto-authenticate. Run 'claude setup-token'"
	echo "         locally to mint CLAUDE_CODE_OAUTH_TOKEN."
fi

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
