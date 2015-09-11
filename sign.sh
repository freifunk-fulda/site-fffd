#!/bin/bash -ex
# =====================================================================
# Downloads, signs and uploads a gluon manifest file.
#
# This is used by firmware developers to sign a release after it was
# uploaded by the build system.
#
# Source: https://github.com/freifunk-fulda
# Contact: fffd-noc@lists.open-mail.net
# Web: https://fulda.freifunk.net
#
# Credits:
#   - Freifunk Darmstadt for your great support
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
  echo "Usage ./sign.sh KEY_PATH BRANCH"
  echo "    PUBKEY      the path to the developers prvate key"
  echo "    BRANCH      the branch to sign"
}

# Evaluate arguments for build script.
if [[ "${#}" != 2 ]]; then
  echo "Insufficient arguments given"
  usage
  exit 1
fi

PUBKEY="${1}"
BRANCH="${2}"

# Sanity checks for required arguments
if [[ ! -e "${PUBKEY}" ]]; then
  echo "Error: Key file not found or not readable: ${KEY_PATH}"
  usage
  exit 1
fi

if [[ -z "${BRANCH}" ]]; then
  echo "Error: Invalid branch name: ${BRANCH}"
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

# Download manifest
scp \
  -o stricthostkeychecking=no \
  -P "${SRV_PORT}" \
  "${SRV_USER}@${SRV_HOST}:${SRV_PATH}/${BRANCH}/current/sysupgrade/${BRANCH}.manifest" \
  "${TMP}"

# Sign the local file
./gluon/contrib/sign.sh \
  "${PUBKEY}" \
  "${TMP}"

# Upload signed file
scp \
  -o stricthostkeychecking=no \
  -P "${SRV_PORT}" \
  "${TMP}" \
  "${SRV_USER}@${SRV_HOST}:${SRV_PATH}/${BRANCH}/current/sysupgrade/${BRANCH}.manifest"
