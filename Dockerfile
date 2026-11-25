# syntax=docker/dockerfile:1.7

# ---------------------------------------------------------------------------
# Pi-hole v6 (FTL + Core + Web) on Debian 13 (trixie) slim (multi-arch).
#
# Drop-in compatible with pihole/pihole: same environment variables, volumes,
# ports, healthcheck, and uid/gid defaults, built on Debian 13 with daily
# security updates. The only behavioural patch applied to the upstream
# entrypoint is the package manager and cron daemon call
# (see patches/0001-debian-gnu-userland.patch).
#
# Every version and base digest below is a documented default; CI overrides
# them on each run (see .github/workflows/daily.yml).
# ---------------------------------------------------------------------------

ARG DEBIAN_BASE=debian:trixie-slim@sha256:8aa5a7bf5a1955bddbe7d74fcdd0b91ab30e74362a8b73af672b0481b35b44a0

# docker-pi-hole release supplying start.sh / bash_functions.sh / crontab
ARG PIHOLE_DOCKER_VERSION=2026.11.0
# pi-hole component releases
ARG PIHOLE_CORE_VERSION=v6.6
ARG PIHOLE_WEB_VERSION=v6.6.1
ARG FTL_VERSION=v6.9
# SHA-256 of pihole-FTL-{amd64,arm64} for FTL_VERSION (upstream publishes SHA-1 only)
ARG FTL_SHA256_AMD64=8203d625fa1ee889710471b8f9b8a991fd6dddb4ca6a923d1ff43db47660865d
ARG FTL_SHA256_ARM64=00c1d51bca1f9539af7cada95532cdabf9755a42fd8e41802c75e5758a8daa60
# PADD (Pi-hole Ad-blocking Dashboard) pinned commit + SHA-256 of padd.sh
ARG PADD_COMMIT=3600b2e0399967219ae998561bb474d8c169e432
ARG PADD_SHA256=5f62569868b9e081eba539c79c06e504cbb43a59cd0af052783e87b901ec2a24
# MAC vendor database published by the Pi-hole project
ARG MACVENDOR_SHA256=e07d5a2ac56c7b23582c174272c8cbb785859680e843c1295cb8b8726cfc3ac0

ARG PIHOLE_UID=1000
ARG PIHOLE_GID=1000

ARG IMAGE_CREATED=""
ARG IMAGE_REVISION=""
ARG IMAGE_SOURCE="https://github.com/dgcosenza/pihole-docker"

# ---- Stage 1: fetch and verify all Pi-hole artifacts into /rootfs ----------
FROM ${DEBIAN_BASE} AS assets

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG TARGETARCH
ARG PIHOLE_DOCKER_VERSION
ARG PIHOLE_CORE_VERSION
ARG PIHOLE_WEB_VERSION
ARG FTL_VERSION
ARG FTL_SHA256_AMD64
ARG FTL_SHA256_ARM64
ARG PADD_COMMIT
ARG PADD_SHA256
ARG MACVENDOR_SHA256

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl git patch \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /scripts
COPY patches/ /patches/

