# FreeBSD pkg Roadmap

Goal: native FreeBSD port/pkg after the install layout is stable.

## Port Files

- `Makefile`
- `distinfo`
- `pkg-descr`
- `pkg-plist`
- `pkg-message`
- `files/opencloud.in`

## Port Defaults

- `USE_RC_SUBR=opencloud`
- `USERS=opencloud`
- `GROUPS=opencloud`
- config samples under `/usr/local/etc/opencloud`
- state under `/var/db/opencloud`
- logs under `/var/log/opencloud`
- pid under `/var/run/opencloud`

## Validation

- poudriere build
- rc script start/stop/status
- config sample preservation
- no generated state under `/usr/local`
- upgrade path for `opencloud.env`
- upgrade path for `/var/db/opencloud`
