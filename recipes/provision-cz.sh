#!/usr/bin/env bash

PROGNAME="provision-cz.sh"


_step_base_system () {
  ${STEP_BASE_SYSTEM_DONE:-false} && return
  [ -e /etc/sudoers ] && ! sudo grep -q "$USER" /etc/sudoers && (echo "$USER ALL=(ALL) NOPASSWD: ALL" | su -c 'tee -a /etc/sudoers' -)
  mkdir ~/workspace >/dev/null 2>&1 ; ls -d -l ~/workspace || exit $?
  bash -c "$(curl --tlsv1.3 -LSf "https://bitbucket.org/stroparo/runr/raw/master/entry.sh" || curl --tlsv1.3 -LSf "https://raw.githubusercontent.com/stroparo/runr/master/entry.sh")" entry.sh apps shell
  source "${DS_HOME:-$HOME/.ds}/ds.sh" || exit $?
  export STEP_BASE_SYSTEM_DONE=true
}


_step_custom () {
  dsplugin.sh "bitbucket.org/stroparo/ds-cz"
  if [ ! -f "${DS_HOME}/envcz.sh" ] ; then
    echo "${PROGNAME}: FATAL: no 'envcz.sh' found in DS_HOME (${DS_HOME})."
    exit 1
  fi

  export PROVISION_OPTIONS="${PROVISION_OPTIONS} gui xfce"
  export RUNR_QUIET=true
  runr provision-stroparo

  bash "${DS_HOME:-$HOME/.ds}"/recipes/cz-conf-git.sh
  bash "${DS_HOME:-$HOME/.ds}"/scripts/czsetupautostart.sh
  echo; echo "==> czsetup.sh <=="
  echo
  echo "Review script \$DS_HOME/.../cz*filesystem*.sh" 1>&2
  echo "... and only then run czsetup.sh." 1>&2
  echo
}


_main () {
  _step_base_system
  _step_custom
}


_main "$@"
