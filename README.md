# Pi-hole v6 for Debian 13 (trixie-slim)

[![Daily Pi-hole image](https://github.com/dgcosenza/pihole-docker/actions/workflows/daily.yml/badge.svg)](https://github.com/dgcosenza/pihole-docker/actions/workflows/daily.yml)
[![Packaging License: MIT](https://img.shields.io/badge/packaging-MIT-blue.svg)](https://github.com/dgcosenza/pihole-docker/blob/main/LICENSE)
[![Upstream License: EUPL-1.2](https://img.shields.io/badge/upstream-EUPL--1.2-green.svg)](https://github.com/pi-hole/pi-hole/blob/master/LICENSE)
[![Signed with Cosign](https://img.shields.io/badge/signed-cosign%20OIDC-blueviolet.svg)](#supply-chain-verification)
[![SLSA Level 3](https://img.shields.io/badge/SLSA-Level%203-brightgreen.svg)](#supply-chain-verification)
[![Architectures](https://img.shields.io/badge/arch-amd64%20%7C%20arm64-informational.svg)](#supported-architectures)
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/dgcosenza/pihole-docker/badge)](https://scorecard.dev/viewer/?uri=github.com/dgcosenza/pihole-docker)
[![Docker Pulls](https://img.shields.io/docker/pulls/dgcosenza/pihole)](https://hub.docker.com/r/dgcosenza/pihole)
[![Docker Image Size](https://img.shields.io/docker/image-size/dgcosenza/pihole/latest)](https://hub.docker.com/r/dgcosenza/pihole)
[![Latest Release](https://img.shields.io/github/v/release/dgcosenza/pihole-docker?label=version)](https://github.com/dgcosenza/pihole-docker/releases)

A hardened, multi-arch, continuously rebuilt **Debian 13 (`trixie-slim`)** container image of [Pi-hole v6](https://pi-hole.net/) (Core, Web, FTL, PADD, and the official `docker-pi-hole` entrypoint), maintained by **Daniel G. Cosenza from FNX Labs**.

- **Docker Hub:** [`dgcosenza/pihole`](https://hub.docker.com/r/dgcosenza/pihole)
- **GitHub Container Registry (GHCR):** [`ghcr.io/dgcosenza/pihole`](https://github.com/dgcosenza/pihole-docker/pkgs/container/pihole) (identical signed multi-arch digest)
- **Source Repository:** [`dgcosenza/pihole-docker`](https://github.com/dgcosenza/pihole-docker)
- **Upstream Application:** [`pi-hole/pi-hole`](https://github.com/pi-hole/pi-hole) / [`pi-hole/FTL`](https://github.com/pi-hole/FTL) (`EUPL-1.2`), [`pi-hole/web`](https://github.com/pi-hole/web) (`MIT`)

---

## Overview

`dgcosenza/pihole` is a **drop-in replacement** for `pihole/pihole` built for both `linux/amd64` and `linux/arm64`:

- **Full behavioral parity:** Same environment variables (`FTLCONF_*`, `WEBPASSWORD_FILE`, `PIHOLE_UID`/`PIHOLE_GID`), same volumes (`/etc/pihole`, `/etc/dnsmasq.d`, `/var/log/pihole`), same ports, same healthcheck, and same unprivileged `pihole` (`1000:1000`) FTL runtime account.
- **Debian 13 (`trixie-slim`) underneath:** Uses glibc and daily `apt-get upgrade` security updates instead of Alpine/musl, with only a minimal two-hunk patch (`patches/0001-debian-gnu-userland.patch`) adapting `ADDITIONAL_PACKAGES` and `cron`.
- **Hardened supply chain:** Hadolint + Gitleaks preflight, native multi-arch smoke tests, strict Dive efficiency gate (`>= 95%`, `<= 5%` wasted), Syft SPDX + CycloneDX SBOMs, Trivy + Grype (SBOM) zero-fixable High/Critical gates, Cosign keyless OIDC signatures & SBOM attestations, SLSA Build L3 provenance, dual-registry publishing, and signed GitHub Releases.

---

## Current Versions

<!-- versions:start -->
| Component | Resolved Version |
| --- | --- |
| docker-pi-hole | `2026.11.0` |
| pi-hole-core | `v6.6` |
| pi-hole-web | `v6.6.1` |
| pi-hole-ftl | `v6.9` |
| padd | `3600b2e03999` |
| Base OS | `Debian 13.8 (trixie-slim)` |
| Architectures | `linux/amd64, linux/arm64` |
| Compressed size (per arch) | `amd64: 102.7 MB, arm64: 103.4 MB` |
| Last verified build (UTC) | `2026-11-26` |
| Published multi-arch digest | `dgcosenza/pihole@sha256:f44a2304c217080137a8add3852e77a9293714fc504215f9f7b0d2ae0c40e734` |
| GHCR mirror | `ghcr.io/dgcosenza/pihole@sha256:f44a2304c217080137a8add3852e77a9293714fc504215f9f7b0d2ae0c40e734` |
| Supply chain | Cosign OIDC signed + SPDX & CycloneDX SBOM attestations + SLSA Build L3 provenance |
| Security gate (Trivy + Grype on SBOM) | **0 fixable findings of any severity** (37 upstream-unfixed) |

Currently tracked upstream-unfixed findings (no fix released): `CVE-2019-16224`, `CVE-2019-16225`, `CVE-2019-16226`, `CVE-2019-16227`, `CVE-2019-16228`, `CVE-2025-69720`, `CVE-2026-105437`, `CVE-2026-107494`, `CVE-2026-111760`, `CVE-2026-113351` (+27 more in CI artifacts).
<!-- versions:end -->

---

## Supported Tags & Tag Policy

Identical multi-arch OCI digests are published to **Docker Hub** (`dgcosenza/pihole`) and **GHCR** (`ghcr.io/dgcosenza/pihole`), accompanied by an automated signed [GitHub Release](https://github.com/dgcosenza/pihole-docker/releases):

| Tag | Policy | Description |
| --- | --- | --- |
| `<version>-<YYYYMMDD>` (e.g. `2026.11.0-20261125`) | **Immutable** | Date-stamped daily rebuild pinning the Pi-hole suite release and UTC build date. |
| `sha-<short>` | **Immutable** | Packaging repository Git commit tag. |
| `<version>` (e.g. `2026.11.0`) | Moving | Latest verified Debian 13 security rebuild of that `docker-pi-hole` release. |
| `latest` | Moving | Latest verified build tracking the newest official Pi-hole release. |

**Production pinning:** Always pin by immutable digest:

```yaml
image: dgcosenza/pihole:2026.11.0@sha256:<digest>
# or via GitHub Container Registry (identical digest):
image: ghcr.io/dgcosenza/pihole:2026.11.0@sha256:<digest>
```

---

## Supported Architectures

| Architecture | Status | Verification |
| --- | --- | --- |
| `linux/amd64` | **Published & natively tested** | Official `pihole-FTL-amd64` verified by SHA-1 + SHA-256, smoke-tested, Dive-gated, Syft/Trivy/Grype-scanned, and Cosign-signed on native x86_64 CI runners. |
| `linux/arm64` | **Published & natively tested** | Official `pihole-FTL-arm64` verified by SHA-1 + SHA-256, smoke-tested, Dive-gated, Syft/Trivy/Grype-scanned, and Cosign-signed on native ARM64 CI runners. |

---

## Quick Start

### `docker run`

```bash
docker run -d --name pihole \
  --restart unless-stopped \
  --cap-drop ALL \
  --cap-add NET_BIND_SERVICE \
  --cap-add NET_ADMIN \
  --cap-add NET_RAW \
  --cap-add SYS_NICE \
  --cap-add CHOWN \
  --cap-add SETUID \
  --cap-add SETGID \
  --cap-add DAC_OVERRIDE \
  --cap-add FOWNER \
  --cap-add AUDIT_WRITE \
  --security-opt no-new-privileges:true \
  --tmpfs /tmp:noexec,nosuid,size=64m \
  -p 192.0.2.10:53:53/tcp -p 192.0.2.10:53:53/udp \
  -p 192.0.2.10:80:80/tcp \
  -e TZ=Etc/UTC \
  -e FTLCONF_webserver_api_password='change-me' \
  -v ./etc-pihole:/etc/pihole \
  -v ./etc-dnsmasq.d:/etc/dnsmasq.d \
  dgcosenza/pihole:latest
```

Open `http://192.0.2.10/admin/` and log in with the configured password.

### Hardened Docker Compose

See [`docker-compose.example.yml`](https://github.com/dgcosenza/pihole-docker/blob/main/docker-compose.example.yml) for a complete production-style compose file with `cap_drop: [ALL]`, minimal `cap_add`, `no-new-privileges:true`, `/tmp` `tmpfs`, resource limits, and a paired [`dgcosenza/unbound`](https://github.com/dgcosenza/unbound-docker) recursive resolver.

---

## Configuration

### Ports

| Port | Protocol | Purpose |
| --- | --- | --- |
| `53` | TCP / UDP | DNS service |
| `80` | TCP | Web interface (FTL embedded web server) |
| `443` | TCP | Web interface over TLS (when configured in `pihole.toml`) |
| `67` | UDP | DHCP server (only when enabled) |
| `123` | UDP | NTP server (`pihole-FTL` NTP, when enabled) |

Bind DNS to the interfaces you serve rather than `0.0.0.0`, unless host firewall rules restrict external access.

### Volumes

| Path | Purpose |
| --- | --- |
| `/etc/pihole` | Configuration (`pihole.toml`), gravity database, local DNS records, TLS material |
| `/etc/dnsmasq.d` | Legacy/migration drop-in dnsmasq snippets |
| `/var/log/pihole` | FTL, DNS, and web logs |

### Environment Variables

| Variable | Default | Description |
| --- | --- | --- |
| `TZ` | `UTC` | Container timezone |
| `FTLCONF_webserver_api_password` | *(random on first start)* | Web admin password; hashed into `pihole.toml` |
| `WEBPASSWORD_FILE` | *(unset)* | Read password from `/run/secrets/<name>` instead of an env var |
| `FTLCONF_dns_upstreams` | `8.8.8.8, 8.8.4.4` | Upstream resolvers, e.g. `172.20.0.10#53` for Unbound |
| `FTLCONF_dns_listeningMode` | `local` | Set `all` when clients reach the container through NAT/bridge/VPN |
| `FTLCONF_dns_rateLimit_count` | `1000` | Queries per client per interval (`0` disables behind NAT) |
| `FTLCONF_dns_rateLimit_interval` | `60` | Rate-limit window in seconds |
| `FTLCONF_dns_revServers` | *(unset)* | Conditional forwarding, e.g. `true,192.0.2.0/24,192.0.2.1,lan` |
| `FTLCONF_*` | — | Any FTL setting mapped to dotted `pihole.toml` keys |
| `PIHOLE_UID` / `PIHOLE_GID` | `1000` / `1000` | Remap service account IDs at start to match host volume ownership |
| `DNSMASQ_USER` | `pihole` | Unprivileged account FTL drops to |
| `FTL_CMD` | `no-daemon` | FTL invocation mode |
| `ADDITIONAL_PACKAGES` | *(unset)* | Extra Debian packages installed via `apt-get` at startup |
| `TAIL_FTL_LOG` | `1` | Mirror FTL logs to container stdout |

### UID / GID & Capabilities

`pihole` (`1000:1000`) runs `pihole-FTL`. The upstream entrypoint starts briefly as root to reconcile `/etc/pihole` ownership, start `cron`, and apply capabilities before dropping `pihole-FTL` to `pihole`. `no-new-privileges:true` and explicit `cap_drop: [ALL]` + minimal `cap_add` are supported without `privileged: true`.

---

## Healthcheck

```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD dig -p "$(pihole-FTL --config dns.port)" +short +norecurse +retry=0 @127.0.0.1 pi.hole || exit 1
```

Queries FTL directly on its configured DNS port for `pi.hole` and fails closed whenever FTL is unresponsive.

---

## Upgrading and Migrating from `pihole/pihole`

1. Back up `/etc/pihole` (or use **Settings → Teleporter → Export**).
2. Replace `pihole/pihole:<tag>` in your compose file with `dgcosenza/pihole:<version>@sha256:<digest>` (or `ghcr.io/dgcosenza/pihole:<version>@sha256:<digest>`).
3. Run `docker compose up -d pihole`.
4. Confirm `healthy` status, DNS resolution (`dig @127.0.0.1 pi.hole`), and the `/admin/` UI.

`pihole.toml`, `gravity.db`, blocklists, local DNS entries, and v5-to-v6 migrations work identically. Note that `ADDITIONAL_PACKAGES` uses Debian `apt-get` rather than Alpine `apk`, and scheduled gravity/update jobs run under Debian `cron`.

---

## Supply-Chain Verification

Every published digest (multi-arch index and per-architecture manifests) on both Docker Hub and GHCR is keyless-signed with **Sigstore Cosign** (GitHub OIDC), attested with **SPDX** and **CycloneDX** SBOMs, and backed by **SLSA Build L3** provenance (`actions/attest-build-provenance`).

### Verify image signature with Cosign

```bash
cosign verify \
  --certificate-identity-regexp="^https://github\.com/dgcosenza/pihole-docker/\.github/workflows/daily\.yml@refs/heads/main$" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
  ghcr.io/dgcosenza/pihole:latest

# Or against Docker Hub (identical digest):
cosign verify \
  --certificate-identity-regexp="^https://github\.com/dgcosenza/pihole-docker/\.github/workflows/daily\.yml@refs/heads/main$" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
  dgcosenza/pihole:latest
```

### Verify SPDX / CycloneDX SBOM attestations

```bash
cosign verify-attestation \
  --type spdxjson \
  --certificate-identity-regexp="^https://github\.com/dgcosenza/pihole-docker/\.github/workflows/daily\.yml@refs/heads/main$" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
  ghcr.io/dgcosenza/pihole@sha256:<arch-digest>
```

### Verify SLSA Build Provenance

```bash
gh attestation verify oci://ghcr.io/dgcosenza/pihole:latest --owner dgcosenza
```

---

## Security

- **Preflight gates:** Every push and PR runs **Hadolint** (blocking on warning+), **Gitleaks** secret scanning across full git history, and **public-content/attribution/license** checks.
- **Artifact integrity:** Both `pihole-FTL-amd64` and `pihole-FTL-arm64` are verified against upstream SHA-1 digests and pinned SHA-256 checksums; `padd.sh` and `macvendor.db` are SHA-256 verified; Core and Web are cloned from signed/tagged upstream releases.
- **Vulnerability & efficiency gates (all severities with a fix):** Each architecture generates **Syft** SPDX + CycloneDX SBOMs, passes a strict **Dive** efficiency gate (`>= 95%`, `<= 5%` wasted), and must pass **Trivy** (table, JSON, SARIF to Code Scanning, blocking `--ignore-unfixed`) and **Grype** scanning the SPDX SBOM (`--only-fixed --fail-on negligible`) with **0 fixable findings of any severity** vulnerabilities.
- **Dependency automation:** Renovate (`renovate.json`) pins base image digests and GitHub Action commit SHAs; Dependabot security alerts and OpenSSF Scorecard monitoring are enabled.
- See [`SECURITY.md`](https://github.com/dgcosenza/pihole-docker/blob/main/SECURITY.md) for vulnerability reporting.

---

## Build Locally

```bash
git clone https://github.com/dgcosenza/pihole-docker.git
cd pihole-docker

docker buildx build \
  --platform linux/amd64 \
  --load \
  --build-arg IMAGE_CREATED="$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --build-arg IMAGE_REVISION="$(git rev-parse HEAD)" \
  -t dgcosenza/pihole:local \
  .

./tests/smoke.sh dgcosenza/pihole:local
```

| Build Arg | Default | Purpose |
| --- | --- | --- |
| `DEBIAN_BASE` | `debian:trixie-slim@sha256:...` | Digest-pinned Debian 13 base image (refreshed daily by CI) |
| `PIHOLE_DOCKER_VERSION` | `2026.11.0` | `pi-hole/docker-pi-hole` release tag supplying the entrypoint |
| `PIHOLE_CORE_VERSION` | `v6.6` | `pi-hole/pi-hole` release tag |
| `PIHOLE_WEB_VERSION` | `v6.6.1` | `pi-hole/web` release tag |
| `FTL_VERSION` | `v6.9` | `pi-hole/FTL` release tag |
| `FTL_SHA256_AMD64` / `FTL_SHA256_ARM64` | pinned | Verified SHA-256 digests of `pihole-FTL-{amd64,arm64}` |
| `PADD_COMMIT` / `PADD_SHA256` | pinned | PADD commit and SHA-256 |
| `MACVENDOR_SHA256` | pinned | SHA-256 of `macvendor.db` |
| `PIHOLE_UID` / `PIHOLE_GID` | `1000` / `1000` | Unprivileged `pihole` service account IDs |

---

## Update Policy

[`.github/workflows/daily.yml`](https://github.com/dgcosenza/pihole-docker/blob/main/.github/workflows/daily.yml) runs automatically every day at **05:10 UTC**, on pushes to `main`, on pull requests (verification only), and via `workflow_dispatch`:

1. **Preflight & upstream check:** Runs public-content checks, **Hadolint**, and **Gitleaks**; resolves the latest `docker-pi-hole`, Core, Web, FTL (verifying both `amd64` and `arm64` checksums), PADD, `macvendor.db`, and `debian:trixie-slim` digest via the authenticated GitHub API; diffs against `versions.json` and emits `upstream-changes.md`.
2. **Multi-arch no-cache rebuild:** Builds natively on `linux/amd64` and `linux/arm64` runners with `--no-cache` on schedule and full `apt-get upgrade` on Debian 13.
3. **Smoke, Dive & vulnerability gates:** Runs [`tests/smoke.sh`](https://github.com/dgcosenza/pihole-docker/blob/main/tests/smoke.sh) natively on both architectures, enforces the strict **Dive** efficiency gate (`>= 95%`, `<= 5%` wasted), generates **Syft** SPDX + CycloneDX SBOMs per arch, and gates publication on **0 fixable findings of any severity** in both **Trivy** and **Grype** (SBOM scan).
4. **Dual-registry publish & signing:** Assembles the multi-arch OCI index on **GHCR** (`ghcr.io/dgcosenza/pihole`) and mirrors the identical digest to **Docker Hub** (`dgcosenza/pihole`) with tags `latest`, `<version>`, `<version>-<YYYYMMDD>`, and `sha-<short>`; keyless-signs digests and attaches SPDX/CycloneDX SBOM attestations via **Cosign** OIDC; emits **SLSA Build L3** provenance; and publishes a signed **GitHub Release** with checksums, Cosign bundle, and SBOMs.
5. **Automated documentation sync:** Commits updated `versions.json`, the README `Current Versions` block, and a dated `CHANGELOG.md` entry via `github-actions[bot]` (`[skip ci]`), then syncs the Docker Hub repository overview and short description.
6. **Failure alerting:** Opens or updates a single GitHub issue labeled `ci-failure` on any `main` or scheduled failure, and automatically closes it on the next green run.

---

## Design Decisions

- **Debian 13 (`trixie-slim`) instead of Alpine:** Aligns libc, CA trust, and daily security patching with Debian 13 while preserving upstream Pi-hole scripts via a minimal two-hunk patch (`patches/0001-debian-gnu-userland.patch`).
- **Two-layer zero-waste runtime layout:** Upgrading Debian 13 inside an `os-base` stage and assembling the final image with cleanly separated OS and application layers eliminates overwritten base-layer bloat (~5+ MB) so Dive stays at ~100% efficiency and ~0% wasted space across every daily Debian security update.
- **Official FTL static binaries for both architectures:** Dual-verified (`SHA-1` + `SHA-256`) official `pihole-FTL-amd64` and `pihole-FTL-arm64` binaries avoid bundling a C build toolchain while maintaining exact upstream parity.
- **Hadolint `DL3008` ignore:** Daily `--no-cache` security rebuilds intentionally pull the newest Debian 13 security updates via `apt-get` rather than pinning stale package versions.

---

## License

This repository follows a clear packaging-vs-upstream license split:

- **Container packaging, patch, CI workflows, scripts, and documentation (`packaging: MIT`):** Licensed under the [MIT License](https://github.com/dgcosenza/pihole-docker/blob/main/LICENSE) — copyright **Daniel G. Cosenza from FNX Labs**.
- **Bundled upstream software — Pi-hole (`upstream: EUPL-1.2`):** Pi-hole Core, FTL, `docker-pi-hole`, and PADD are licensed under the [European Union Public License v1.2 (`EUPL-1.2`)](https://github.com/pi-hole/pi-hole/blob/master/LICENSE); Pi-hole Web is licensed under the [MIT License](https://github.com/pi-hole/web/blob/master/LICENSE).

Full notices are preserved inside the image (`/usr/share/doc/pihole-notices/`) and in [`THIRD-PARTY-NOTICES.md`](https://github.com/dgcosenza/pihole-docker/blob/main/THIRD-PARTY-NOTICES.md). Pi-hole is a trademark of the Pi-hole project; this image is an independent build and is not endorsed by the Pi-hole project.

---

## Credits

- [Pi-hole](https://github.com/pi-hole/pi-hole), [pi-hole/web](https://github.com/pi-hole/web), [pi-hole/FTL](https://github.com/pi-hole/FTL), [pi-hole/docker-pi-hole](https://github.com/pi-hole/docker-pi-hole), and [pi-hole/PADD](https://github.com/pi-hole/PADD)
- Container packaging, CI, and documentation: maintained by **Daniel G. Cosenza from FNX Labs** ([dgcosenza](https://github.com/dgcosenza))
