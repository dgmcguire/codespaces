#!/bin/bash

# nvim deps
sudo apk add --no-cache \
	gcc \
	unzip \
	make \
	nerd-fonts 

mkdir -p ~/lsp/{lua,elixir}

if [ -z "$( ls -A ~/lsp/lua )" ]; then
  wget https://github.com/LuaLS/lua-language-server/releases/download/3.13.9/lua-language-server-3.13.9-linux-x64-musl.tar.gz
  tar -xzvf lua-language-server-3.13.9-linux-x64-musl.tar.gz -C ~/lsp/lua/
  rm lua-language-server-3.13.9-linux-x64-musl.tar.gz 
fi
if [ -z "$( ls -A ~/lsp/elixir )" ]; then
  wget https://github.com/elixir-lsp/elixir-ls/releases/download/v0.27.1/elixir-ls-v0.27.1.zip
  unzip elixir-ls-v0.27.1.zip -d ~/lsp/elixir
  rm elixir-ls-v0.27.1.zip
fi

# git clone "https://dgmcguire:$GITLAB_TOKEN@gitlab.com/dgmcguire/nixconfig.git"
