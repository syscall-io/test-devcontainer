# syntax=docker/dockerfile:1.19.0@sha256:b6afd42430b15f2d2a4c5a02b919e98a525b785b1aaff16747d2f623364e39b6
# Syntax: https://github.com/moby/buildkit/blob/v0.25/frontend/dockerfile/docs/reference.md

FROM docker.io/almalinux/10-minimal:10.0-20250909@sha256:f430e3c8e1078c519de768fa41bbccfe2b673bacc2f10d7193b11c71267bcecb AS downloader

ARG TARGETARCH
ARG TARGETVARIANT

ENV LANG=C LC_CTYPE=C.UTF-8 LC_COLLATE=C

RUN --mount=type=cache,id=snapshot-${TARGETARCH}${TARGETVARIANT},target=/var/cache --mount=type=tmpfs,target=/var/lib/dnf/repos --mount=type=tmpfs,target=/run --mount=type=tmpfs,target=/tmp --mount=type=tmpfs,target=/var/log <<RUNEOF
set -eux -o pipefail

rm -rf /var/cache/{yum,dnf}

microdnf install --setopt=install_weak_deps=0 --setopt=tsflags=nodocs --assumeyes \
 dnf epel-release \
;

microdnf makecache

dnf makecache

mkdir -p /output

RUNEOF

RUN --network=none --mount=type=cache,id=snapshot-${TARGETARCH}${TARGETVARIANT},target=/var/cache <<RUNEOF

cp -va /var/cache/{yum,dnf} /output/

RUNEOF


FROM scratch

COPY --from=downloader /output/ /

