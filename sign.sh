#!/bin/bash -e
# =====================================================================
# Downloads, signs and uploads a gluon manifest file.
#
# This is used by firmware developers to sign a release after it was
# uploaded by the build system.
#
# Source: https://github.com/freifunk-fulda
# Contact: fffd-noc@lists.open-mail.net
# Web: https://fulda.freifunk.net
# =====================================================================

# Basic configuration
SRV_USER="root"
SRV_HOST="firmware.fulda.freifunk.net"
SRV_PORT=22022
SRV_PATH="/var/www/downloads.freifunk-fulda.de/firmware"

# Help function used in error messages and -h option
usage() {
  echo ""
  echo "Downloads, signs and uploads a gluon manifest file."
  echo "Usage ./sign.sh KEYPATH BRANCH"
  echo "    KEYPATH     the path to the developers private key"
  echo "    BRANCH      the branch to sign"
}

# Evaluate arguments for build script.
if [[ "${#}" != 2 ]]; then
  echo "Insufficient arguments given"
  usage
  exit 1
fi

KEYPATH="${1}"
BRANCH="${2}"

# Subsitute all slashes in the branch name
BRANCH=${BRANCH//\//-}

# Sanity checks for required arguments
if [[ ! -e "${KEYPATH}" ]]; then
  echo "Error: Key file not found or not readable: ${KEY_PATH}"
  usage
  exit 1
fi

# Check if ecdsa utils are installed
if ! which ecdsasign 2> /dev/null; then
  echo "ecdsa utils are not found."
  exit 1
fi

# Determine temporary local file
TMP="$(mktemp)"

# Determine upload target prefix
case "${BRANCH}" in
  stable| \
  testing| \
  development)
    TARGET="${BRANCH}"
    ;;

  *)
    TARGET="others/${BRANCH}"
    ;;
esac

# Download manifest
scp \
  -o stricthostkeychecking=no \
  -P "${SRV_PORT}" \
  "${SRV_USER}@${SRV_HOST}:${SRV_PATH}/${TARGET}/current/sysupgrade/${BRANCH}.manifest" \
  "${TMP}"

# Sign the local file
./gluon/contrib/sign.sh \
  "${KEYPATH}" \
  "${TMP}"

# Upload signed file
scp \
  -o stricthostkeychecking=no \
  -P "${SRV_PORT}" \
  "${TMP}" \
  "${SRV_USER}@${SRV_HOST}:${SRV_PATH}/${TARGET}/current/sysupgrade/${BRANCH}.manifest"
