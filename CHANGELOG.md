# Changelog

Maintained by Daniel G. Cosenza from FNX Labs.

All notable changes to this image are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and
this project adheres to [Semantic Versioning](https://semver.org/) for the
packaging, while the image version tracks the upstream Pi-hole release.

## [2026.11.0] - 2026-11-26

### Automated Daily Build
- Verified components: docker-pi-hole `2026.11.0`, pi-hole-core `v6.6`, pi-hole-web `v6.6.1`, pi-hole-ftl `v6.9`, padd `3600b2e03999`, Base OS `Debian 13.8 (trixie-slim)`.
- Architectures verified: `linux/amd64, linux/arm64` (native smoke tests + Dive efficiency gate).
- Upstream status: refreshed base OS, dependencies, and supply-chain attestations.
- Vulnerability gate: **0 fixable findings of any severity** in Trivy and Grype (SBOM scan) (37 upstream-unfixed).
- Published multi-arch digest (Docker Hub + GHCR): `dgcosenza/pihole@sha256:9b00b239966908f261abc7722a8ea44ddf67b3376cbaf476492223aa549319cc` (Cosign OIDC signed + SPDX/CycloneDX SBOM + SLSA L3 provenance).
## [2026.11.0] - 2026-11-25

### Automated Daily Build
- Verified components: docker-pi-hole `2026.11.0`, pi-hole-core `v6.6`, pi-hole-web `v6.6.1`, pi-hole-ftl `v6.9`, padd `3600b2e03999`, Base OS `Debian 13.8 (trixie-slim)`.
- Architectures verified: `linux/amd64, linux/arm64` (native smoke tests + Dive efficiency gate).
- Upstream status: refreshed base OS, dependencies, and supply-chain attestations.
- Vulnerability gate: **0 fixable Critical/High** in Trivy and Grype (SBOM scan) (37 upstream-unfixed).
- Published multi-arch digest (Docker Hub + GHCR): `dgcosenza/pihole@sha256:959e9043ae296a18768108bd856f4194681b0f2819d67807a0b441f352c43807` (Cosign OIDC signed + SPDX/CycloneDX SBOM + SLSA L3 provenance).
## [2026.11.0] - 2026-11-25

### Changed

- Rebuilt on Debian `13.8` (`debian:trixie-slim`) with docker-pi-hole `2026.11.0`, pi-hole-core `v6.6`, pi-hole-web `v6.6.1`, pi-hole-ftl `v6.9`, padd `3600b2e03999`.
- Verified `0` fixable CRITICAL/HIGH vulnerabilities in Trivy and Grype.
- Published digest: `dgcosenza/pihole@sha256:76b51e041688e25810b94e7405d5d377e775be9ee9bb4ba17ebacbb796810151`.
## [2026.11.0] - 2026-11-24

### Added

- Initial public build: Pi-hole v6 on Debian 13 (trixie) slim.
- Upstream components pinned by release tag: docker-pi-hole `2026.11.0`,
  Core `v6.6`, Web `v6.6.1`, FTL `v6.9`.
- Drop-in compatibility with `pihole/pihole`: same entrypoint, environment
  variables, volumes, ports, healthcheck and uid/gid defaults.
- Debian adaptation patch for the upstream entrypoint
  (`patches/0001-debian-gnu-userland.patch`): `apt-get` for
  `ADDITIONAL_PACKAGES` and Debian `cron` instead of BusyBox `crond`.
- FTL release binary verified against the upstream SHA-1 and a pinned SHA-256;
  PADD and the MAC vendor database verified by pinned SHA-256.
- Daily GitHub Actions pipeline: version resolution via authenticated GitHub
  API, build, smoke test (DNS, web UI, non-root FTL, negative test), Trivy
  blocking gate plus SARIF, Grype, SBOM, digest-pinned publishing and Docker Hub
  description sync.
- Documented security posture, supported tags and rollback procedure.
