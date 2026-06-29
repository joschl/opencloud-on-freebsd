# OpenCloud FreeBSD Builder

This repository builds OpenCloud for FreeBSD inside a Vagrant-managed builder VM and packages the reusable FreeBSD builder box.

## Prerequisites

- Vagrant
- VirtualBox
- mise
- HashiCorp Cloud Platform auth configured for `hcp auth print-access-token`
- Vagrant Cloud account with access to publish the configured box

## Local Environment

Local secrets belong in `.env`, which is intentionally ignored by git. Define only the values you need to override:

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

## Common Commands

```sh
mise run box:login
mise run opencloud:build
mise run box:ready
mise run box:publish
mise run box:build-fresh
mise run patches:update
```

`.env`, build outputs, Vagrant state, and generated box files are intentionally ignored.
