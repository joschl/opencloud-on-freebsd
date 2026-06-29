#!/bin/sh
set -eu

BOX_NAME="${FREEBSD_BOX:-j0sch7/freebsd-15.1-builder}"
BUILD_DISK="${FREEBSD_BUILD_DISK:-build/opencloud-freebsd-builder-data.vdi}"

vagrant destroy -f
if [ "${FREEBSD_RECREATE_BUILD_DISK:-0}" = "1" ]; then
  rm -f "${BUILD_DISK}"
fi
vagrant box update --box "${BOX_NAME}" || true
vagrant up --provision
scripts/opencloud-build.sh
