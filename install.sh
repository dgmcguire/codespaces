#!/bin/bash

# install deps
sudo apk add --no-cache \
	gcc \
	unzip \
	make \
	nerd-fonts \
	npm \
	stylua \
	eza \
	fzf \
	xclip \
	tmux

# install lua lsp
if [ -z "$( ls -A ~/lsp/lua )" ]; then
  mkdir -p ~/lsp/lua
  wget https://github.com/LuaLS/lua-language-server/releases/download/3.13.9/lua-language-server-3.13.9-linux-x64-musl.tar.gz;
  tar -xzvf lua-language-server-3.13.9-linux-x64-musl.tar.gz -C ~/lsp/lua/;
  rm lua-language-server-3.13.9-linux-x64-musl.tar.gz;
fi

# install tpm tmux plugin manager
if [ -d "$HOME/.tmux/plugins/tpm" ]; then
  echo "tpm already installed"
else
  echo "installing tpm"
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
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
cp -rf "$dotfiles_dir/scripts" ~/
cp -f "$dotfiles_dir/zshrc.zsh" ~/.zshrc
# make sure this exists to prevent an annoying debug message on ssh
touch ~/.profile
