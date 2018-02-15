#!/usr/bin/env bash

# Made for Ubuntu 16.04
# Install Ruby, Rails, Bundler and common gems

# Argument is a gemfile to use to install global packages

# Dependencies
(! grep -q Ubuntu /etc/os-release || ! grep -q '16[.]04' /etc/os-release) && exit
. "${DS_HOME:-$HOME}"/ds.sh "${DS_HOME:-$HOME}" || exit 101
export APTPROG=apt-get; which apt >/dev/null 2>&1 && export APTPROG=apt

# #############################################################################
# Functions

installDependencies () {

    typeset deps="git-core curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev python-software-properties libffi-dev nodejs"

    sudo $APTPROG update || return $?
    sudo $APTPROG install -y $deps || return $?
}

installRbenv () {

    type rbenvprofile="export PATH=\"\$HOME/.rbenv/bin:\$PATH\"
eval \"\$(rbenv init -)\"
export PATH=\"\$HOME/.rbenv/plugins/ruby-build/bin:\$PATH\""

    if [ -e ~/.rbenv ] ; then
        echo 'installRbenv: SKIP: ~/.rbenv present already.' 1>&2
        return
    else
        git clone https://github.com/rbenv/rbenv.git ~/.rbenv || return $?
    fi

    if [ ! -e ~/.rbenv/plugins/ruby-build ] ; then
        git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build || return $?
    fi

    if [[ "$(uname -a)" = *[Uu]buntu* ]] && [[ "$-" = *i* ]] ; then
        # Ubuntu desktop edge case as pointed out in
        #   https://www.digitalocean.com/community/tutorials/how-to-install-ruby-on-rails-with-rbenv-on-ubuntu-14-04
        appendunique "$rbenvprofile" ~/.bashrc
    else
        appendunique "$rbenvprofile" ~/.bash_profile
    fi

    if [ -e ~/.zshrc ] ; then
        appendunique "$rbenvprofile" ~/.zshrc
    fi

    exec $SHELL
}

installVm () {

    typeset version="$1"

    rbenv install -v "$version" || return $?
}

setDefaultVm () {

    typeset version="$1"

    rbenv global "$version" || return $?
    rbenv rehash
    ruby -v
}

installBundler () {

    echo "gem: --no-document" > ~/.gemrc

    gem install bundler || return $?
    rbenv rehash

}

installGemDeps () {

    typeset deps

    if userconfirm "Install imagemagick?" ; then
        deps="$deps imagemagick libmagick++-dev"
    fi

    if userconfirm "Install PostgreSQL database?" ; then
        deps="$deps postgresql postgresql-doc libpq-dev postgresql-server-dev-all"
    fi

    sudo $APTPROG install -y $deps || return $?
}

# #############################################################################
# Ruby

installDependencies || exit $?
installRbenv || exit $?

export RUBY_VERSION='2.3.3'
userinput "Enter desired ruby version (default: $RUBY_VERSION)"
export RUBY_VERSION="${userinput:-$RUBY_VERSION}"
installVm "$RUBY_VERSION" || exit $?

setDefaultVm "$RUBY_VERSION" || exit $?

# #############################################################################
# Gems

installBundler || exit $?
installGemDeps || exit $?

if [ -f "$1" ]; then
    BUNDLE_GEMFILE="$1" bundle || exit $?
fi

# #############################################################################
# Display version of main packages

echo ${BASH_VERSION:+-e} "sqlite3\c " ; sqlite3 --version
ruby -v
rails -v