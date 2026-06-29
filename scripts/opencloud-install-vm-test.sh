#!/bin/sh
set -eu

RELEASE_DIR="${RELEASE_DIR:-dist/release}"
DIST_DIR="${DIST_DIR:-dist/freebsd}"
ARCH="${OPENCLOUD_ARCH:-amd64}"
VERSION="$(cat "${DIST_DIR}/version")"
PACKAGE_NAME="opencloud-${VERSION}-freebsd-${ARCH}"
INSTALLER="${RELEASE_DIR}/install-${PACKAGE_NAME}.sh"
REMOTE_BASE="${REMOTE_BASE:-/opencloud-build/tmp}"
REMOTE_DIR="${REMOTE_BASE}/${PACKAGE_NAME}-vm-install"
REMOTE_INSTALLER="${REMOTE_BASE}/install-${PACKAGE_NAME}.sh"
PUBLIC_URL="${OPENCLOUD_VM_TEST_PUBLIC_URL:-https://cloud.opencloud.test}"
VALIDATION_URL="${OPENCLOUD_VM_TEST_VALIDATION_URL:-http://127.0.0.1:9200}"
VALIDATION_HOST="${OPENCLOUD_VM_TEST_HOST:-cloud.opencloud.test}"
TEST_PASSWORD="${OPENCLOUD_VM_TEST_ADMIN_PASSWORD:-opencloud-vm-test-password}"
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

vagrant ssh -c "sudo service opencloud stop >/dev/null 2>&1 || true"
vagrant ssh -c "sudo rm -rf /tmp/opencloud-*-smoke /tmp/opencloud-*-root /tmp/opencloud-*.tar.gz /tmp/install-opencloud-*.sh /tmp/opencloud-debug-root /tmp/opencloud-vm-test.html"
vagrant ssh -c "sudo rm -rf '${REMOTE_DIR}' /usr/local/bin/opencloud /usr/local/etc/rc.d/opencloud /usr/local/etc/opencloud /var/db/opencloud /var/log/opencloud /var/run/opencloud"
vagrant ssh -c "mkdir -p '${REMOTE_DIR}'"
vagrant ssh -c "sudo env TMPDIR='${REMOTE_BASE}' /bin/sh '${REMOTE_INSTALLER}'"

vagrant ssh -c "sudo sed -i '' 's#^OC_URL=.*#OC_URL=${PUBLIC_URL}#' /usr/local/etc/opencloud/opencloud.env"
vagrant ssh -c "sudo sed -i '' 's#^IDM_ADMIN_PASSWORD=.*#IDM_ADMIN_PASSWORD=${TEST_PASSWORD}#' /usr/local/etc/opencloud/opencloud.env"
vagrant ssh -c "sudo sed -i '' 's#^OC_INSECURE=.*#OC_INSECURE=true#' /usr/local/etc/opencloud/opencloud.env"
vagrant ssh -c "sudo sysrc opencloud_enable=YES >/dev/null"
vagrant ssh -c "sudo service opencloud start"

vagrant ssh -c "for i in \$(seq 1 90); do if sockstat -4 -l | grep -q ':9200'; then exit 0; fi; sleep 2; done; echo 'OpenCloud did not listen on port 9200 in time' >&2; sudo tail -100 /var/log/opencloud/opencloud.log >&2; exit 1"
vagrant ssh -c "for i in \$(seq 1 120); do if curl -fsS -H 'Host: ${VALIDATION_HOST}' -o /tmp/opencloud-vm-test.html '${VALIDATION_URL}/'; then exit 0; fi; sleep 2; done; echo 'OpenCloud did not return a successful HTTP response' >&2; sudo tail -120 /var/log/opencloud/opencloud.log >&2; exit 1"
vagrant ssh -c "sudo service opencloud status"
vagrant ssh -c "grep -qi 'opencloud' /tmp/opencloud-vm-test.html"

echo "OpenCloud VM install test passed at ${VALIDATION_URL} with Host: ${VALIDATION_HOST}"
