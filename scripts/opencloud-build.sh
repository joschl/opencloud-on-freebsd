#!/bin/sh
set -eu

PROJECT_DIR="${PROJECT_DIR:-/tmp/opencloud-build-env}"
HOST_DIST_DIR="${HOST_DIST_DIR:-dist/freebsd}"
SSH_CONFIG="$(mktemp)"

cleanup() {
  rm -f "${SSH_CONFIG}"
}
trap cleanup EXIT

vagrant up
vagrant ssh -c "rm -rf '${PROJECT_DIR}' && mkdir -p '${PROJECT_DIR}'"
vagrant upload scripts "${PROJECT_DIR}/scripts"
vagrant upload patches "${PROJECT_DIR}/patches"
vagrant ssh -c "sudo /bin/sh '${PROJECT_DIR}/scripts/box-setup-disk.sh'"
vagrant ssh -c "PROJECT_DIR='${PROJECT_DIR}' /bin/sh '${PROJECT_DIR}/scripts/opencloud-build-vm.sh'"

mkdir -p "${HOST_DIST_DIR}"
vagrant ssh-config > "${SSH_CONFIG}"
rsync -az --delete -e "ssh -F ${SSH_CONFIG}" "default:${PROJECT_DIR}/dist/freebsd/" "${HOST_DIST_DIR}/"

echo "FreeBSD build artifacts copied to ${HOST_DIST_DIR}/"
