#!/bin/sh
set -eu

RELEASE_DIR="${RELEASE_DIR:-dist/release}"
DIST_DIR="${DIST_DIR:-dist/freebsd}"
ARCH="${OPENCLOUD_ARCH:-amd64}"
VERSION="$(cat "${DIST_DIR}/version")"
PACKAGE_NAME="opencloud-${VERSION}-freebsd-${ARCH}"
INSTALLER="${RELEASE_DIR}/install-${PACKAGE_NAME}.sh"
REMOTE_BASE="${REMOTE_BASE:-/opencloud-build/tmp}"
REMOTE_DIR="${REMOTE_BASE}/${PACKAGE_NAME}-smoke"
REMOTE_ROOT="${REMOTE_BASE}/${PACKAGE_NAME}-root"
REMOTE_INSTALLER="${REMOTE_BASE}/install-${PACKAGE_NAME}.sh"
SSH_CONFIG="$(mktemp)"

cleanup() {
  rm -f "${SSH_CONFIG}"
}
trap cleanup EXIT

if [ ! -f "${INSTALLER}" ]; then
  echo "Missing release installer: ${INSTALLER}" >&2
  echo "Run: mise run opencloud:package" >&2
  exit 1
fi

vagrant ssh -c "mkdir -p '${REMOTE_BASE}'"
vagrant ssh-config > "${SSH_CONFIG}"
rsync -az -e "ssh -F ${SSH_CONFIG}" "${INSTALLER}" "default:${REMOTE_INSTALLER}"
vagrant ssh -c "rm -rf '${REMOTE_DIR}' '${REMOTE_ROOT}' && mkdir -p '${REMOTE_DIR}'"
vagrant ssh -c "TMPDIR='${REMOTE_BASE}' DESTDIR='${REMOTE_ROOT}' /bin/sh '${REMOTE_INSTALLER}'"
vagrant ssh -c "test -x '${REMOTE_ROOT}/usr/local/bin/opencloud' && test -x '${REMOTE_ROOT}/usr/local/etc/rc.d/opencloud' && test -f '${REMOTE_ROOT}/usr/local/etc/opencloud/opencloud.env' && test -f '${REMOTE_ROOT}/usr/local/etc/opencloud/opencloud.env.sample'"
vagrant ssh -c "/bin/sh -n '${REMOTE_ROOT}/usr/local/etc/rc.d/opencloud'"
vagrant ssh -c "sha256 -q '${REMOTE_INSTALLER}' >/dev/null"

echo "OpenCloud install smoke passed in ${REMOTE_ROOT}"
