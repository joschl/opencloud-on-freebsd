# OpenCloud FreeBSD Builder

Builds OpenCloud for FreeBSD in Vagrant.

## Requirements

- Vagrant
- VirtualBox
- mise
- HCP auth for `hcp auth print-access-token`
- Vagrant Cloud account for box publishing

## `.env`

Ignored by git. Supported keys:

```sh
HCP_CLIENT_ID=
HCP_CLIENT_SECRET=
VAGRANT_CLOUD_TOKEN=
OPENCLOUD_VERSION=
OPENCLOUD_EDITION=
OPENCLOUD_UPSTREAM_REPO=
PATCH_SOURCE_REPO=
PATCH_SOURCE_REF=
FREEBSD_BOX=
FREEBSD_BOX_VERSION=
FREEBSD_SOURCE_BOX_VERSION=
FREEBSD_READY_BOX_VERSION=
FREEBSD_BUILD_DISK_MB=
VAGRANT_CLOUD_BOX=
```

## Commands

```sh
mise run box:login
mise run opencloud:build
mise run opencloud:package
mise run opencloud:install-smoke
mise run opencloud:install-vm-test
mise run box:ready
mise run box:publish
mise run box:build-fresh
mise run patches:update
```

## Outputs

- install script: `dist/release/install-opencloud-<version>-freebsd-amd64.sh`
- checksum: `dist/release/install-opencloud-<version>-freebsd-amd64.sh.sha256`
- install docs: [docs/freebsd-install.md](docs/freebsd-install.md)

Ignored: `.env`, `.vagrant/`, `build/`, `dist/`, `*.box`, `*.vmdk`, `*.vmdk.xz`.
