#!/bin/sh
set -eu

CLOUD_BOX="${VAGRANT_CLOUD_BOX:-}"
BOX_VERSION="${FREEBSD_READY_BOX_VERSION:-15.1.2}"
BOX_FILE="${FREEBSD_READY_BOX_FILE:-build/freebsd-15.1-ready-box/freebsd-15.1-builder-${BOX_VERSION}.box}"
ARCH="${FREEBSD_READY_BOX_ARCH:-amd64}"
PROVIDER="${FREEBSD_READY_BOX_PROVIDER:-virtualbox}"

if [ -z "${CLOUD_BOX}" ]; then
  echo "Set VAGRANT_CLOUD_BOX to your Vagrant Cloud box name, e.g. username/freebsd-15.1-builder." >&2
  exit 1
fi

if [ ! -f "${BOX_FILE}" ]; then
  echo "Box file not found: ${BOX_FILE}" >&2
  echo "Run: mise run box:ready" >&2
  exit 1
fi

if ! vagrant cloud auth whoami >/dev/null 2>&1; then
  echo "Not logged in to Vagrant Cloud. Run: mise run box:login" >&2
  exit 1
fi

CHECKSUM="$(sha256sum "${BOX_FILE}" | awk '{print $1}')"

vagrant cloud publish \
  --force \
  --release \
  --direct-upload \
  --architecture "${ARCH}" \
  --checksum-type sha256 \
  --checksum "${CHECKSUM}" \
  --short-description "FreeBSD 15.1 builder for OpenCloud" \
  --version-description "FreeBSD 15.1 builder VM with SSH, sudo, Go, Node, gmake, rsync, and OpenCloud build prerequisites." \
  "${CLOUD_BOX}" \
  "${BOX_VERSION}" \
  "${PROVIDER}" \
  "${BOX_FILE}"
