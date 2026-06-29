#!/bin/sh
set -eu

PROJECT_DIR="${PROJECT_DIR:-/tmp/opencloud-build-env}"
PATCH_DIR="${PATCH_DIR:-${PROJECT_DIR}/patches}"
DIST_DIR="${DIST_DIR:-${PROJECT_DIR}/dist/freebsd}"
OPENCLOUD_VERSION="${OPENCLOUD_VERSION:-latest}"
OPENCLOUD_EDITION="${OPENCLOUD_EDITION:-${EDITION:-rolling}}"
OPENCLOUD_UPSTREAM_REPO="${OPENCLOUD_UPSTREAM_REPO:-opencloud-eu/opencloud}"

if [ "$(uname -s)" != "FreeBSD" ]; then
  echo "This build script must run inside the FreeBSD Vagrant VM." >&2
  exit 1
fi

export PATH="/usr/local/bin:${PATH}"

if mount | grep -q " on /opencloud-build " && [ -w /opencloud-build ]; then
  BUILD_ROOT="${BUILD_ROOT:-/opencloud-build}"
else
  echo "/opencloud-build is not mounted; run vagrant provision or mise run opencloud:build again after the build disk is attached." >&2
  exit 1
fi

WORK_DIR="${WORK_DIR:-${BUILD_ROOT}/opencloud-freebsd-build}"
export GOPATH="${GOPATH:-${BUILD_ROOT}/go}"
export GOCACHE="${GOCACHE:-${BUILD_ROOT}/gocache}"
export GOMODCACHE="${GOMODCACHE:-${GOPATH}/pkg/mod}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-${BUILD_ROOT}/xdg-cache}"
export npm_config_cache="${npm_config_cache:-${BUILD_ROOT}/npm-cache}"
export COREPACK_HOME="${COREPACK_HOME:-${BUILD_ROOT}/corepack}"
export COREPACK_ENABLE_DOWNLOAD_PROMPT="${COREPACK_ENABLE_DOWNLOAD_PROMPT:-0}"
export TMPDIR="${TMPDIR:-${BUILD_ROOT}/tmp}"
export GOTMPDIR="${GOTMPDIR:-${TMPDIR}}"

mkdir -p "${GOPATH}" "${GOCACHE}" "${GOMODCACHE}" "${XDG_CACHE_HOME}" "${npm_config_cache}" "${COREPACK_HOME}" "${TMPDIR}"

if ! command -v go >/dev/null 2>&1 && command -v go126 >/dev/null 2>&1; then
  mkdir -p "${PROJECT_DIR}/bin"
  ln -sf "$(command -v go126)" "${PROJECT_DIR}/bin/go"
  ln -sf "$(command -v gofmt126)" "${PROJECT_DIR}/bin/gofmt"
  export PATH="${PROJECT_DIR}/bin:${PATH}"
fi

if [ ! -d "${PATCH_DIR}" ]; then
  echo "Patch directory not found: ${PATCH_DIR}" >&2
  exit 1
fi

mkdir -p "${DIST_DIR}"
rm -rf "${WORK_DIR}"
mkdir -p "${WORK_DIR}"

cd "${WORK_DIR}"

if [ "${OPENCLOUD_VERSION}" = "latest" ]; then
  RELEASE_PATH="latest"
else
  RELEASE_TAG="${OPENCLOUD_VERSION}"
  case "${RELEASE_TAG}" in
    v*) ;;
    *) RELEASE_TAG="v${RELEASE_TAG}" ;;
  esac
  RELEASE_PATH="tags/${RELEASE_TAG}"
fi

UPSTREAM_URL="${UPSTREAM_URL:-https://api.github.com/repos/${OPENCLOUD_UPSTREAM_REPO}/releases/${RELEASE_PATH}}"

echo "Fetching OpenCloud release metadata from ${UPSTREAM_URL}"
fetch -qo latest.json "${UPSTREAM_URL}"

VERSION="$(jq -r '.tag_name' latest.json | sed 's/^v//')"
TARBALL_URL="$(jq -r '.tarball_url' latest.json)"

if [ -z "${VERSION}" ] || [ "${VERSION}" = "null" ]; then
  echo "Could not determine OpenCloud version from release metadata." >&2
  exit 1
fi

if [ -z "${TARBALL_URL}" ] || [ "${TARBALL_URL}" = "null" ]; then
  echo "Could not determine OpenCloud tarball URL from release metadata." >&2
  exit 1
fi

echo "Building OpenCloud ${VERSION}"
fetch -qo opencloud.tar.gz "${TARBALL_URL}"
mkdir -p source
tar -C source -xzf opencloud.tar.gz --strip-components 1

cd source

for patch_file in "${PATCH_DIR}"/*.patch; do
  [ -e "${patch_file}" ] || {
    echo "No patches found in ${PATCH_DIR}" >&2
    exit 1
  }

  echo "Applying ${patch_file}"
  patch -p0 < "${patch_file}"
done

go install github.com/bwplotka/bingo@latest

EDITION="${OPENCLOUD_EDITION}" gmake clean generate VERSION="${VERSION}"
EDITION="${OPENCLOUD_EDITION}" gmake -C opencloud build VERSION="${VERSION}"

ARCH="$(uname -m)"
BUILT_BINARY="opencloud/bin/opencloud"
VERSIONED_BINARY="${DIST_DIR}/opencloud-${VERSION}-freebsd-${ARCH}"
STABLE_BINARY="${DIST_DIR}/opencloud"

if [ ! -x "${BUILT_BINARY}" ]; then
  echo "Expected build output missing or not executable: ${BUILT_BINARY}" >&2
  exit 1
fi

cp "${BUILT_BINARY}" "${VERSIONED_BINARY}"
cp "${BUILT_BINARY}" "${STABLE_BINARY}"
printf '%s\n' "${VERSION}" > "${DIST_DIR}/version"
printf '%s\n' "${TARBALL_URL}" > "${DIST_DIR}/tarball_url"

echo "Built ${VERSIONED_BINARY}"
echo "Updated ${STABLE_BINARY}"
