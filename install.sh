#!/bin/bash

# nvim deps
sudo apk add --no-cache \
	gcc \
	unzip \
	make \
	nerd-fonts \
	npm \
	stylua

mkdir -p ~/lsp/{lua,elixir}

# install lua lsp
if [ -z "$( ls -A ~/lsp/lua )" ]; then
  wget https://github.com/LuaLS/lua-language-server/releases/download/3.13.9/lua-language-server-3.13.9-linux-x64-musl.tar.gz;
  tar -xzvf lua-language-server-3.13.9-linux-x64-musl.tar.gz -C ~/lsp/lua/;
  rm lua-language-server-3.13.9-linux-x64-musl.tar.gz;
fi

# append_to_zshrc() {
#   if grep -q "$1" ~/.zshrc; then
#     echo "EXISTS in zshrc: $1";
#   else
#     echo "ADDING to zshrc: $1";
#
#     echo "$1" >> ~/.zshrc
#     # echo "export LUA_LSP='$HOME/lsp/lua/bin/lua-language-server'" >> ~/.zshrc;
#   fi
# }
#
# append_to_zshrc "export LUA_LSP='$HOME/lsp/lua/bin/lua-language-server'"
# append_to_zshrc "export STYLUA_LINTER='/usr/bin/stylua'"
# append_to_zshrc "source ~/.config/

# if grep -q "LUA_LSP" ~/.zshrc; then
#   echo "LUA_LSP already in zshrc";
# else
#   echo "adding LUA_LSP to zshrc";
#   echo  >> ~/.zshrc;
# fi

# if grep -q "STYLUA_LINTER" ~/.zshrc; then
#   echo "STYLUA_LINTER already in zshrc";
# else
#   echo "adding STYLUA_LINTER to zshrc";
#   echo "export STYLUA_LINTER='/usr/bin/stylua'" >> ~/.zshrc;
# fi

# if [ -z "$( ls -A ~/lsp/elixir )" ]; then
#   wget https://github.com/elixir-lsp/elixir-ls/releases/download/v0.27.1/elixir-ls-v0.27.1.zip;
#   unzip elixir-ls-v0.27.1.zip -d ~/lsp/elixir;
#   rm elixir-ls-v0.27.1.zip;
# fi
#
# if grep -q "ELIXIR_LSP" ~/.zshrc; then
#   echo "ELIXIR_LSP alreay in zshrc";
# else
#   echo "adding ELIXIR_LSP to zshrc";
#   echo "export ELIXIR_LSP='$HOME/lsp/elixir/language_server.sh'" >> ~/.zshrc
# fi

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

dotfiles_dir="/workspaces/.codespaces/.persistedshare/dotfiles"
cp -rf "$dotfiles_dir/scripts" ~/
cp -f "$dotfiles_dir/zshrc.zsh" ~/.zshrc