RUN set -eux; \
    base="https://raw.githubusercontent.com/pi-hole/docker-pi-hole/${PIHOLE_DOCKER_VERSION}/src"; \
    for f in start.sh bash_functions.sh prefix-time.sh crontab.txt; do \
        curl -fsSL --retry 3 "${base}/${f}" -o "/scripts/${f}"; \
    done; \
    patch -p1 -d /scripts < /patches/0001-debian-gnu-userland.patch; \
    install -d /rootfs/usr/bin /rootfs/usr/local/bin /rootfs/opt/pihole \
        /rootfs/etc/bash_completion.d /rootfs/etc/logrotate.d \
        /rootfs/usr/share/doc/pihole-notices; \
    install -m 0755 /scripts/bash_functions.sh /rootfs/usr/bin/bash_functions.sh; \
    install -m 0755 /scripts/prefix-time.sh /rootfs/usr/bin/prefix-time.sh; \
    install -m 0755 /scripts/start.sh /rootfs/usr/bin/start.sh; \
    install -m 0644 /scripts/crontab.txt /rootfs/crontab.txt; \
    printf '%s\n' "${PIHOLE_DOCKER_VERSION}" > /rootfs/pihole.docker.tag; \
    case "${TARGETARCH:-amd64}" in \
        amd64) ftl_bin="pihole-FTL-amd64"; ftl_sha256="${FTL_SHA256_AMD64}" ;; \
        arm64) ftl_bin="pihole-FTL-arm64"; ftl_sha256="${FTL_SHA256_ARM64}" ;; \
        *) echo "Unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    ftl_base="https://github.com/pi-hole/FTL/releases/download/${FTL_VERSION}"; \
    curl -fsSL --retry 3 "${ftl_base}/${ftl_bin}" -o /rootfs/usr/bin/pihole-FTL; \
    printf '%s  /rootfs/usr/bin/pihole-FTL\n' "${ftl_sha256}" | sha256sum -c -; \
    curl -fsSL --retry 3 "${ftl_base}/${ftl_bin}.sha1" -o /tmp/ftl.sha1; \
    ftl_sha1="$(cut -d' ' -f1 /tmp/ftl.sha1)"; \
    printf '%s  /rootfs/usr/bin/pihole-FTL\n' "${ftl_sha1}" | sha1sum -c -; \
    rm -f /tmp/ftl.sha1; \
    chmod 0755 /rootfs/usr/bin/pihole-FTL; \
    /rootfs/usr/bin/pihole-FTL --version; \
    curl -fsSL --retry 3 https://ftl.pi-hole.net/macvendor.db -o /rootfs/macvendor.db; \
    printf '%s  /rootfs/macvendor.db\n' "${MACVENDOR_SHA256}" | sha256sum -c -; \
    chmod 0644 /rootfs/macvendor.db; \
    curl -fsSL --retry 3 "https://raw.githubusercontent.com/pi-hole/PADD/${PADD_COMMIT}/padd.sh" -o /rootfs/usr/local/bin/padd; \
    printf '%s  /rootfs/usr/local/bin/padd\n' "${PADD_SHA256}" | sha256sum -c -; \
    chmod 0755 /rootfs/usr/local/bin/padd; \
    git clone --depth 1 --branch "${PIHOLE_CORE_VERSION}" https://github.com/pi-hole/pi-hole.git /rootfs/etc/.pihole; \
    git clone --depth 1 --branch "${PIHOLE_WEB_VERSION}" https://github.com/pi-hole/web.git /rootfs/var/www/html/admin; \
    install -m 0755 -t /rootfs/opt/pihole /rootfs/etc/.pihole/gravity.sh; \
    install -m 0755 -t /rootfs/opt/pihole /rootfs/etc/.pihole/advanced/Scripts/*.sh; \
    install -m 0755 -t /rootfs/opt/pihole /rootfs/etc/.pihole/advanced/Scripts/COL_TABLE; \
    install -m 0755 -t /rootfs/usr/local/bin /rootfs/etc/.pihole/pihole; \
    install -m 0644 /rootfs/etc/.pihole/advanced/bash-completion/pihole.bash /rootfs/etc/bash_completion.d/pihole; \
    install -m 0644 /rootfs/etc/.pihole/advanced/bash-completion/pihole-ftl.bash /rootfs/etc/bash_completion.d/pihole-FTL; \
    install -m 0755 /rootfs/etc/.pihole/advanced/Templates/pihole-FTL-prestart.sh /rootfs/opt/pihole/pihole-FTL-prestart.sh; \
    install -m 0755 /rootfs/etc/.pihole/advanced/Templates/pihole-FTL-poststop.sh /rootfs/opt/pihole/pihole-FTL-poststop.sh; \
    install -m 0644 /rootfs/etc/.pihole/advanced/Templates/logrotate /rootfs/etc/logrotate.d/pihole; \
    install -m 0644 /rootfs/etc/.pihole/LICENSE /rootfs/usr/share/doc/pihole-notices/LICENSE-core; \
    install -m 0644 /rootfs/var/www/html/admin/LICENSE /rootfs/usr/share/doc/pihole-notices/LICENSE-web

# ---- Stage 2: fully upgraded Debian 13 runtime OS layer --------------------
FROM ${DEBIAN_BASE} AS os-base

ARG PIHOLE_UID
ARG PIHOLE_GID

ENV DEBIAN_FRONTEND=noninteractive

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
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && groupadd --gid "${PIHOLE_GID}" pihole \
    && useradd --uid "${PIHOLE_UID}" --gid pihole --no-create-home \
        --home-dir /nonexistent --shell /usr/sbin/nologin pihole \
    && install -d -o pihole -g pihole -m 0755 /etc/pihole /var/log/pihole \
    && install -d -m 0755 /run/pihole /var/lib/logrotate \
    && git config --system --add safe.directory /etc/.pihole \
    && git config --system --add safe.directory /var/www/html/admin \
    && chmod a+r /etc/gitconfig

# ---- Stage 3: clean two-layer runtime image (zero base-upgrade waste) ------
FROM scratch

ARG PIHOLE_DOCKER_VERSION
ARG PIHOLE_CORE_VERSION
ARG PIHOLE_WEB_VERSION
ARG FTL_VERSION
ARG IMAGE_CREATED
ARG IMAGE_REVISION
ARG IMAGE_SOURCE

# hadolint ignore=DL3067
COPY --from=os-base / /
COPY --from=assets /rootfs/ /

ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    DEBIAN_FRONTEND=noninteractive \
    DNSMASQ_USER=pihole \
    FTL_CMD=no-daemon

LABEL org.opencontainers.image.title="Pi-hole v6 (Debian 13)" \
      org.opencontainers.image.description="Hardened, multi-arch Debian 13 (trixie-slim) build of Pi-hole v6 (FTL, Core and Web), drop-in compatible with pihole/pihole." \
      org.opencontainers.image.url="https://hub.docker.com/r/dgcosenza/pihole" \
      org.opencontainers.image.source="${IMAGE_SOURCE}" \
      org.opencontainers.image.documentation="${IMAGE_SOURCE}#readme" \
      org.opencontainers.image.version="${PIHOLE_DOCKER_VERSION}" \
      org.opencontainers.image.revision="${IMAGE_REVISION}" \
      org.opencontainers.image.created="${IMAGE_CREATED}" \
      org.opencontainers.image.licenses="EUPL-1.2 AND MIT" \
      org.opencontainers.image.vendor="Daniel G. Cosenza from FNX Labs" \
      org.opencontainers.image.authors="Daniel G. Cosenza from FNX Labs" \
      org.opencontainers.image.base.name="debian:trixie-slim" \
      io.github.dgcosenza.pihole.upstream_image="pihole/pihole" \
      io.github.dgcosenza.pihole.upstream_version="${PIHOLE_DOCKER_VERSION}" \
      io.github.dgcosenza.pihole.core_version="${PIHOLE_CORE_VERSION}" \
      io.github.dgcosenza.pihole.web_version="${PIHOLE_WEB_VERSION}" \
      io.github.dgcosenza.pihole.ftl_version="${FTL_VERSION}"

EXPOSE 53/tcp 53/udp 67/udp 80/tcp 443/tcp 123/udp

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD ["sh", "-c", "dig -p \"$(pihole-FTL --config dns.port)\" +short +norecurse +retry=0 @127.0.0.1 pi.hole || exit 1"]

ENTRYPOINT ["start.sh"]
