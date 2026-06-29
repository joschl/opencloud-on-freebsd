# FreeBSD Install

## Target

- FreeBSD 15.1 amd64
- external TLS reverse proxy
- OpenCloud service on port `9200`
- no native `pkg` yet

Proxy the full OpenCloud hostname to port `9200`.
`/wopi` and `/collaboration` are handled by the same process.

## Install

Input artifact:

```text
install-opencloud-<version>-freebsd-amd64.sh
install-opencloud-<version>-freebsd-amd64.sh.sha256
```

Verify checksum:

```sh
sha256 -c install-opencloud-<version>-freebsd-amd64.sh.sha256
```

Run installer:

```sh
sudo ./install-opencloud-<version>-freebsd-amd64.sh
```

Installed paths:

- `/usr/local/bin/opencloud`
- `/usr/local/etc/rc.d/opencloud`
- `/usr/local/etc/opencloud/opencloud.env`
- `/usr/local/etc/opencloud/*.sample`
- `/var/db/opencloud`
- `/var/log/opencloud`
- `/var/run/opencloud`

User/group:

- `opencloud`

## Configure

Edit before first start:

```sh
sudo vi /usr/local/etc/opencloud/opencloud.env
```

Required:

```sh
OC_URL=https://cloud.example.com
IDM_ADMIN_PASSWORD=replace-with-a-strong-password
```

Notes:

- `IDM_ADMIN_PASSWORD` is first-start only.
- `PROXY_TLS=false` assumes TLS terminates at the reverse proxy.
- config assets come from `opencloud-compose`.

## Run

```sh
sudo sysrc opencloud_enable=YES
sudo service opencloud start
sudo service opencloud status
```

Logs:

```text
/var/log/opencloud/opencloud.log
```

## Not Included

- native FreeBSD `pkg`
- Collabora
- Keycloak
- Tika
- ClamAV
- Radicale
- monitoring
