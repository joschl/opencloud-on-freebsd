#!/bin/sh
set -eu

BOX_NAME="${FREEBSD_READY_BOX_NAME:-opencloud/freebsd-15.1-builder}"
BOX_VERSION="${FREEBSD_READY_BOX_VERSION:-15.1.2}"
BUILD_DIR="${FREEBSD_READY_BOX_BUILD_DIR:-build/freebsd-15.1-ready-box}"
BOX_FILE="${BUILD_DIR}/${BOX_NAME##*/}-${BOX_VERSION}.box"
BOX_VAGRANTFILE="${BUILD_DIR}/box.Vagrantfile"
VAGRANT_PUB="${BUILD_DIR}/vagrant.pub"

mkdir -p "${BUILD_DIR}"

cat > "${BOX_VAGRANTFILE}" <<'EOF'
Vagrant.configure("2") do |config|
  config.ssh.username = "vagrant"
  config.ssh.insert_key = false
  config.ssh.shell = "/bin/sh"
  config.ssh.sudo_command = "sudo %c"
  config.vm.synced_folder ".", "/vagrant", disabled: true
end
EOF

VAGRANT_KEY_SOURCE="$(find /opt/vagrant/embedded/gems/gems -path '*/keys/vagrant.pub' -type f | sort | tail -1)"
if [ -z "${VAGRANT_KEY_SOURCE}" ]; then
  echo "Could not find Vagrant insecure public key." >&2
  exit 1
fi
cp "${VAGRANT_KEY_SOURCE}" "${VAGRANT_PUB}"

vagrant upload "${VAGRANT_PUB}" /tmp/vagrant.pub
vagrant ssh -c "mkdir -p /home/vagrant/.ssh && cat /tmp/vagrant.pub > /home/vagrant/.ssh/authorized_keys && chmod 700 /home/vagrant/.ssh && chmod 600 /home/vagrant/.ssh/authorized_keys"
vagrant ssh -c "sudo sed -i '' '/\\/dev\\/gpt\\/opencloud-build[[:space:]]/d' /etc/fstab"
vagrant ssh -c "sudo rm -rf /tmp/opencloud-freebsd-build /tmp/opencloud-build-env /home/vagrant/go /home/vagrant/.cache/go-build /opencloud-build/opencloud-freebsd-build /opencloud-build/tmp"
vagrant ssh -c "sudo pkg clean -ay || true"
vagrant halt

rm -f "${BOX_FILE}"
vagrant package --output "${BOX_FILE}" --vagrantfile "${BOX_VAGRANTFILE}"
vagrant box add --force --name "${BOX_NAME}" "${BOX_FILE}"

echo "Built reusable box: ${BOX_NAME}"
echo "Box file: ${BOX_FILE}"
