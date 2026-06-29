#!/bin/sh
set -eu

OPENCLOUD_SERVICE_USER="${OPENCLOUD_USER:-opencloud}"
OPENCLOUD_SERVICE_GROUP="${OPENCLOUD_GROUP:-opencloud}"
PREFIX="${PREFIX:-/usr/local}"
DESTDIR="${DESTDIR:-}"

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)"
ROOT="${DESTDIR%/}"

target_path() {
  printf '%s%s\n' "${ROOT}" "$1"
}

install_file() {
  install_file_src="$1"
  install_file_dst="$2"
  install_file_mode="$3"
  install -m "${install_file_mode}" "${install_file_src}" "$(target_path "${install_file_dst}")"
}

install_sample() {
  install_sample_src="$1"
  install_sample_dst="$2"
  install_sample_mode="$3"
  install_sample_sample_dst="${install_sample_dst}.sample"
  install_file "${install_sample_src}" "${install_sample_sample_dst}" "${install_sample_mode}"
  if [ ! -e "$(target_path "${install_sample_dst}")" ]; then
    install_file "${install_sample_src}" "${install_sample_dst}" "${install_sample_mode}"
  fi
}

if [ "$(id -u)" != "0" ] && [ -z "${DESTDIR}" ]; then
  echo "Run as root for a real install, or set DESTDIR for a staged install." >&2
  exit 1
fi

if [ -z "${DESTDIR}" ]; then
  install -d -m 0750 /var/db/opencloud
  if ! pw groupshow "${OPENCLOUD_SERVICE_GROUP}" >/dev/null 2>&1; then
    pw groupadd "${OPENCLOUD_SERVICE_GROUP}"
  fi
  if ! pw usershow "${OPENCLOUD_SERVICE_USER}" >/dev/null 2>&1; then
    pw useradd "${OPENCLOUD_SERVICE_USER}" -g "${OPENCLOUD_SERVICE_GROUP}" -d /var/db/opencloud -s /usr/sbin/nologin -c "OpenCloud service"
  else
    pw usermod "${OPENCLOUD_SERVICE_USER}" -d /var/db/opencloud -s /usr/sbin/nologin
  fi
fi

install -d -m 0755 "$(target_path "${PREFIX}/bin")"
install -d -m 0755 "$(target_path "${PREFIX}/etc/rc.d")"
install -d -m 0755 "$(target_path "${PREFIX}/etc/opencloud")"
install -d -m 0755 "$(target_path "${PREFIX}/etc/opencloud/apps")"
install -d -m 0750 "$(target_path "/var/db/opencloud")"
install -d -m 0750 "$(target_path "/var/log/opencloud")"
install -d -m 0750 "$(target_path "/var/run/opencloud")"

install_file "${SCRIPT_DIR}/bin/opencloud" "${PREFIX}/bin/opencloud" 0755
install_file "${SCRIPT_DIR}/etc/rc.d/opencloud" "${PREFIX}/etc/rc.d/opencloud" 0755
install_sample "${SCRIPT_DIR}/etc/opencloud/opencloud.env.sample" "${PREFIX}/etc/opencloud/opencloud.env" 0640
install_sample "${SCRIPT_DIR}/etc/opencloud/csp.yaml" "${PREFIX}/etc/opencloud/csp.yaml" 0644
install_sample "${SCRIPT_DIR}/etc/opencloud/proxy.yaml" "${PREFIX}/etc/opencloud/proxy.yaml" 0644
install_sample "${SCRIPT_DIR}/etc/opencloud/banned-password-list.txt" "${PREFIX}/etc/opencloud/banned-password-list.txt" 0644

if [ -z "${DESTDIR}" ]; then
  chown -R "${OPENCLOUD_SERVICE_USER}:${OPENCLOUD_SERVICE_GROUP}" \
    "${PREFIX}/etc/opencloud" /var/db/opencloud /var/log/opencloud /var/run/opencloud
fi

cat <<EOF
OpenCloud has been installed.

Next steps:
  1. Edit ${PREFIX}/etc/opencloud/opencloud.env
  2. Set OC_URL and IDM_ADMIN_PASSWORD before the first start
  3. Enable the service: sysrc opencloud_enable=YES
  4. Start the service: service opencloud start

Use an external TLS reverse proxy and forward the OpenCloud domain to port 9200.
EOF
