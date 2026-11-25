# syntax=docker/dockerfile:1

# ---------------------------------------------------------------------------
# Pi-hole v6 (FTL + Core + Web) on Debian 13 (trixie) slim.
#
# The official pi-hole/pihole image is Alpine-based. This image rebuilds the
# exact same upstream components (Core, Web, FTL and the docker-pi-hole
# entrypoint) on Debian 13 so that it shares the distro, libc and security
# patch stream of the other images in this collection. The only behavioural patch applied to
# the upstream entrypoint is the package manager and the cron daemon call
# (see patches/0001-debian-gnu-userland.patch).
#
# Every version below is a documented default; CI overrides them with the
# latest upstream releases on each run (see .github/workflows/daily.yml).
# ---------------------------------------------------------------------------

ARG DEBIAN_VERSION=trixie-slim

# docker-pi-hole release that supplies start.sh / bash_functions.sh / crontab
ARG PIHOLE_DOCKER_VERSION=2026.11.0
# pi-hole component releases
ARG PIHOLE_CORE_VERSION=v6.6
ARG PIHOLE_WEB_VERSION=v6.6.1
ARG FTL_VERSION=v6.9
# SHA-256 of pihole-FTL-amd64 for FTL_VERSION (upstream publishes SHA-1 only)
ARG FTL_SHA256=8203d625fa1ee889710471b8f9b8a991fd6dddb4ca6a923d1ff43db47660865d
# PADD (Pi-hole Ad-blocking Dashboard) pinned commit + SHA-256 of padd.sh
ARG PADD_COMMIT=3600b2e0399967219ae998561bb474d8c169e432
ARG PADD_SHA256=67fb9cc219be1758825d04cc19d85d454fc91a856edbd2f7787d52f62332e01b
# MAC vendor database published by the Pi-hole project (no upstream checksum)
ARG MACVENDOR_SHA256=e07d5a2ac56c7b23582c174272c8cbb785859680e843c1295cb8b8726cfc3ac0

ARG PIHOLE_UID=1000
ARG PIHOLE_GID=1000

ARG IMAGE_CREATED=""
ARG IMAGE_REVISION=""
ARG IMAGE_SOURCE="https://github.com/dgcosenza/pihole-docker"

# ---- Stage 1: fetch the upstream container entrypoint at the pinned release --
FROM debian:${DEBIAN_VERSION} AS entrypoint

ARG PIHOLE_DOCKER_VERSION

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl patch \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /scripts

# Fetch first, patch second: if upstream changes the context of the Debian
# adaptations the build fails loudly instead of silently drifting.
RUN set -eux; \
    base="https://raw.githubusercontent.com/pi-hole/docker-pi-hole/${PIHOLE_DOCKER_VERSION}/src"; \
    for f in start.sh bash_functions.sh prefix-time.sh crontab.txt; do \
        curl -fsSL --retry 3 "$base/$f" -o "$f"; \
    done

COPY patches/ /patches/
RUN patch -p1 -d /scripts < /patches/0001-debian-gnu-userland.patch

# ---- Stage 2: hardened Debian 13 runtime ------------------------------------
FROM debian:${DEBIAN_VERSION}

ARG PIHOLE_DOCKER_VERSION
ARG PIHOLE_CORE_VERSION
ARG PIHOLE_WEB_VERSION
ARG FTL_VERSION
ARG FTL_SHA256
ARG PADD_COMMIT
ARG PADD_SHA256
ARG MACVENDOR_SHA256
ARG PIHOLE_UID
ARG PIHOLE_GID
ARG IMAGE_CREATED
ARG IMAGE_REVISION
ARG IMAGE_SOURCE

LABEL org.opencontainers.image.title="Pi-hole v6 (Debian 13)" \
      org.opencontainers.image.description="Hardened, up-to-date Debian 13 (trixie) build of Pi-hole v6 (FTL, Core and Web), drop-in compatible with pihole/pihole." \
      org.opencontainers.image.url="https://hub.docker.com/r/dgcosenza/pihole" \
      org.opencontainers.image.source="${IMAGE_SOURCE}" \
      org.opencontainers.image.documentation="${IMAGE_SOURCE}#readme" \
      org.opencontainers.image.version="${PIHOLE_DOCKER_VERSION}" \
      org.opencontainers.image.revision="${IMAGE_REVISION}" \
      org.opencontainers.image.created="${IMAGE_CREATED}" \
      org.opencontainers.image.licenses="EUPL-1.2" \
      org.opencontainers.image.vendor="FNX Labs" \
      org.opencontainers.image.authors="Daniel Cosenza (dgcosenza)" \
      io.github.dgcosenza.pihole.upstream_image="pihole/pihole" \
      io.github.dgcosenza.pihole.upstream_version="${PIHOLE_DOCKER_VERSION}" \
      io.github.dgcosenza.pihole.core_version="${PIHOLE_CORE_VERSION}" \
      io.github.dgcosenza.pihole.web_version="${PIHOLE_WEB_VERSION}" \
      io.github.dgcosenza.pihole.ftl_version="${FTL_VERSION}" \
      io.github.dgcosenza.pihole.base="debian:${DEBIAN_VERSION}"

ENV DEBIAN_FRONTEND=noninteractive

