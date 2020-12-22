#!/bin/sh

PROGNAME="apps-cli.sh"

export PKG_LIST_FILE_EL="${RUNR_DIR}/assets/pkgs-el.lst"
export PKG_LIST_FILE_EL_EPEL="${RUNR_DIR}/assets/pkgs-el-epel.lst"
export PKG_LIST_FILE_UBUNTU="${RUNR_DIR}/assets/pkgs-ubuntu.lst"


if _is_debian_family ; then
  export PKG_LIST_FILE="${PKG_LIST_FILE_UBUNTU}"
elif _is_el_family ; then
  export PKG_LIST_FILE="${PKG_LIST_FILE_EL}"
else
  echo "${PROGNAME:+$PROGNAME: }SKIP: OS not supported." 1>&2
  exit
fi


echo "$PROGNAME: INFO: started..."
echo "$PROGNAME: INFO: \$0='$0'; \$PWD='$PWD'"

source "${RUNR_DIR:-.}"/helpers/dsenforce.sh

cd "${RUNR_DIR:-$PWD}"


if _is_debian_family ; then
  if ! (sudo "$APTPROG" update | tee '/tmp/apt-update-err.log') ; then
    echo "$PROGNAME: WARN: There was some failure during APT index update - see '/tmp/apt-update-err.log'." 1>&2
  fi

elif _is_el_family ; then
  installrepoepel
  sudo $RPMGROUP -q -y --enablerepo=epel 'Development Tools'
  installpkgsepel $(validpkgs "${PKG_LIST_FILE_EL_EPEL}")
fi

installpkgs $(validpkgs "${PKG_LIST_FILE}")

if _is_debian_family ; then aptcleanup ; fi


echo
echo
echo "$PROGNAME: COMPLETE"
exit
