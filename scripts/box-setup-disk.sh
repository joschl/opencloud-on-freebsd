#!/bin/sh
set -eu

BUILD_LABEL="${FREEBSD_BUILD_LABEL:-opencloud-build}"
BUILD_MOUNT="${FREEBSD_BUILD_MOUNT:-/opencloud-build}"
BUILD_DEVICE="${FREEBSD_BUILD_DEVICE:-/dev/ada1}"

if [ "$(uname -s)" != "FreeBSD" ]; then
  echo "This script must run inside the FreeBSD VM." >&2
  exit 1
fi

mkdir -p "${BUILD_MOUNT}"

if ! mount | grep -q " on ${BUILD_MOUNT} "; then
  if [ ! -e "/dev/gpt/${BUILD_LABEL}" ]; then
    gpart create -s GPT "${BUILD_DEVICE}" 2>/dev/null || true
    gpart add -t freebsd-ufs -l "${BUILD_LABEL}" "${BUILD_DEVICE}"
    newfs -U "/dev/gpt/${BUILD_LABEL}"
  fi

  # If previous attempts wrote into the mountpoint before the disk was mounted,
  # remove that root-backed data before mounting the build disk over it.
  find "${BUILD_MOUNT}" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
  mount -o noatime "/dev/gpt/${BUILD_LABEL}" "${BUILD_MOUNT}"
fi

chown vagrant:wheel "${BUILD_MOUNT}"
chmod 775 "${BUILD_MOUNT}"

if ! df -h "${BUILD_MOUNT}" | awk 'NR == 2 { exit ($6 == "'"${BUILD_MOUNT}"'" ? 0 : 1) }'; then
  echo "${BUILD_MOUNT} is not mounted as a dedicated filesystem." >&2
  exit 1
fi

df -h "${BUILD_MOUNT}"
