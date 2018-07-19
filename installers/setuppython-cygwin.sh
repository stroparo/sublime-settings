#!/usr/bin/env bash

# Cristian Stroparo's dotfiles

# Install Python in a Cygwin environment

# Arguments of filenames ending '-xyz' will have a list of pip packages to be installed
# into the 'xyz' virtualenv.

export PYV2='2.7.13'
export PYV3='3.6.0'

# Dependencies
if ! (uname -a | grep -i -q "cygwin") ; then
  echo "${PROGNAME:+$PROGNAME: }SKIP: Only cygwin supported." 1>&2
  exit
fi
export APTPROG=apt-get; which apt >/dev/null 2>&1 && export APTPROG=apt
[ -n "$ZSH_VERSION" ] && set -o shwordsplit

# #############################################################################
# Functions

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

_make_dirs () {
    # virtualenvs in ~/.ve and projects in ~/workspace
    mkdir ~/.ve
    mkdir ~/workspace
    [ -d ~/.ve ] && [ -d ~/workspace ]
}

_prep_profiles () {
    appendunique 'export WORKON_HOME=~/.ve' \
        "${HOME}/.bashrc" \
        "${HOME}/.zshrc" \
        || return $?
    appendunique 'export PROJECT_HOME=~/workspace' \
        "${HOME}/.bashrc" \
        "${HOME}/.zshrc" \
        || return $?
}

_install_deps () {
    sudo apt-add-repository 'ppa:jonathonf/python-3.6'
    sudo $APTPROG update || return $?
    sudo $APTPROG install -y git-core curl sqlite3 || return $?
}

_install_pyenv () {
    # Pyenv projects:
    # https://github.com/yyuu/pyenv-installer (https://github.com/yyuu/pyenv)
    # https://github.com/yyuu/pyenv-virtualenv
    # https://github.com/yyuu/pyenv-virtualenvwrapper

    # Skip if already installed
    test -x "$HOME/.pyenv/bin/pyenv" && return

    curl -L "$PYENV_INSTALLER" | bash
    appendunique 'export PATH="$HOME/.pyenv/bin:$PATH"' ~/.bashrc ~/.zshrc
    appendunique 'eval "$(pyenv init -)"' ~/.bashrc ~/.zshrc
    # Commenting this LOC out avoids conflicting with virtualenvwrapper...
    appendunique '#eval "$(pyenv virtualenv-init -)"' ~/.bashrc ~/.zshrc

    test -x "$HOME/.pyenv/bin/pyenv"
}

_install_tools () {
    for piplist in "$@" ; do
        pyenv activate ${piplist##*-}
        pip install $(cat "$piplist")
        pyenv deactivate
    done
}

_install_venvwrapper () {

    if [ ! -d ~/.pyenv/plugins/pyenv-virtualenvwrapper ] ; then
        git clone --depth 1 \
            "https://github.com/yyuu/pyenv-virtualenvwrapper.git" \
            ~/.pyenv/plugins/pyenv-virtualenvwrapper \
            || return $?
    fi

    appendunique 'pyenv virtualenvwrapper_lazy' \
        "${HOME}/.bashrc" \
        "${HOME}/.zshrc" \
        || return $?
}

# #############################################################################

_make_dirs || exit $?
_prep_profiles || exit $?
_install_deps || exit $?
_install_pyenv || exit $?

# Load pyenv into this session:
export PATH="$HOME/.pyenv/bin:$PATH"
eval "$("$HOME/.pyenv/bin/pyenv" init -)"

pyenv install "$PYV3"
pyenv install "$PYV2"

if ! (pyenv versions | fgrep -q "$PYV3") ; then
    echo "FATAL: $PYV3 version could not be installed." 1>&2
fi

# Environments:
pyenv virtualenv "$PYV3" jupyter3
pyenv virtualenv "$PYV2" ipython2
pyenv virtualenv "$PYV3" tools3
pyenv virtualenv "$PYV2" tools2

# Install iPython for Python 3 & Jupyter
pyenv activate jupyter3
pip install jupyter # iPython dependency gets automatically installed...
python -m ipykernel install --user
pyenv deactivate

# Install iPython for Python 2
pyenv activate ipython2
pip install ipykernel
python -m ipykernel install --user
pyenv deactivate

# Install argument lists:
_install_tools "$@"

# Set pyenv's PATH priority
pyenv global "$PYV3" "$PYV2" jupyter3 ipython2 tools3 tools2

_install_venvwrapper || exit $?

# Load virtualenvwrapper into this session:
eval "$("$HOME/.pyenv/bin/pyenv" init -)"
pyenv virtualenvwrapper_lazy

# #############################################################################
# iPython virtualenv detection (by Henrique Bastos):
ipython profile create
# curl -L http://hbn.link/hb-ipython-startup-script \
#     > ~/.ipython/profile_default/startup/00-venv-sitepackages.py
cat > ~/.ipython/profile_default/startup/00-venv-sitepackages.py <<'EOF'
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

