#!/bin/sh
set -eu

vagrant ssh -c "sudo chmod -R u+w /home/vagrant/go /home/vagrant/.cache/go-build /tmp/opencloud-freebsd-build 2>/dev/null || true"
vagrant ssh -c "sudo rm -rf /tmp/opencloud-freebsd-build /home/vagrant/go /home/vagrant/.cache/go-build"
vagrant ssh -c "if ! mount | grep -q ' on /opencloud-build '; then sudo rm -rf /opencloud-build/*; fi"
vagrant ssh -c "df -h"
