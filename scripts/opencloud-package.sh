#!/bin/sh
set -eu

DIST_DIR="${DIST_DIR:-dist/freebsd}"
PACKAGE_SRC_DIR="${PACKAGE_SRC_DIR:-packaging/freebsd}"
RELEASE_DIR="${RELEASE_DIR:-dist/release}"
ARCH="${OPENCLOUD_ARCH:-amd64}"

if [ ! -f "${DIST_DIR}/version" ]; then
  echo "Missing ${DIST_DIR}/version. Run mise run opencloud:build first." >&2
  exit 1
fi

VERSION="$(cat "${DIST_DIR}/version")"
BINARY="${DIST_DIR}/opencloud-${VERSION}-freebsd-${ARCH}"
PACKAGE_NAME="opencloud-${VERSION}-freebsd-${ARCH}"
WORK_DIR="${RELEASE_DIR}/${PACKAGE_NAME}"
TARBALL="${RELEASE_DIR}/${PACKAGE_NAME}.tar.gz"
INSTALLER="${RELEASE_DIR}/install-${PACKAGE_NAME}.sh"

if [ ! -x "${BINARY}" ]; then
  echo "Missing executable build artifact: ${BINARY}" >&2
  exit 1
fi

rm -rf "${WORK_DIR}"
mkdir -p "${WORK_DIR}/bin" "${WORK_DIR}/etc/opencloud/apps" "${WORK_DIR}/etc/rc.d" "${RELEASE_DIR}"

install -m 0755 "${BINARY}" "${WORK_DIR}/bin/opencloud"
install -m 0755 "${PACKAGE_SRC_DIR}/install-opencloud-freebsd.sh" "${WORK_DIR}/install-opencloud-freebsd.sh"
install -m 0755 "${PACKAGE_SRC_DIR}/etc/rc.d/opencloud" "${WORK_DIR}/etc/rc.d/opencloud"
install -m 0644 "${PACKAGE_SRC_DIR}/etc/opencloud/opencloud.env.sample" "${WORK_DIR}/etc/opencloud/opencloud.env.sample"
install -m 0644 "${PACKAGE_SRC_DIR}/etc/opencloud/csp.yaml" "${WORK_DIR}/etc/opencloud/csp.yaml"
install -m 0644 "${PACKAGE_SRC_DIR}/etc/opencloud/proxy.yaml" "${WORK_DIR}/etc/opencloud/proxy.yaml"
install -m 0644 "${PACKAGE_SRC_DIR}/etc/opencloud/banned-password-list.txt" "${WORK_DIR}/etc/opencloud/banned-password-list.txt"

{
  printf 'name=%s\n' "${PACKAGE_NAME}"
  printf 'version=%s\n' "${VERSION}"
  printf 'arch=%s\n' "${ARCH}"
  printf 'source_tarball_url=%s\n' "$(cat "${DIST_DIR}/tarball_url" 2>/dev/null || true)"
  printf 'built_at_utc=%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  printf '\nfiles:\n'
  find "${WORK_DIR}" -type f | sed "s#^${WORK_DIR}/#  #g" | sort
} > "${WORK_DIR}/MANIFEST"

(cd "${WORK_DIR}" && find . -type f ! -name SHA256SUMS -print | sort | xargs sha256sum) > "${WORK_DIR}/SHA256SUMS"

rm -f "${TARBALL}"
tar -czf "${TARBALL}" -C "${RELEASE_DIR}" "${PACKAGE_NAME}"

cat > "${INSTALLER}" <<EOF
#!/bin/sh
set -eu

SELF="\$0"
TMPDIR="\$(mktemp -d "\${TMPDIR:-/tmp}/opencloud-install.XXXXXX")"

cleanup() {
  rm -rf "\${TMPDIR}"
}
trap cleanup EXIT

ARCHIVE="\${TMPDIR}/${PACKAGE_NAME}.tar.gz"

awk '
  found { print }
  /^__OPENCLOUD_INSTALLER_PAYLOAD__\$/ { found = 1 }
' "\${SELF}" | base64 -d > "\${ARCHIVE}"

tar -xzf "\${ARCHIVE}" -C "\${TMPDIR}"
cd "\${TMPDIR}/${PACKAGE_NAME}"
exec /bin/sh ./install-opencloud-freebsd.sh "\$@"

__OPENCLOUD_INSTALLER_PAYLOAD__
EOF
base64 "${TARBALL}" >> "${INSTALLER}"
chmod 0755 "${INSTALLER}"

echo "Built ${TARBALL}"
echo "Built ${INSTALLER}"
sha256sum "${TARBALL}" > "${TARBALL}.sha256"
sha256sum "${INSTALLER}" > "${INSTALLER}.sha256"
