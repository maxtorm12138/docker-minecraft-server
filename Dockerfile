ARG BASE_IMAGE=azul/zulu-openjdk-alpine:21.0.10-jre
FROM ${BASE_IMAGE}

# hook into docker BuildKit --platform support
# see https://docs.docker.com/engine/reference/builder/#automatic-platform-args-in-the-global-scope
ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT

# The following three arg/env vars get used by the platform specific "install-packages" script
ARG EXTRA_ALPINE_PACKAGES=""
ARG FORCE_INSTALL_PACKAGES=1
RUN --mount=target=/build,source=build \
    TARGET=${TARGETARCH}${TARGETVARIANT} \
    /build/run.sh install-packages
COPY --from=tianon/gosu /gosu /usr/local/bin/

RUN --mount=target=/build,source=build \
    /build/run.sh setup-user

EXPOSE 25565

ARG APPS_REV=1
ARG GITHUB_BASEURL=https://github.com

# renovate: datasource=github-releases packageName=itzg/restify
ARG RESTIFY_VERSION=1.7.12
RUN curl -fsSL ${GITHUB_BASEURL}/itzg/restify/releases/download/${RESTIFY_VERSION}/restify_${RESTIFY_VERSION}_${TARGETOS}_${TARGETARCH}${TARGETVARIANT}.tar.gz \
  | tar -xzf - -C /usr/local/bin restify

# renovate: datasource=github-releases packageName=itzg/rcon-cli
ARG RCON_CLI_VERSION=1.7.4
RUN curl -fsSL ${GITHUB_BASEURL}/itzg/rcon-cli/releases/download/${RCON_CLI_VERSION}/rcon-cli_${RCON_CLI_VERSION}_${TARGETOS}_${TARGETARCH}${TARGETVARIANT}.tar.gz \
  | tar -xzf - -C /usr/local/bin rcon-cli

# renovate: datasource=github-releases packageName=itzg/mc-monitor
ARG MC_MONITOR_VERSION=0.16.1
RUN curl -fsSL ${GITHUB_BASEURL}/itzg/mc-monitor/releases/download/${MC_MONITOR_VERSION}/mc-monitor_${MC_MONITOR_VERSION}_${TARGETOS}_${TARGETARCH}${TARGETVARIANT}.tar.gz \
  | tar -xzf - -C /usr/local/bin mc-monitor

# renovate: datasource=github-releases packageName=itzg/mc-server-runner
ARG MC_SERVER_RUNNER_VERSION=1.14.4
RUN curl -fsSL ${GITHUB_BASEURL}/itzg/mc-server-runner/releases/download/${MC_SERVER_RUNNER_VERSION}/mc-server-runner_${MC_SERVER_RUNNER_VERSION}_${TARGETOS}_${TARGETARCH}${TARGETVARIANT}.tar.gz \
  | tar -xzf - -C /usr/local/bin mc-server-runner

# renovate: datasource=github-releases packageName=itzg/mc-image-helper versioning=loose
ARG MC_HELPER_VERSION=1.55.4
ARG MC_HELPER_BASE_URL=${GITHUB_BASEURL}/itzg/mc-image-helper/releases/download/${MC_HELPER_VERSION}
# used for cache busting local copy of mc-image-helper
ARG MC_HELPER_REV=1
RUN curl -fsSL ${MC_HELPER_BASE_URL}/mc-image-helper-${MC_HELPER_VERSION}.tgz \
  | tar -C /usr/share -zxf - \
    && ln -s /usr/share/mc-image-helper-${MC_HELPER_VERSION}/ /usr/share/mc-image-helper \
    && ln -s /usr/share/mc-image-helper/bin/mc-image-helper /usr/bin

VOLUME ["/data"]
WORKDIR /data

STOPSIGNAL SIGTERM

# End user MUST set EULA and change RCON_PASSWORD
ENV TYPE=GTNH VERSION=LATEST EULA="" UID=1000 GID=1000 LC_ALL=en_US.UTF-8

COPY --chmod=755 scripts/start* /image/scripts/

# Backward compatible shim for those with legacy entrypoint
COPY --chmod=755 <<EOF /start
#!/bin/bash
exec /image/scripts/start
EOF

COPY --chmod=755 scripts/auto/* /image/scripts/auto/
COPY --chmod=755 scripts/shims/* /image/scripts/shims/
RUN ln -s /image/scripts/shims/* /usr/local/bin/
COPY --chmod=755 files/* /image/

RUN curl -fsSL -o /image/Log4jPatcher.jar https://github.com/CreeperHost/Log4jPatcher/releases/download/v1.0.1/Log4jPatcher-1.0.1.jar

RUN dos2unix /image/scripts/start* /image/scripts/auto/*

ENTRYPOINT [ "/image/scripts/start" ]
HEALTHCHECK --start-period=2m --retries=2 --interval=30s CMD mc-health

ARG BUILDTIME=local
ARG VERSION=local
ARG REVISION=local
COPY <<EOF /etc/image.properties
buildtime=${BUILDTIME}
version=${VERSION}
revision=${REVISION}
EOF
