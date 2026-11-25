# Changelog

All notable changes to this image are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and
this project adheres to [Semantic Versioning](https://semver.org/) for the
packaging, while the image version tracks the upstream Pi-hole release.

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
