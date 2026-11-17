# syntax=docker/dockerfile:1.29.0@sha256:572cebbc2b15e6f84c077742952674889cb63cd5e9b80abdffcbe587b6f19183
# Syntax: https://github.com/moby/buildkit/blob/v0.25/frontend/dockerfile/docs/reference.md

FROM docker.io/almalinux/10-toolbox:10.3-20261116@sha256:6e37c1eae6c57189c8d90bd6b35497405df34e1f766ea7e6498e4afbb98a5e4f AS downloader

ARG TARGETARCH
ARG TARGETVARIANT

ENV LANG=C LC_CTYPE=C.UTF-8 LC_COLLATE=C

RUN --mount=type=tmpfs,target=/run --mount=type=tmpfs,target=/tmp --mount=type=tmpfs,target=/var/log <<RUNEOF
set -eux -o pipefail

if ! rpm -q epel-release; then
    # NOTE: rpm is signed.
    curl -fSL -o /tmp/epel-release.noarch.rpm https://repo.almalinux.org/almalinux/10/extras/x86_64/os/Packages/epel-release-10-6.el10.noarch.rpm

    rpm --checksig /tmp/epel-release.noarch.rpm
    rpm --install --verbose /tmp/epel-release.noarch.rpm
fi

RUNEOF

RUN --mount=type=cache,id=snapshot-${TARGETARCH}${TARGETVARIANT},target=/var/cache --mount=type=tmpfs,target=/var/lib/dnf/repos --mount=type=tmpfs,target=/run --mount=type=tmpfs,target=/tmp --mount=type=tmpfs,target=/var/log <<RUNEOF
set -eux -o pipefail

rm -rf /var/cache/{yum,dnf}

dnf makecache
dnf provides /bin/bash > /dev/null
dnf provides dummy-not-exists > /dev/null || :

RUNEOF

RUN --network=none --mount=type=cache,id=snapshot-${TARGETARCH}${TARGETVARIANT},target=/var/cache <<RUNEOF

now_ts=$(date +%s)
echo "[*] Snapshot time: @${now_ts}, $(TZ=UTC date --date="@${now_ts}" '+%Y-%m-%d %H:%M:%S %Z')"

rm -rf /output
mkdir -p /output
cp -va --no-target-directory /var/cache/dnf /output

TZ=UTC date --date="@${now_ts}" '+%Y%m%d_%H%M' > /output/.reposnapshot.BUILDTIME
echo "$now_ts" > /output/.reposnapshot.BUILDEPOCH
touch -d "@${now_ts}" /output/.reposnapshot.*

RUNEOF


FROM scratch

COPY --from=downloader /output/ /