# The full Debian 13 package set is upgraded at build time so a rebuild picks up
# security fixes without waiting for a new base digest.
RUN apt-get update \
    && apt-get -y --no-install-recommends upgrade \
    && apt-get install -y --no-install-recommends \
        bash \
        bash-completion \
        bind9-dnsutils \
        binutils \
        ca-certificates \
        coreutils \
        cron \
        curl \
        git \
        grep \
        iproute2 \
        jq \
        libcap2-bin \
        libncurses6 \
        logrotate \
        lsof \
        passwd \
        procps \
        psmisc \
        tzdata \
        unzip \
        util-linux \
        wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Unprivileged service account (uid/gid 1000, same defaults as the official
# image; override at runtime with PIHOLE_UID / PIHOLE_GID).
RUN groupadd --gid "${PIHOLE_GID}" pihole \
    && useradd --uid "${PIHOLE_UID}" --gid pihole --no-create-home \
        --home-dir /nonexistent --shell /usr/sbin/nologin pihole

# pihole-FTL is a statically linked binary published by the Pi-hole project.
# Upstream only publishes SHA-1 digests, so the build verifies both the SHA-1
# from the GitHub release and our pinned SHA-256 of the exact artifact.
RUN set -eux; \
    base="https://github.com/pi-hole/FTL/releases/download/${FTL_VERSION}"; \
    curl -fsSL --retry 3 "$base/pihole-FTL-amd64" -o /usr/bin/pihole-FTL; \
    echo "${FTL_SHA256}  /usr/bin/pihole-FTL" | sha256sum -c -; \
    curl -fsSL --retry 3 "$base/pihole-FTL-amd64.sha1" -o /tmp/pihole-FTL-amd64.sha1; \
    echo "$(cut -d' ' -f1 /tmp/pihole-FTL-amd64.sha1)  /usr/bin/pihole-FTL" | sha1sum -c -; \
    rm -f /tmp/pihole-FTL-amd64.sha1; \
    chmod 0755 /usr/bin/pihole-FTL; \
    /usr/bin/pihole-FTL --version

# MAC vendor database used by FTL for the network table.
RUN set -eux; \
    curl -fsSL --retry 3 https://ftl.pi-hole.net/macvendor.db -o /macvendor.db; \
    echo "${MACVENDOR_SHA256}  /macvendor.db" | sha256sum -c -; \
    chmod 0644 /macvendor.db

# PADD dashboard script, pinned by commit and verified by digest.
RUN set -eux; \
    curl -fsSL --retry 3 \
        "https://raw.githubusercontent.com/pi-hole/PADD/${PADD_COMMIT}/padd.sh" \
        -o /usr/local/bin/padd; \
    echo "${PADD_SHA256}  /usr/local/bin/padd" | sha256sum -c -; \
    chmod 0755 /usr/local/bin/padd

# Pi-hole Core and Web at their official release tags, laid out exactly as the
# official image does. The .git directories are kept so `pihole -v` can report
# the local component versions.
RUN set -eux; \
    git clone --depth 1 --branch "${PIHOLE_CORE_VERSION}" https://github.com/pi-hole/pi-hole.git /etc/.pihole; \
    git clone --depth 1 --branch "${PIHOLE_WEB_VERSION}" https://github.com/pi-hole/web.git /var/www/html/admin; \
    cd /etc/.pihole; \
    install -Dm755 -d /opt/pihole; \
    install -Dm755 -t /opt/pihole gravity.sh; \
    install -Dm755 -t /opt/pihole ./advanced/Scripts/*.sh; \
    install -Dm755 -t /opt/pihole ./advanced/Scripts/COL_TABLE; \
    install -Dm755 -d /etc/pihole; \
    install -Dm755 -d /var/log/pihole; \
    install -Dm755 -d /var/lib/logrotate; \
    install -Dm755 -t /usr/local/bin pihole; \
    install -Dm644 ./advanced/bash-completion/pihole.bash /etc/bash_completion.d/pihole; \
    install -Dm644 ./advanced/bash-completion/pihole-ftl.bash /etc/bash_completion.d/pihole-FTL; \
    install -T -m 0755 ./advanced/Templates/pihole-FTL-prestart.sh /opt/pihole/pihole-FTL-prestart.sh; \
    install -T -m 0755 ./advanced/Templates/pihole-FTL-poststop.sh /opt/pihole/pihole-FTL-poststop.sh; \
    install -T -m 644 ./advanced/Templates/logrotate /etc/logrotate.d/pihole; \
    git config --system --add safe.directory /etc/.pihole; \
    git config --system --add safe.directory /var/www/html/admin; \
    chmod a+r /etc/gitconfig

COPY --from=entrypoint --chmod=0755 /scripts/bash_functions.sh /usr/bin/bash_functions.sh
COPY --from=entrypoint --chmod=0755 /scripts/prefix-time.sh /usr/bin/prefix-time.sh
COPY --from=entrypoint --chmod=0755 /scripts/start.sh /usr/bin/start.sh
COPY --from=entrypoint /scripts/crontab.txt /crontab.txt

# The tag file tells `pihole updatechecker` that this is an image build and
# stops it from reporting/attempting in-place component upgrades.
RUN echo "${PIHOLE_DOCKER_VERSION}" > /pihole.docker.tag

# Runtime directories (the compose volume mounts land on top of these).
RUN mkdir -p /etc/pihole /var/log/pihole /run/pihole \
    && chown -R pihole:pihole /etc/pihole /var/log/pihole

ENV DNSMASQ_USER=pihole \
    FTL_CMD=no-daemon

EXPOSE 53/tcp 53/udp 67/udp 80/tcp 443/tcp 123/udp

# FTL answers on the port configured in pihole.toml (53 by default). The exact
# test of the official image is kept so behaviour is identical.
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD dig -p $(pihole-FTL --config dns.port) +short +norecurse +retry=0 @127.0.0.1 pi.hole || exit 1

# start.sh stays PID 1: it traps SIGTERM/SIGINT, shuts FTL down cleanly, waits
# for the capsh/FTL child and reaps the cron and log-tail children.
ENTRYPOINT ["start.sh"]
