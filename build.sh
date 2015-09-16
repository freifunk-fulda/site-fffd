#!/bin/bash -e
# =====================================================================
# Build script for Freifunk Fulda firmware runningn on Jenkins CI
#
# Source: https://github.com/freifunk-fulda
# Contact: fffd-noc@lists.open-mail.net
# Web: https://fulda.freifunk.net
#
# Credits:
#   - Freifunk Darmstadt for your great support
# =====================================================================

# Default make options
MAKEOPTS="-j 4 V=s"

# Default to build all Gluon targets if parameter -t is not set
GLUON_TARGETS="ar71xx-generic ar71xx-nand mpc85xx-generic x86-generic x86-kvm_guest"

# Default is set to use current work directory
GLUON_SITEDIR="$(pwd)"

# Default build set to snapshot
BUILD_NUMBER="snapshot"

# Specify deployment server and user
DEPLOYMENT_SERVER="firmware.fulda.freifunk.net"
DEPLOYMENT_USER="deployment"

E_MISSING_ARG=126
E_WRONG_ARG=127

# Help function used in error messages and -h option
usage() {
  echo ""
  echo "Build script for Freifunk-Fulda gluon firmware."
  echo ""
  echo "-b: String for git branch, e.g. development"
  echo "-c: Build command, [ update | download | build | sign | upload ]"
  echo "-d: Enable bash debug output"
  echo "-h: Show this help"
  echo "-m: Optional setting for make options."
  echo "    Default is \"${MAKEOPTS}\""
  echo "-n: String for build number is optional"
  echo "    Default is: \"${BUILD_NUMBER}\""
  echo "-t: Set gluon targets for build."
  echo "    Default is: \"${GLUON_TARGETS}\""
  echo "-w: Path for workspace used for Gluon site directory, e.g. current work directoy"
  echo "    Default is: \"${GLUON_SITEDIR}\""
}

# Evaluate arguments for build script.
if [[ "${#}" == 0 ]]; then
  usage
  exit ${E_MISSING_ARG}
fi

# Evaluate arguments for build script.
while getopts b:c:dhm:n:t:w: flag; do
  case ${flag} in
    b)
        GIT_BRANCH="${OPTARG}"
        ;;
    c)
      case "${OPTARG}" in
        update)
          COMMAND="${OPTARG}"
          ;;
        download)
          COMMAND="${OPTARG}"
          ;;
        build)
          COMMAND="${OPTARG}"
          ;;
        sign)
          COMMAND="${OPTARG}"
          ;;
        upload)
          COMMAND="${OPTARG}"
          ;;
        *)
          echo "Error: Invalid build command set."
          usage
          exit ${E_WRONG_ARG}
          ;;
      esac
      ;;
    d)
      set -x
      ;;
    h)
      usage
      exit
      ;;
    m)
      MAKEOPTS="${OPTARG}"
      ;;
    n)
      BUILD_NUMBER="${OPTARG}"
      ;;
    t)
      GLUON_TARGETS="${OPTARG}"
      ;;
    w)
      # Use the root project as site-config for make commands below
      GLUON_SITEDIR="${OPTARG}"
      ;;
    *)
      usage
      exit ${E_WRONG_ARG}
      ;;
  esac
done

shift $(( OPTIND - 1 ));

if [ -z "${GIT_BRANCH}" ]; then
  # Set branch name
  GIT_BRANCH=$(git symbolic-ref -q HEAD)
  GIT_BRANCH=${GIT_BRANCH##refs/heads/}
  GIT_BRANCH=${GIT_BRANCH:-HEAD}
fi

if [ -z "${COMMAND}" ]; then
  echo "Error: Build command with -c is not set."
  usage
  exit ${E_MISSING_ARG}
fi

# Configure gluon build environment
export GLUON_BRANCH="${GIT_BRANCH#origin/}"            # Use the current git branch as autoupdate branch
export GLUON_BRANCH="${GLUON_BRANCH//\//-}"
export GLUON_BUILD="${BUILD_NUMBER}-$(date '+%Y%m%d')" # ... and generate a fency build identifier
export GLUON_RELEASE="${GLUON_BRANCH}-${GLUON_BUILD}"
export GLUON_PRIORITY=1                                # Number of days that may pass between releasing an updating
export GLUON_SITEDIR

update() {
  make update ${MAKEOPTS}
  for GLUON_TARGET in ${GLUON_TARGETS}; do
    echo "--- Update Gluon for target: ${GLUON_TARGET}"
    make clean ${MAKEOPTS} GLUON_TARGET=${GLUON_TARGET}
  done
}

download() {
  for GLUON_TARGET in ${GLUON_TARGETS}; do
    echo "--- Download Gluon Dependencies for target: ${GLUON_TARGET}"
    make download ${MAKEOPTS} GLUON_TARGET=${GLUON_TARGET}
  done
}

build() {
  for GLUON_TARGET in ${GLUON_TARGETS}; do
    echo "--- Build Gluon Dependencies for target: ${GLUON_TARGET}"
    make ${MAKEOPTS} GLUON_TARGET=${GLUON_TARGET}
  done
}

sign() {
  echo "--- Sign Gluon Firmware Build"
  contrib/sign.sh ~/freifunk/autoupdate_secret_jenkins images/sysupgrade/${GLUON_BRANCH}.manifest
}

upload() {
  echo "--- Upload Gluon Firmware Build"
  ssh -i ~/.ssh/deploy_id_rsa -o stricthostkeychecking=no -p 22022 ${DEPLOYMENT_USER}@${DEPLOYMENT_SERVER} "mkdir -p firmware/${GLUON_BRANCH}/${GLUON_BUILD}"
  scp -i ~/.ssh/deploy_id_rsa -o stricthostkeychecking=no -P 22022 -r images/* ${DEPLOYMENT_USER}@${DEPLOYMENT_SERVER}:firmware/${GLUON_BRANCH}/${GLUON_BUILD}
  ssh -i ~/.ssh/deploy_id_rsa -o stricthostkeychecking=no -p 22022 ${DEPLOYMENT_USER}@${DEPLOYMENT_SERVER} "ln -sf -T ${GLUON_BUILD} firmware/${GLUON_BRANCH}/current"
}

(
  cd "${GLUON_SITEDIR}/gluon"
  ${COMMAND}
)
