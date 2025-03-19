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
	fzf

mkdir -p ~/lsp/{lua,elixir}

# install lua lsp
if [ -z "$( ls -A ~/lsp/lua )" ]; then
  wget https://github.com/LuaLS/lua-language-server/releases/download/3.13.9/lua-language-server-3.13.9-linux-x64-musl.tar.gz;
  tar -xzvf lua-language-server-3.13.9-linux-x64-musl.tar.gz -C ~/lsp/lua/;
  rm lua-language-server-3.13.9-linux-x64-musl.tar.gz;
fi

# install nvim config from my personal nix config repo
if [ -z "$(ls -A ~/nixconfig)" ]; then
  echo "cloning nixconfig repo";
  git clone "https://dgmcguire:$GITLAB_TOKEN@gitlab.com/dgmcguire/nixconfig.git" ~/nixconfig;
  rm -rf ~/.config/nvim
  cp -rf ~/nixconfig/hosts/yoga-nix/home/nvim ~/.config/nvim;
else
  echo "pulling nixconfig repo";
  cd ~/nixconfig || exit;
  git pull;
  rm -rf ~/.config/nvim
  cp -rf ~/nixconfig/hosts/yoga-nix/home/nvim ~/.config/;
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
