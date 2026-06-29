#!/bin/sh
set -eu

IMAGE_XZ="${FREEBSD_IMAGE_XZ:-FreeBSD-15.1-RELEASE-amd64-zfs.vmdk.xz}"
BOX_NAME="${FREEBSD_BOX_NAME:-opencloud/freebsd-15.1-release}"
BOX_VERSION="${FREEBSD_SOURCE_BOX_VERSION:-15.1.0}"
BUILD_DIR="${FREEBSD_BOX_BUILD_DIR:-build/freebsd-15.1-vagrant-box}"
VM_NAME="${FREEBSD_BOX_VM_NAME:-opencloud-freebsd-15.1-box-build}"
PROJECT_DIR="$(pwd -P)"

case "${BUILD_DIR}" in
  /*) ;;
  *) BUILD_DIR="${PROJECT_DIR}/${BUILD_DIR}" ;;
esac

BOX_FILE="${BUILD_DIR}/${BOX_NAME##*/}-${BOX_VERSION}.box"
DISK_FILE="${BUILD_DIR}/FreeBSD-15.1-RELEASE-amd64-zfs.vmdk"
VDI_FILE="${BUILD_DIR}/FreeBSD-15.1-RELEASE-amd64-zfs.vdi"
BOX_VAGRANTFILE="${BUILD_DIR}/box.Vagrantfile"
PACKAGE_DIR="${BUILD_DIR}/package"
OVF_FILE="${PACKAGE_DIR}/box.ovf"

for tool in VBoxManage qemu-img xz tar; do
  if ! command -v "${tool}" >/dev/null 2>&1; then
    echo "Required tool not found: ${tool}" >&2
    exit 1
  fi
done

if [ ! -f "${IMAGE_XZ}" ]; then
  echo "FreeBSD image not found: ${IMAGE_XZ}" >&2
  echo "Set FREEBSD_IMAGE_XZ=/path/to/FreeBSD-15.1-RELEASE-amd64-zfs.vmdk.xz if needed." >&2
  exit 1
fi

if VBoxManage showvminfo "${VM_NAME}" >/dev/null 2>&1; then
  if [ "${FREEBSD_BOX_FORCE:-0}" != "1" ]; then
    echo "Temporary VM already exists: ${VM_NAME}" >&2
    echo "Set FREEBSD_BOX_FORCE=1 to unregister/delete it and rebuild." >&2
    exit 1
  fi

  VBoxManage unregistervm "${VM_NAME}" --delete
fi

if [ -e "${BUILD_DIR}" ] && [ "${FREEBSD_BOX_FORCE:-0}" != "1" ]; then
  echo "Build directory already exists: ${BUILD_DIR}" >&2
  echo "Set FREEBSD_BOX_FORCE=1 to rebuild it." >&2
  exit 1
fi

rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

echo "Decompressing ${IMAGE_XZ}"
xz -dc "${IMAGE_XZ}" > "${DISK_FILE}"

echo "Converting VMDK to VDI"
qemu-img convert -p -f vmdk -O vdi "${DISK_FILE}" "${VDI_FILE}"
rm -f "${DISK_FILE}"

echo "Creating temporary VirtualBox VM ${VM_NAME}"
VBoxManage createvm --name "${VM_NAME}" --ostype FreeBSD_64 --basefolder "${BUILD_DIR}" --register
VBoxManage modifyvm "${VM_NAME}" \
  --memory 2048 \
  --cpus 2 \
  --ioapic on \
  --rtcuseutc on \
  --boot1 disk \
  --boot2 none \
  --boot3 none \
  --boot4 none \
  --audio none \
  --usb off \
  --nic1 nat
VBoxManage storagectl "${VM_NAME}" --name "SATA Controller" --add sata --controller IntelAhci --portcount 1
VBoxManage storageattach "${VM_NAME}" \
  --storagectl "SATA Controller" \
  --port 0 \
  --device 0 \
  --type hdd \
  --medium "${VDI_FILE}"

cat > "${BOX_VAGRANTFILE}" <<'EOF'
Vagrant.configure("2") do |config|
  config.vm.base_mac = "080027D15F01"
  config.ssh.shell = "/bin/sh"
  config.ssh.username = "vagrant"
  config.ssh.password = "vagrant"
  config.vm.synced_folder ".", "/vagrant", disabled: true
end
EOF

echo "Packaging ${BOX_FILE}"
rm -rf "${PACKAGE_DIR}"
mkdir -p "${PACKAGE_DIR}"
VBoxManage export "${VM_NAME}" --output "${OVF_FILE}"

cp "${BOX_VAGRANTFILE}" "${PACKAGE_DIR}/Vagrantfile"
cat > "${PACKAGE_DIR}/metadata.json" <<EOF
{"provider":"virtualbox"}
EOF
tar -czf "${BOX_FILE}" -C "${PACKAGE_DIR}" .

echo "Adding local Vagrant box ${BOX_NAME}"
vagrant box add --force --name "${BOX_NAME}" "${BOX_FILE}"

echo "Built and installed ${BOX_NAME} from ${IMAGE_XZ}"
echo "Use it with: FREEBSD_BOX=${BOX_NAME} mise run opencloud:build"
