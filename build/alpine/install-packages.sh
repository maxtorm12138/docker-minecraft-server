#!/bin/sh

set -e
set -o pipefail

# Install necessary packages
# shellcheck disable=SC2086
apk add --no-cache -U \
    openssl \
    file \
    lsof \
    coreutils \
    findutils \
    procps \
    shadow \
    bash \
    curl \
    iputils \
    jq \
    tzdata \
    rsync \
    ncurses \
    sudo \
    tar \
    zstd \
    libpcap \
    libcap \
    numactl \
    dos2unix \
    ${EXTRA_ALPINE_PACKAGES}

# Download and install patched knockd
curl -fsSL -o /tmp/knock.tar.gz https://github.com/Metalcape/knock/releases/download/0.8.1/knock-0.8.1-alpine-amd64.tar.gz
tar -xf /tmp/knock.tar.gz -C /usr/local/ && rm /tmp/knock.tar.gz
ln -s /usr/local/sbin/knockd /usr/sbin/knockd
setcap cap_net_raw=ep /usr/local/sbin/knockd
