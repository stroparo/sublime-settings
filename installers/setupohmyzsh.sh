#!/usr/bin/env bash

PROGNAME=setupohmyzsh.sh
: ${ZSH_CUSTOM:=$HOME/.oh-my-zsh/custom}

if ! type zsh >/dev/null 2>&1 ; then echo "$PROGNAME: SKIP: zsh is not installed" 1>&2 ; exit ; fi

echo "$PROGNAME: INFO: Oh-My-Zsh setup started"
echo "$PROGNAME: INFO: \$0='$0'; \$PWD='$PWD'"

# #############################################################################
# Globals

OMZ_URL="https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh"

# #############################################################################
# Main

echo
echo ">>> IMPORTANT <<<"
echo "... After installing oh-my-zsh, it will change"
echo "... the default shell to zsh and log into it."
echo "... IF THAT IS THE CASE (like the prompt stopped"
echo "... and nothing else happened), then exit or CTRL+D"
echo "... for this sequence to continue."
echo

if [ ! -d "${HOME}/.oh-my-zsh" ] ; then
  sh -c "$(curl ${DLOPTEXTRA} -LSfs "${OMZ_URL}")"
fi

# Restore pre-oh-my-zsh backup:
if [ -s "${HOME}/.zshrc.pre-oh-my-zsh" ] ; then
  echo ${BASH_VERSION:+-e} "\n# .zshrc.pre-oh-my-zsh restored\n" >> "${HOME}/.zshrc"
  cat >> "${HOME}/.zshrc" < "${HOME}/.zshrc.pre-oh-my-zsh" \
    && rm -f "${HOME}/.zshrc.pre-oh-my-zsh"
fi

# #############################################################################
# Plugins

# {url} {path}
_install_omz_plugin () {
  typeset plugin_url="${1}"
  typeset plugin_path="${2}"
  typeset plugin_name=$(basename "${plugin_url%.git}")

  echo ; echo "Installing ohmyzsh plugin (or theme) '${plugin_name}' ..." ; echo

  if [ ! -d "$plugin_path" ] ; then
    echo git clone "$OMZ_SYN_URL" "$plugin_path" ...
    git clone --depth 1 "$OMZ_SYN_URL" "$plugin_path"
  fi
  ls -d -l "$plugin_path"

  # Activate the plugin (idempotent):
  if (echo "${plugin_path}" | grep '/plugins') ; then
    if ! grep -q "plugins=.*${plugin_name}" ~/.zshrc ; then
      sed -i -e 's/\(plugins=(.*\))/\1 '"${plugin_name}"')/' ~/.zshrc
      grep "${plugin_name}" ~/.zshrc /dev/null
    else
      echo "SKIP: ${plugin_name} already activated." 1>&2
    fi
  fi
}


_install_omz_plugin \
  "https://github.com/zsh-users/zsh-syntax-highlighting.git" \
  "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"


_install_omz_plugin \
  "https://github.com/denysdovhan/spaceship-prompt.git" \
  "${ZSH_CUSTOM}/themes/spaceship-prompt"
if [ ! -e "$ZSH_CUSTOM/themes/spaceship.zsh-theme" ] ; then
  ln -s "$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" "$ZSH_CUSTOM/themes/spaceship.zsh-theme"
fi


# #############################################################################
# Themes

_conf_spaceship () {
  if grep SPACESHIP_PROMPT_ORDER ~/.zshrc ; then
    return
  fi
  cat >> ~/.zshrc <<'EOF'
SPACESHIP_PROMPT_ORDER=(
  user          # Username section
  dir           # Current directory section
  host          # Hostname section
  git           # Git section (git_branch + git_status)
  hg            # Mercurial section (hg_branch  + hg_status)
  exec_time     # Execution time
  line_sep      # Line break
  vi_mode       # Vi-mode indicator
  jobs          # Background jobs indicator
  exit_code     # Exit code section
  char          # Prompt character
)
SPACESHIP_USER_SHOW=always
SPACESHIP_PROMPT_ADD_NEWLINE=false
SPACESHIP_CHAR_SYMBOL="❯"
SPACESHIP_CHAR_SUFFIX=" "
EOF
}


_select_theme () {
  echo ; echo "Selecting ZSH_THEME=\"${1}\"" ; echo
  if ! grep 'ZSH_THEME=' "${HOME}/.zshrc" ; then
    echo 'ZSH_THEME=' >> "${HOME}/.zshrc"
  fi
  sed -i -e "s/^ZSH_THEME=.*$/ZSH_THEME=\"${1}\"/" "${HOME}/.zshrc"
}


# _select_theme robbyrussell
_select_theme spaceship ; _conf_spaceship

# #############################################################################
# Final sequence

echo "$PROGNAME: COMPLETE: Oh-My-Zsh setup"
echo
echo
exit
