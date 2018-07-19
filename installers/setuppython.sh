#!/usr/bin/env bash

# Cristian Stroparo's dotfiles

# Install Python, pyenv etcetera, and Python packages

# Arguments of filenames ending '-xyz' will have a list of pip packages to be installed
# into the 'xyz' virtualenv.

# pyenv faq
# https://github.com/pyenv/pyenv/wiki/Common-build-problems

# #############################################################################
# Globals

export PROGNAME=setuppython.sh
export USAGE="$PROGNAME [-h] [system]"

export PYENV_INSTALLER="https://raw.githubusercontent.com/pyenv/pyenv-installer/master/bin/pyenv-installer"
export PYV2='2.7.14'
export PYV3='3.6.4'

export APTPROG=apt-get; which apt >/dev/null 2>&1 && export APTPROG=apt
export RPMPROG=yum; which dnf >/dev/null 2>&1 && export RPMPROG=dnf

if (echo "$*" | grep -q system) ; then
  export SYSTEM_ONLY=true
fi

# #############################################################################
# Check OS

if ! egrep -i -q 'ubuntu' /etc/*release \
  && ! egrep -i -q 'centos|fedora|oracle|red *hat' /etc/*release
then
  echo "FATAL: Only Debian/RHEL family distros are supported." 1>&2
  exit 1
fi

# #############################################################################
# Shell

[ -n "$ZSH_VERSION" ] && set -o shwordsplit

# #############################################################################
# Helpers

appendunique () {
  # Syntax: string file1 [file2 ...]
  [ -z "$1" ] && return 0
  typeset fail=0
  typeset text="${1}" ; shift
  for f in "$@" ; do
    [ ! -e "$f" ] && fail=1 && echo "ERROR '${f}' does not exist" 1>&2 && continue
    if ! fgrep -q "${text}" "${f}" ; then
      ! echo "${text}" >> "${f}" && fail=1 && echo "ERROR appending '${f}'" 1>&2
    fi
  done
  return ${fail}
}

# #############################################################################
# Options

OPTIND=1
while getopts ':h' option ; do
  case "${option}" in
    h) echo "$USAGE"; exit;;
  esac
done
shift "$((OPTIND-1))"

# #############################################################################
echo ${BASH_VERSION:+-e} "\n\n==> Python system dependencies"

if egrep -i -q 'debian|ubuntu' /etc/*release ; then

  sudo $APTPROG update || exit $?

  # Distribution Python
  sudo $APTPROG install -y python python-dev python-pip
  sudo $APTPROG install -y python3 python3-dev python3-pip

  # pyenv dependencies
  sudo $APTPROG install -y make build-essential libssl-dev zlib1g-dev libbz2-dev \
  libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev \
  xz-utils tk-dev

  # tools
  which git >/dev/null 2>&1 || sudo $APTPROG install -y git-core || exit $?
  which sqlite3 >/dev/null 2>&1 || sudo $APTPROG install -y sqlite3 || exit $?

elif egrep -i -q 'centos|fedora|oracle|red *hat' /etc/*release ; then

  # Python 2
  sudo $RPMPROG install -q -y --enablerepo=epel python python-devel
  sudo $RPMPROG install -q -y --enablerepo=epel python-pip \
    || sudo $RPMPROG install -q -y --enablerepo=epel python2-pip

  # Python 3
  sudo $RPMPROG install -q -y --enablerepo=epel python3 python3-devel \
    || sudo $RPMPROG install -q -y --enablerepo=epel python34 python34-devel
  sudo $RPMPROG install -q -y --enablerepo=epel python3-pip \
    || sudo $RPMPROG install -q -y --enablerepo=epel python34-pip

  # pyenv dependencies
  sudo $RPMPROG install -q -y --enablerepo=epel zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel openssl-devel xz xz-devel

  # tools
  which git >/dev/null 2>&1 || sudo $RPMPROG install -q -y git || exit $?
  which sqlite >/dev/null 2>&1 || sudo $RPMPROG install -q -y sqlite || exit $?
fi

(
echo ${BASH_VERSION:+-e} "\n\n==> pip upgrade for system's pip, so no pyenv in PATH...\n"
export PATH="$(echo "$PATH" | tr : \\n | grep -v pyenv | tr \\n :)"
sudo -H pip install --upgrade pip
sudo -H pip3 install --upgrade pip
)

# #############################################################################
# pip.conf

mkdir -p "$HOME/.config/pip" 2>/dev/null
cp -v "$HOME/.config/pip/pip.conf" "$HOME/.config/pip/pip.conf.$(date '+%Y%m%d-%OH%OM%OS')"
cat > "$HOME/.config/pip/pip.conf" <<EOF
[list]
format=columns
EOF

# #############################################################################
# Checkpoint

${SYSTEM_ONLY:-false} && exit

# #############################################################################
echo ${BASH_VERSION:+-e} "\n\n==> Preparing venv and workspace directories..."

# Directory for projects
mkdir "$HOME"/workspace
ls -ld "$HOME"/workspace || exit $?

# Directory for virtualenvs
mkdir "$HOME"/.ve
ls -ld "$HOME"/.ve || exit $?

# #############################################################################
echo ${BASH_VERSION:+-e} "\n\n==> Preparing shell profiles for Python..."

echo ${BASH_VERSION:+-e} "\n\n==> WORKON_HOME..."
appendunique 'export WORKON_HOME="$HOME"/.ve' \
  "${HOME}/.bashrc" \
  "${HOME}/.zshrc" \
  || exit $?

echo ${BASH_VERSION:+-e} "\n\n==> PROJECT_HOME..."
appendunique 'export PROJECT_HOME="$HOME"/workspace' \
  "${HOME}/.bashrc" \
  "${HOME}/.zshrc" \
  || exit $?

# #############################################################################
echo ${BASH_VERSION:+-e} "\n\n==> pyenv setup and load into this session..."

# Pyenv projects:
# https://github.com/yyuu/pyenv-installer (https://github.com/yyuu/pyenv)
# https://github.com/yyuu/pyenv-virtualenv
# https://github.com/yyuu/pyenv-virtualenvwrapper

# Write shell RC files before everything, as pyenv could be in path,
# but for some reason the RC files been meddled with or reset etc.
if ! grep -q 'pyenv init' "$HOME/.bashrc" \
  || ! grep -q 'pyenv init' "$HOME/.zshrc"
then
  cat <<'EOF' | tee -a "$HOME"/.{ba,z}shrc
export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init -)"
# Commenting this LOC out avoids conflicting with virtualenvwrapper...
# eval "$(pyenv virtualenv-init -)"
EOF
fi

# Speed up disabling prompt as it is going to be discontinued anyway:
appendunique 'export PYENV_VIRTUALENV_DISABLE_PROMPT=1' \
  "${HOME}/.bashrc" \
  "${HOME}/.zshrc"

# Install
if [ ! -d "$HOME/.pyenv" ] ; then
  bash -c "$(curl -L "$PYENV_INSTALLER")"
fi

# Load
if which pyenv >/dev/null 2>&1 ; then
  eval "$(pyenv init -)"
else
  if [ -n "$BASH_VERSION" ] && grep -q "pyenv" "$HOME/.bashrc" ; then
    . "$HOME/.bashrc"
  elif [ -n "$ZSH_VERSION" ] && grep -q "pyenv" "$HOME/.zshrc" ; then
    . "$HOME/.zshrc"
  fi
  if ! which pyenv >/dev/null 2>&1 ; then
    echo "FATAL: There was some error installing pyenv." 1>&2
    exit 1
  fi
fi

# #############################################################################
echo ${BASH_VERSION:+-e} "\n\n==> pyenv virtualenv disable \
(conflicts with virtualenvwrapper)"

sed -i -e 's/^[^#].*pyenv virtualenv-init.*$/# &/' \
  "$HOME/.bashrc" "$HOME/.zshrc"

# #############################################################################
echo ${BASH_VERSION:+-e} "\n\n==> pyenv install $PYV3 and $PYV2 ..."

pyenv install "$PYV3"
pyenv install "$PYV2"

if ! (pyenv versions | fgrep -q "$PYV3") ; then
  echo "FATAL: $PYV3 version could not be installed." 1>&2
fi

echo ${BASH_VERSION:+-e} "\n\n==> pip upgrade for pyenv's pip...\n"
pip2 install --upgrade pip
pip3 install --upgrade pip

# #############################################################################
echo ${BASH_VERSION:+-e} "\n\n==> virtualenv's..."

pyenv virtualenv "$PYV3" jupyter3
pyenv virtualenv "$PYV2" ipython2
pyenv virtualenv "$PYV3" tools3
pyenv virtualenv "$PYV2" tools2

# #############################################################################
echo ${BASH_VERSION:+-e} "\n\n==> IPython for Python 3 & Jupyter"

pyenv activate jupyter3
pip install jupyter # iPython dependency gets automatically installed...
python -m ipykernel install --user
pyenv deactivate

# #############################################################################
echo ${BASH_VERSION:+-e} "\n\n==> IPython for Python 2"

pyenv activate ipython2
pip install ipykernel
python -m ipykernel install --user
pyenv deactivate

# #############################################################################
echo ${BASH_VERSION:+-e} "\n\n==> pyenv PATH priority"

pyenv global "$PYV3" "$PYV2" jupyter3 ipython2 tools3 tools2

# #############################################################################
echo ${BASH_VERSION:+-e} "\n\n==> Python 3 base utilities"

pip install pipenv

# #############################################################################
echo ${BASH_VERSION:+-e} "\n\n==> virtualenvwrapper installation"

if [ ! -d "$HOME"/.pyenv/plugins/pyenv-virtualenvwrapper ] ; then
  git clone --depth 1 \
    "https://github.com/yyuu/pyenv-virtualenvwrapper.git" \
    "$HOME"/.pyenv/plugins/pyenv-virtualenvwrapper \
    || exit $?
fi

appendunique 'pyenv virtualenvwrapper_lazy' \
  "${HOME}/.bashrc" \
  "${HOME}/.zshrc" \
  || exit $?

# #############################################################################
echo ${BASH_VERSION:+-e} "\n\n==> virtualenvwrapper load into this session"

eval "$(pyenv init -)"
pyenv virtualenvwrapper_lazy

# #############################################################################
echo ${BASH_VERSION:+-e} "\n\n==> IPython virtualenv detection (by Henrique Bastos)"

ipython profile create

mkdir -p "$HOME"/.ipython/profile_default/startup
# curl -L http://hbn.link/hb-ipython-startup-script \
#     > "$HOME"/.ipython/profile_default/startup/00-venv-sitepackages.py
cat > "$HOME"/.ipython/profile_default/startup/00-venv-sitepackages.py <<'EOF'
"""IPython startup script to detect and inject VIRTUAL_ENV's site-packages dirs.

IPython can detect virtualenv's path and injects it's site-packages dirs into sys.path.
But it can go wrong if IPython's python version differs from VIRTUAL_ENV's.

This module fixes it looking for the actual directories. We use only old stdlib
resources so it can work with as many Python versions as possible.

References:
http://stackoverflow.com/a/30650831/443564
http://stackoverflow.com/questions/122327/how-do-i-find-the-location-of-my-python-site-packages-directory
https://github.com/ipython/ipython/blob/master/IPython/core/interactiveshell.py#L676

Author: Henrique Bastos <henrique@bastos.net>
License: BSD
"""
import os
import sys
from warnings import warn


virtualenv = os.environ.get('VIRTUAL_ENV')

if virtualenv:

  version = os.listdir(os.path.join(virtualenv, 'lib'))[0]
  site_packages = os.path.join(virtualenv, 'lib', version, 'site-packages')
  lib_dynload = os.path.join(virtualenv, 'lib', version, 'lib-dynload')

  if not (os.path.exists(site_packages) and os.path.exists(lib_dynload)):
    msg = 'Virtualenv site-packages discovery went wrong for %r' % repr([site_packages, lib_dynload])
    warn(msg)

  sys.path.insert(0, site_packages)
  sys.path.insert(1, lib_dynload)
EOF

# #############################################################################
echo ${BASH_VERSION:+-e} "\n\n==> Etcetera"

if which "pythonselects.sh" >/dev/null 2>&1; then
  "pythonselects.sh"
fi
