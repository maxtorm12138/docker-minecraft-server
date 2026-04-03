#!/bin/sh

set -e
set -o pipefail

# Install necessary packages
# shellcheck disable=SC2086
apk add --no-cache -U \
    file \
    coreutils \
    findutils \
    procps \
    bash \
    curl \
    jq \
    tzdata \
    rsync \
    ncurses \
    tar \
    zstd \
    numactl \
    dos2unix \
    ${EXTRA_ALPINE_PACKAGES}
