# Third-party notices

This image installs or embeds the following upstream components. They are
distributed under their own licenses; the MIT license of this repository covers
only the packaging (Dockerfile, CI, documentation, smoke test).

| Component | Version | License | Source |
|---|---|---|---|
| Pi-hole Core (`pihole/pi-hole`) | v6.6 | EUPL-1.2 | https://github.com/pi-hole/pi-hole |
| Pi-hole Web (`pihole/web`) | v6.6.1 | MIT | https://github.com/pi-hole/web |
| Pi-hole FTL (`pihole/FTL`) | v6.9 | EUPL-1.2 | https://github.com/pi-hole/FTL |
| docker-pi-hole entrypoint (`pihole/docker-pi-hole`) | 2026.11.0 | EUPL-1.2 | https://github.com/pi-hole/docker-pi-hole |
| PADD (`pihole/PADD`) | commit `3600b2e` | EUPL-1.2 | https://github.com/pi-hole/PADD |
| MAC vendor database | 2026-11 | distributed by the Pi-hole project | https://ftl.pi-hole.net/macvendor.db |
| Debian 13 packages | trixie | individual Debian licenses (DFSG) | https://www.debian.org/ |

Notes:

* None of the upstream licenses forbids redistribution in a container image.
  Pi-hole Core, FTL and PADD are licensed under the European Union Public
  Licence v1.2 (EUPL-1.2), which permits redistribution provided the license and
  copyright notices are preserved — they remain intact inside the image
  (`/etc/.pihole`, `/var/www/html/admin`, `/usr/bin/pihole-FTL`,
  `/usr/local/bin/padd`).
* The FTL binary is the unmodified release artifact, verified at build time
  against the upstream SHA-1 and the pinned SHA-256.
* Downloading these components is done at build time from the official release
  locations; no proprietary code is included.
* "Pi-hole" is a trademark of the Pi-hole project. This image is an independent
  build, not endorsed by or affiliated with the Pi-hole project.
