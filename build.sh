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

# Help function used in error messages and -h option
usage() {
  echo ""
  echo "Build script for Freifunk-Fulda gluon firmware."
  echo ""
  echo "-c: Build command, [ update | download | build | sign | upload ]"
  echo "-b: String for git branch, e.g. development"
  echo "-d: Enable bash debug output"
  echo "-h: Show this help"
  echo "-m: Optional setting for make options. Default is \"-j 4\""
  echo "-n: String for build number, e.g. b48"
  echo "-w: Path for workspace, e.g. current work directoy"
}

# Evaluate arguments for build script.
while getopts b:c:dhm:n:w: flag; do
  case ${flag} in
    b)
      GIT_BRANCH=${OPTARG};
      ;;
    c)
      case ${OPTARG} in
        update)
        COMMAND=${OPTARG}
        ;;
        download)
        COMMAND=${OPTARG}
        ;;
        build)
        COMMAND=${OPTARG}
        ;;
        sign)
        COMMAND=${OPTARG}
        ;;
        upload)
        COMMAND=${OPTARG}
        ;;
        *)
          echo "Error: Invalid build command set."
          usage
          exit 1
          ;;
      esac
      ;;
    d)
      set -x
      ;;
    h)
      usage
      ;;
    m)
      MAKEOPTS=${OPTARG}
      ;;
    n)
      BUILD_NUMBER=${OPTARG}
      ;;
    w)
      WORKSPACE=${OPTARG};
      ;;
    *)
      usage
      exit;
      ;;
  esac
done

shift $(( OPTIND - 1 ));

# Sanity checks for required arguments
if [ -z "${GIT_BRANCH}" ]; then
  echo "Error: Git branch with -b is not set."
  usage
  exit 1
fi

if [ -z "${BUILD_NUMBER}" ]; then
  echo "Error: Build number with -n is not set."
  usage
  exit 1
fi

if [ -z "${WORKSPACE}" ]; then
  WORKSPACE=$(readlink -e $(dirname $0))
fi

if [ -z "${COMMAND}" ]; then
  echo "Error: Build command with -c is not set."
  usage
  exit 1
fi

# Use the root project as site-config for make commands below
export GLUON_SITEDIR="${WORKSPACE}"

# Configure gluon build
export GLUON_BRANCH="${GIT_BRANCH#origin/}"            # Use the current git branch as autoupdate branch
export GLUON_BUILD="${BUILD_NUMBER}-$(date '+%Y%m%d')" # ... and generate a fency build identifier
export GLUON_RELEASE="${GLUON_BRANCH}-${GLUON_BUILD}"
export GLUON_PRIORITY=1                                # Number of days that may pass between releasing an updating
export GLUON_TARGETS="ar71xx-generic ar71xx-nand mpc85xx-generic x86-generic x86-kvm_guest"

# Specify deployment credentials
export DEPLOYMENT_SERVER="firmware.fulda.freifunk.net"
export DEPLOYMENT_USER="deployment"

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
  cd gluon
  ${COMMAND}
)
