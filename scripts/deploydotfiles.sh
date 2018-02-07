#!/usr/bin/env bash

# Cristian Stroparo's dotfiles - https://github.com/stroparo/dotfiles

echo
echo "==> Dotifying all files in conf/ to the home directory..."

for conf_item in $(ls -d ./conf/*) ; do
  cp -a -v "${conf_item}" "${HOME}/.${conf_item#./conf/}"
done