# Pi-hole v6 for Debian 13 (trixie)

[![Daily build, scan and publish](https://github.com/dgcosenza/pihole-docker/actions/workflows/daily.yml/badge.svg)](https://github.com/dgcosenza/pihole-docker/actions/workflows/daily.yml)
[![Docker Hub pulls](https://img.shields.io/docker/pulls/dgcosenza/pihole.svg)](https://hub.docker.com/r/dgcosenza/pihole)
[![Image size](https://img.shields.io/docker/image-size/dgcosenza/pihole/latest.svg)](https://hub.docker.com/r/dgcosenza/pihole)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A hardened, continuously rebuilt **Debian 13 (trixie)** image of
[Pi-hole v6](https://pi-hole.net/), assembled from the official Pi-hole
components (Core, Web and FTL) and the official `docker-pi-hole` entrypoint.

It is a **drop-in replacement** for `pihole/pihole`: same environment
variables, same volumes, same ports, same healthcheck, same uid/gid defaults.
The difference is the platform underneath — Debian 13 with glibc, the Debian
security archive and a full `apt-get upgrade` on every build, instead of the
Alpine/musl base used by the official image.

Every image is rebuilt daily, smoke-tested, scanned with Trivy and Grype, and
published only when the build and the scans pass.

## Supported tags

| Tag | Meaning |
|---|---|
| `latest` | Newest successfully built and scanned image |
| `<pihole-version>` | Pi-hole release, e.g. `2026.11.0` (moves on rebuild of the same upstream release) |
| `<pihole-version>-<YYYYMMDD>` | Immutable date-stamped build of that release |
| `sha-<short>` | Immutable build of one repository commit |

`<pihole-version>` is the `pi-hole/docker-pi-hole` release the image tracks
(the Pi-hole suite version). The exact Core, Web and FTL versions resolved in a
given run are recorded in the build summary and in
[CHANGELOG.md](CHANGELOG.md).

Pin production deployments by digest:

```bash
docker pull dgcosenza/pihole:latest
docker inspect --format='{{index .RepoDigests 0}}' dgcosenza/pihole:latest
# image: dgcosenza/pihole@sha256:...
```

## Quick start

```bash
docker run -d --name pihole \
  --restart unless-stopped \
  --security-opt no-new-privileges:true \
  -p 53:53/tcp -p 53:53/udp \
  -p 80:80/tcp \
  -e TZ=Europe/Berlin \
  -e FTLCONF_webserver_api_password='change-me' \
  -v ./etc-pihole:/etc/pihole \
  -v ./etc-dnsmasq.d:/etc/dnsmasq.d \
  dgcosenza/pihole:latest
```

Open `http://<host>/admin/` and log in with the password you passed.

## Compose example

[docker-compose.example.yml](docker-compose.example.yml) is a complete
production-style example: LAN-only bindings, `no-new-privileges`, resource
limits, persistent configuration, and a paired Unbound resolver. See also
[dgcosenza/unbound](https://github.com/dgcosenza/unbound-docker) if you want a
local recursive resolver as Pi-hole's upstream.

## Configuration

### Ports

| Port | Protocol | Purpose |
|---|---|---|
| 53 | tcp/udp | DNS service |
| 80 | tcp | Web interface (FTL's embedded web server) |
| 443 | tcp | Web interface over TLS (when configured in `pihole.toml`) |
| 67 | udp | DHCP server (only when enabled) |
| 123 | udp | NTP server (`pihole-FTL` NTP, when enabled) |

Bind DNS to the interfaces you actually serve, not to `0.0.0.0`, unless the
host firewall restricts it.

### Volumes

| Path | Purpose |
|---|---|
| `/etc/pihole` | Configuration (`pihole.toml`), gravity database, local DNS records, TLS material |
| `/etc/dnsmasq.d` | Legacy/migration drop-in dnsmasq snippets (kept for v5 migrations) |
| `/var/log/pihole` | FTL, DNS and web logs (persist them if you need post-mortem data) |

### Environment variables

All variables understood by the official image are understood here, because the
entrypoint is the upstream one.

| Variable | Default | Description |
|---|---|---|
| `TZ` | `UTC` | Container timezone |
| `FTLCONF_webserver_api_password` | *(unset → random, printed once)* | Web admin password; hashed into `pihole.toml` on first start |
| `WEBPASSWORD_FILE` | *(unset)* | Read the password from `/run/secrets/<name>` instead of a variable |
| `FTLCONF_dns_upstreams` | `8.8.8.8, 8.8.4.4` | Upstream resolvers, e.g. `'172.20.0.10#53'` for Unbound |
| `FTLCONF_dns_listeningMode` | `local` | `all` is required when clients reach the container through NAT (bridge network, Tailscale) |
| `FTLCONF_dns_rateLimit_count` | `1000` | Queries per client per interval; `0` disables the limit (needed behind NAT) |
| `FTLCONF_dns_rateLimit_interval` | `60` | Rate-limit window in seconds |
| `FTLCONF_dns_revServers` | *(unset)* | Conditional forwarding, e.g. `'true,192.168.1.0/24,192.168.1.1,lan'` |
| `FTLCONF_*` | — | Any FTL setting can be set this way: the suffix is the dotted config key, e.g. `FTLCONF_dns_dnssec` |
| `PIHOLE_UID` / `PIHOLE_GID` | `1000` / `1000` | Remap the service account at start to match existing volume ownership |
| `DNSMASQ_USER` | `pihole` | User FTL drops to; `root` only if capabilities cannot be set |
| `FTL_CMD` | `no-daemon` | FTL invocation mode |
| `ADDITIONAL_PACKAGES` | *(unset)* | Extra Debian packages installed at container start (see below) |
| `TAIL_FTL_LOG` | `1` | Mirror FTL's log into `docker logs` |

`ADDITIONAL_PACKAGES` on this image runs `apt-get`, not `apk`. Packages are not
persisted across container recreation; install them at build time if you need
them permanently.

### UID / GID

The image ships a `pihole` user and group with uid/gid `1000`, matching the
official image. FTL runs as that user; the entrypoint runs as root only to fix
ownership and set capabilities. If your `/etc/pihole` volume belongs to another
uid/gid, set `PIHOLE_UID`/`PIHOLE_GID` instead of `chown`-ing the host.

### Capabilities

The container needs `CAP_NET_ADMIN` for DHCP and `CAP_SYS_NICE` so FTL can raise
its scheduling priority; DNS itself works with the default capability set. The
entrypoint detects which capabilities are available and only applies those.

## Healthcheck

```
dig -p $(pihole-FTL --config dns.port) +short +norecurse +retry=0 @127.0.0.1 pi.hole
```

Identical to the official image: it asks FTL for the configured DNS port and
resolves `pi.hole`, which only succeeds when the resolver is actually serving.
`--start-period` is 30 s. The check fails closed — if FTL dies, the container is
reported unhealthy within one interval.

## Upgrading and migrating from `pihole/pihole`

The image is designed for a like-for-like swap:

1. Back up `/etc/pihole` (or run **Settings → Teleporter → Export**).
2. Stop the old container.
3. Replace the image reference in your compose file with
   `dgcosenza/pihole:<version>@sha256:<digest>`.
4. `docker compose up -d pihole`.

Your `pihole.toml`, gravity database, blocklists, local DNS records and TLS
certificates are read as-is: the config schema is FTL's, not the image's. No
migration step and no `setupVars.conf` regeneration is required when moving from
the official v6 image.

If you are still on Pi-hole v5 (`setupVars.conf`), the entrypoint performs the
same automatic v5 → v6 migration as the official image.

Rollback is the same operation in reverse: point the compose file back at
`pihole/pihole:<old-tag>` and start it. Keep the backup until DNS is verified.

### Differences you should know about

* **Base OS**: Debian 13 (glibc) instead of Alpine (musl). This is the point of
  the image; it changes the package names available to `ADDITIONAL_PACKAGES`
  and the `crond` implementation used for `pihole updateGravity` and the update
  checker (Debian `cron` instead of BusyBox `crond`).
* **Package manager**: `ADDITIONAL_PACKAGES` uses `apt-get`.
* **Image size**: larger than the Alpine image (glibc + Debian base).
* **Everything else** — FTL binary, Core scripts, Web UI, entrypoint, env vars,
  volumes, ports, healthcheck — is the unmodified upstream release.

## Security

* Base image is `debian:trixie-slim`, fully upgraded (`apt-get upgrade`) at every
  build; only `--no-install-recommends` packages are installed and apt lists are
  removed.
* FTL is the official statically linked release binary, verified twice at build
  time: against the SHA-1 published in the GitHub release and against the
  SHA-256 pinned in the Dockerfile. Core and Web are cloned from their official
  release tags over TLS. The PADD script is pinned by commit and verified by
  SHA-256. The MAC vendor database is verified by pinned SHA-256.
* FTL runs as the unprivileged `pihole` user; the container does not use
  `privileged: true`. `no-new-privileges` is supported and recommended (see the
  compose example).
* No secrets are baked into layers. The web password is supplied at runtime and
  stored hashed by FTL in `pihole.toml`.
* **Scan policy**: every build is scanned with Trivy and Grype. The build fails
  on any **fixable CRITICAL or HIGH** finding (OS packages and language
  libraries). Reports are attached to each workflow run as artifacts; Trivy
  results are also uploaded to GitHub code scanning.
* Current status is reported by the badge at the top of this file and by the
  artifacts of the latest run. Unfixed findings that cannot be resolved upstream
  are listed here when they appear.

## Building locally

```bash
git clone https://github.com/dgcosenza/pihole-docker.git
cd pihole-docker
docker build -t dgcosenza/pihole:dev .
IMAGE=dgcosenza/pihole:dev tests/smoke.sh
```

Build arguments (all have documented defaults in the `Dockerfile`):

| Argument | Default | Meaning |
|---|---|---|
| `PIHOLE_DOCKER_VERSION` | tracked release | `docker-pi-hole` tag supplying the entrypoint |
| `PIHOLE_CORE_VERSION` | tracked release | `pi-hole/pi-hole` tag |
| `PIHOLE_WEB_VERSION` | tracked release | `pi-hole/web` tag |
| `FTL_VERSION` | tracked release | `pi-hole/FTL` tag |
| `FTL_SHA256` | pinned | SHA-256 of `pihole-FTL-amd64` for `FTL_VERSION` |
| `PADD_COMMIT` / `PADD_SHA256` | pinned | PADD script revision and digest |
| `MACVENDOR_SHA256` | pinned | Digest of `macvendor.db` |
| `PIHOLE_UID` / `PIHOLE_GID` | `1000` | Service account ids |
| `IMAGE_CREATED`, `IMAGE_REVISION`, `IMAGE_SOURCE` | empty / repo | OCI metadata |

If you change `FTL_VERSION`, update `FTL_SHA256` too (the release publishes only
SHA-1; compute the SHA-256 once and pin it).

## Update policy

A GitHub Actions workflow runs **daily** (and on every push to `main`, on pull
requests, and on demand):

1. resolves the latest `pi-hole/docker-pi-hole`, Core, Web and FTL releases via
   the authenticated GitHub API (never unauthenticated);
2. builds the image with those versions (`no-cache` on scheduled runs);
3. runs the smoke test above;
4. runs Trivy (blocking gate) and Grype, uploads reports and an SBOM;
5. publishes `latest`, `<version>`, `<version>-<YYYYMMDD>` and `sha-<short>` —
   only for non-PR events and only when Docker Hub credentials are configured.

Debian security updates therefore reach the image within a day of publication,
and a new Pi-hole release is picked up automatically.

## Design decisions

* **Debian 13 instead of Alpine.** The official image is Alpine-based, which is
  the upstream-documented base for that image. This build deliberately chooses
  the distro used by the rest of the fleet so that base packages, CVE feeds and
  upgrade tooling are uniform, and so the image can share one process/security
  model with the other services on the same host. The compatibility cost is the
  package-manager and cron differences documented above; the entrypoint itself
  is upstream code with a two-hunk patch
  ([`patches/0001-debian-gnu-userland.patch`](patches/0001-debian-gnu-userland.patch)).
* **Upstream entrypoint, not a reimplementation.** `start.sh`,
  `bash_functions.sh`, `prefix-time.sh` and `crontab.txt` are fetched from the
  pinned `docker-pi-hole` release and patched at build time. If upstream changes
  them in a way that breaks the patch, the build fails instead of silently
  drifting.
* **`start.sh` as PID 1.** Upstream's entrypoint already traps `SIGTERM`/
  `SIGINT`, stops FTL gracefully, waits for its children and propagates the exit
  code, so no extra init process is added (matching upstream behaviour).
* **Official FTL binary.** Building FTL from source would add a large C
  toolchain to the supply chain for no runtime benefit; the released binary is
  static and verified twice at build time.
* **Non-root FTL with capabilities.** Same model as upstream: root only for
  setup, FTL under `pihole` with an explicit capability set.

## License

The packaging in this repository is **MIT** (see [LICENSE](LICENSE)). The
software it installs keeps its own licenses:

* Pi-hole Core and FTL: **EUPL-1.2**
* Pi-hole Web: **MIT**
* PADD: **EUPL-1.2**

See [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md). No upstream component
forbids redistribution; the image contains only official release artifacts and
no proprietary code.

Pi-hole is a trademark of the Pi-hole project. This image is an independent
build and is not endorsed by the Pi-hole project.

## Credits

* [Pi-hole](https://github.com/pi-hole/pi-hole) — Core
* [pi-hole/web](https://github.com/pi-hole/web) — Web interface
* [pi-hole/FTL](https://github.com/pi-hole/FTL) — DNS engine and embedded web server
* [pi-hole/docker-pi-hole](https://github.com/pi-hole/docker-pi-hole) — container entrypoint and conventions this image follows
* [pi-hole/PADD](https://github.com/pi-hole/PADD) — terminal dashboard
* Packaging and CI: [dgcosenza](https://github.com/dgcosenza)
