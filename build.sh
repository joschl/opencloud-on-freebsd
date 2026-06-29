#!/bin/sh
set -eu

if [ "$(uname -s)" = "FreeBSD" ]; then
  exec sh "$(dirname "$0")/scripts/opencloud-build-vm.sh"
fi

if command -v mise >/dev/null 2>&1; then
  exec mise run opencloud:build
fi

echo "This build is intended to run in the FreeBSD Vagrant VM." >&2
echo "Install mise and run: mise run box:up && mise run opencloud:build" >&2
exit 1
