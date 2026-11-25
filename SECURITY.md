# Security policy

Maintainer: Daniel G. Cosenza from FNX Labs.

## Supported versions

Only the `latest` tag and the newest `<pihole-version>` tag are supported. The
image is rebuilt daily from `debian:trixie-slim` with a full `apt-get upgrade`,
so security fixes reach `latest` within a day of being published.

## Reporting a vulnerability

Open a private security advisory at
<https://github.com/dgcosenza/pihole-docker/security/advisories/new> or email the
maintainer listed in the repository profile. Please do not open a public issue
for an undisclosed vulnerability.

## What this repository covers

This repository owns the packaging layer: the Dockerfile, the Debian adaptation
patch for the upstream entrypoint, the CI pipeline and the published tags.
Vulnerabilities in Pi-hole itself (FTL, Core, Web) should also be reported
upstream at <https://github.com/pi-hole/FTL/security> or
<https://github.com/pi-hole/pi-hole/security>; this image picks up upstream
fixes automatically on the next daily build.

## Scanning and gates

* Trivy: the build fails on any **fixable CRITICAL or HIGH** finding in OS
  packages or bundled libraries. Results are uploaded to GitHub code scanning
  and kept as a workflow artifact.
* Grype: run on every build, report kept as a workflow artifact.
* SBOM: SPDX JSON generated with Syft and attached to each run.
* The image runs FTL as the unprivileged `pihole` user; root is used only by the
  entrypoint for ownership and capability setup.
* No secrets are stored in image layers; the web password is provided at runtime
  and stored hashed by FTL.

## Hardening recommendations

* Pin the image by `@sha256:<digest>`.
* Run with `security_opt: [no-new-privileges:true]`.
* Grant only `CAP_NET_ADMIN` (DHCP) and `CAP_SYS_NICE` (priority) if you need
  them; DNS works with the default capability set.
* Bind DNS and the web UI to the interfaces that should serve them.
* Keep `/etc/pihole` backed up (Settings → Teleporter) before upgrades.
