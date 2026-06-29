#!/bin/sh
set -eu

export ASSUME_ALWAYS_YES=yes

pkg update
pkg install -y \
  bash \
  ca_root_nss \
  curl \
  git \
  gmake \
  go126 \
  jq \
  npm-node24 \
  rsync

if [ ! -e /usr/local/bin/go ] && [ -x /usr/local/bin/go126 ]; then
  ln -s /usr/local/bin/go126 /usr/local/bin/go
fi

if [ ! -e /usr/local/bin/gofmt ] && [ -x /usr/local/bin/gofmt126 ]; then
  ln -s /usr/local/bin/gofmt126 /usr/local/bin/gofmt
fi

BUILD_DEVICE="${FREEBSD_BUILD_DEVICE:-/dev/ada1}"
BUILD_LABEL="${FREEBSD_BUILD_LABEL:-opencloud-build}"
BUILD_MOUNT="${FREEBSD_BUILD_MOUNT:-/opencloud-build}"

if [ -c "${BUILD_DEVICE}" ] && [ -x /tmp/opencloud-build-env/scripts/box-setup-disk.sh ]; then
  /bin/sh /tmp/opencloud-build-env/scripts/box-setup-disk.sh
elif [ -c "${BUILD_DEVICE}" ]; then
  mkdir -p "${BUILD_MOUNT}"
  if [ ! -e "/dev/gpt/${BUILD_LABEL}" ]; then
    gpart create -s GPT "${BUILD_DEVICE}" 2>/dev/null || true
    gpart add -t freebsd-ufs -l "${BUILD_LABEL}" "${BUILD_DEVICE}"
    newfs -U "/dev/gpt/${BUILD_LABEL}"
  fi
  mount -o noatime "/dev/gpt/${BUILD_LABEL}" "${BUILD_MOUNT}" 2>/dev/null || true
  chown vagrant:wheel "${BUILD_MOUNT}"
  chmod 775 "${BUILD_MOUNT}"
fi

npm install --global corepack@latest
corepack enable pnpm

echo "FreeBSD OpenCloud build dependencies are installed."
