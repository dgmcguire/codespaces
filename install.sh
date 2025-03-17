#!/bin/bash

# nvim deps
sudo apk add --no-cache \
	gcc \
	unzip \
	make \
	nerd-fonts 

mkdir -p ~/lsp/{lua,elixir}

if [ -z "$( ls -A ~/lsp/lua )" ]; then
  wget https://github.com/LuaLS/lua-language-server/releases/download/3.13.9/lua-language-server-3.13.9-linux-x64-musl.tar.gz;
  tar -xzvf lua-language-server-3.13.9-linux-x64-musl.tar.gz -C ~/lsp/lua/;
  rm lua-language-server-3.13.9-linux-x64-musl.tar.gz;
fi

if grep -q "LUA_LSP" ~/.zshrc; then
  echo "LUA_LSP already in zshrc";
else
  echo "adding LUA_LSP to zshrc";
  echo "export LUA_LSP='$HOME/lsp/lua/bin/lua-language-server'" >> ~/.zshrc;
fi

if [ -z "$( ls -A ~/lsp/elixir )" ]; then
  wget https://github.com/elixir-lsp/elixir-ls/releases/download/v0.27.1/elixir-ls-v0.27.1.zip;
  unzip elixir-ls-v0.27.1.zip -d ~/lsp/elixir;
  rm elixir-ls-v0.27.1.zip;
fi

if grep -q "ELIXIR_LSP" ~/.zshrc; then
  echo "ELIXIR_LSP alreay in zshrc";
else
  echo "adding ELIXIR_LSP to zshrc";
  echo "export ELIXIR_LSP='$HOME/lsp/elixir/language_server.sh'" >> ~/.zshrc
fi

if [ -z "$(ls -A ~/nixconfig)" ]; then
  echo "cloning nixconfig repo";
  git clone "https://dgmcguire:$GITLAB_TOKEN@gitlab.com/dgmcguire/nixconfig.git" ~/nixconfig;
  cp -rf ~/nixconfig/hosts/yoga-nix/home/nvim ~/.config/nvim;
else
  echo "pulling nixconfig repo";
  cd ~/nixconfig || exit;
  git pull;
  cp -rf ~/nixconfig/hosts/yoga-nix/home/nvim ~/.config/nvim;
fi
