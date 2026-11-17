# syntax=docker/dockerfile:1.29.0@sha256:572cebbc2b15e6f84c077742952674889cb63cd5e9b80abdffcbe587b6f19183

FROM quay.io/coreos/chunkah:v0.7.1@sha256:71e593421c5de7dcc7c8c5c50e98d3bac572055a76f399f61a491d123c20a523 AS split

ARG TARGETARCH
ARG CHUNKAH_CONFIG_STR
ARG MAX_LAYERS=64

# Apply policy after the last COPY: user.* xattrs need not survive intermediate
# image exporters. The target's Python avoids adding a second toolchain here.
RUN --mount=from=stage3,target=/input,readonly \
    --mount=type=bind,source=components.py,target=/components.py,readonly \
    --mount=type=bind,source=package-groups.json,target=/package-groups.json,readonly \
    --network=none <<RUNEOF
set -eu -o pipefail
test -n "$CHUNKAH_CONFIG_STR"
mkdir /rootfs /out
cp -a /input/. /rootfs/
PACKAGE_GROUPS_JSON="$(cat /package-groups.json)" \
  chroot /rootfs /usr/bin/python3.14 -B - < /components.py
export SOURCE_DATE_EPOCH=$(cat /rootfs/etc/BUILDEPOCH)
chunkah build --rootfs /rootfs \
  --config-str "$CHUNKAH_CONFIG_STR" --arch "$TARGETARCH" \
  --max-layers "$MAX_LAYERS" --compressed --compression-level 6 \
  --tag rechunked \
  --output oci:/out/image
RUNEOF

FROM scratch
COPY --from=split /out/ /
