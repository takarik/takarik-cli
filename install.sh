#!/bin/bash
set -e

crystal --version
if [ $? -ne 0 ]; then
  echo "Crystal lang not installed. Exiting."
  exit 1
fi

shards --version
if [ $? -ne 0 ]; then
  echo "Shards not installed. Exiting."
  exit 1
fi

if [ -d "$HOME/.takarik" ]; then
  echo "Takarik directory already exist. Trying to update takarik"
  cd "$HOME/.takarik" && git pull && TAKARIK_ROOT="$HOME/.takarik" shards build --production && echo "Update has been complete"
  exit 0
fi

echo "Cloning Takarik repository to $HOME/.takarik ..."

git clone https://github.com/takarik/takarik-cli "$HOME/.takarik"
if [ $? -ne 0 ]; then
  echo "Failed to clone Takarik repository. Exiting."
  exit 1
fi

cd "$HOME/.takarik" && TAKARIK_ROOT="$HOME/.takarik" shards build --production
touch "$HOME/.bashrc"
{
  echo '# Takarik CLI'
  echo 'export TAKARIK_ROOT=$HOME/.takarik'
  echo 'export PATH=$PATH:$TAKARIK_ROOT/bin'
} >> "$HOME/.bashrc"

touch "$HOME/.bash_profile"
{
  echo '# Takarik CLI'
  echo 'export TAKARIK_ROOT=$HOME/.takarik'
  echo 'export PATH=$PATH:$TAKARIK_ROOT/bin'
} >> "$HOME/.bash_profile"

if [ -e "$HOME/.zshrc" ]
then
  {
    echo '# Takarik CLI'
    echo 'export TAKARIK_ROOT=$HOME/.takarik'
    echo 'export PATH=$PATH:$TAKARIK_ROOT/bin'
  } >> "$HOME/.zshrc"
fi

echo -e "\nTakarik CLI was installed.\nDont forget to relogin into your shell or run:"
echo -e "\n\tsource $HOME/.bashrc\n\nto refresh your environment variables."