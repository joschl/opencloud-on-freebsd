#!/bin/sh
set -eu

echo "Vagrant status:"
vagrant status
echo

echo "Vagrant SSH config:"
vagrant ssh-config || true
echo

echo "Local listeners on 2222/2200:"
if command -v ss >/dev/null 2>&1; then
  ss -ltnp '( sport = :2222 or sport = :2200 )' || true
elif command -v lsof >/dev/null 2>&1; then
  lsof -nP -iTCP:2222 -iTCP:2200 -sTCP:LISTEN || true
else
  netstat -an | grep -E '(\.2222|:2222|\.2200|:2200).*LISTEN' || true
fi
