#!/bin/sh
set -eu

PATCH_SOURCE_REPO="${PATCH_SOURCE_REPO:-daemonless/opencloud}"
PATCH_SOURCE_REF="${PATCH_SOURCE_REF:-main}"
PATCH_DIR="${PATCH_DIR:-patches}"
API_URL="https://api.github.com/repos/${PATCH_SOURCE_REPO}/contents/patches?ref=${PATCH_SOURCE_REF}"
TMP_DIR="$(mktemp -d)"
PATCH_LIST="${TMP_DIR}/patches.tsv"

cleanup() {
  rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

for tool in curl jq; do
  if ! command -v "${tool}" >/dev/null 2>&1; then
    echo "Required tool not found: ${tool}" >&2
    exit 1
  fi
done

mkdir -p "${PATCH_DIR}"

echo "Fetching patch list from ${API_URL}"
curl -fsSL "${API_URL}" \
  | jq -r '.[] | select(.type == "file" and (.name | endswith(".patch"))) | [.name, .download_url] | @tsv' \
  > "${PATCH_LIST}"

if [ ! -s "${PATCH_LIST}" ]; then
  echo "Remote patch list is empty: ${API_URL}" >&2
  exit 1
fi

while IFS="$(printf '\t')" read -r patch_name patch_url; do
  if [ -z "${patch_name}" ] || [ -z "${patch_url}" ] || [ "${patch_url}" = "null" ]; then
    echo "Invalid patch entry from ${API_URL}" >&2
    exit 1
  fi

  case "${patch_name}" in
    */*|..*)
      echo "Unsafe patch name from remote: ${patch_name}" >&2
      exit 1
      ;;
  esac

  echo "Downloading ${patch_name}"
  curl -fsSL "${patch_url}" -o "${TMP_DIR}/${patch_name}"
done < "${PATCH_LIST}"

rm -f "${PATCH_DIR}"/*.patch
for patch_file in "${TMP_DIR}"/*.patch; do
  [ -e "${patch_file}" ] || {
    echo "No patches were downloaded." >&2
    exit 1
  }
  mv "${patch_file}" "${PATCH_DIR}/"
done

echo "Updated patches in ${PATCH_DIR}/"
