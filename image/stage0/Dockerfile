# syntax=docker/dockerfile:1.18.0@sha256:dabfc0969b935b2080555ace70ee69a5261af8a8f1b4df97b9e7fbcf6722eddf
# Syntax: https://github.com/moby/buildkit/blob/v0.24/frontend/dockerfile/docs/reference.md

# https://raw.githubusercontent.com/AlmaLinux/container-images/9ec2d07542f07e6781d6f388e66f1e3f2aac889e/Containerfiles/10/Containerfile.base
FROM docker.io/almalinux/10-base:10.0-20250909@sha256:926e495c38418bcac4500f67c91def1b6062cd5e7a7f48be77327abfd8f45528 AS stage0-0

ENV LANG=C LC_CTYPE=C.UTF-8 LC_COLLATE=C

ARG SYSTEMD_OFFLINE=1

RUN --mount=type=cache,id=dnf,target=/var/cache/dnf --mount=type=tmpfs,target=/run --mount=type=tmpfs,target=/tmp --mount=type=tmpfs,target=/var/log <<RUNEOF
set -eux -o pipefail

printf "LANG=${LANG}\nLC_CTYPE=${LC_CTYPE}\nLC_COLLATE=${LC_COLLATE}\n" > /etc/locale.conf

printf '\ninstall_weak_deps=0\n' >> /etc/dnf/dnf.conf

dnf remove --assumeyes \
  libuser \
  libusbx \
  dmidecode \
  usermode \
  virt-what \
  gdb-gdbserver \
  openldap \
;

dnf makecache

dnf upgrade --setopt=keepcache=1 --setopt=tsflags=nodocs --assumeyes

dnf install --setopt=keepcache=1 --setopt=tsflags=nodocs --assumeyes \
 dnf-plugins-core epel-release \
;

rpmkeys --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-10
crb enable

dnf makecache --repo=crb --repo=epel

dnf install --setopt=keepcache=1 --allowerasing --assumeyes \
  findutils grep gawk sed which \
  curl openssl \
  ca-certificates \
  tar unzip gzip bzip2 zstd lz4 xz \
  jq \
  glibc-langpack-en \
;

########################################

find /usr/lib/locale -maxdepth 1 -type d -name 'en*' \! \( -name 'en_US*' \) -exec rm -rf {} +

systemctl mask \
  sys-fs-fuse-connections.mount \
  sys-kernel-config.mount \
  sys-kernel-debug.mount \
  sys-kernel-tracing.mount \
  systemd-remount-fs.service \
  systemd-udev-trigger.service \
  systemd-udevd.service \
  getty.target \
  console-getty.service \
  systemd-random-seed.service \
  systemd-machine-id-commit.service \
  systemd-update-utmp.service \
  systemd-update-utmp-runlevel.service \
  systemd-update-done.service \
;

systemctl disable \
  dnf-makecache.timer \
  fstrim.timer \
  systemd-network-generator.service \
  fips-crypto-policy-overlay.service \
  systemd-hostnamed.socket \
  systemd-userdbd.socket \
;

systemctl unmask systemd-logind.service


RUNEOF

# Run the following command if `podman pull scratch` is hanging:
# $ scratch_image='docker.io/shinsenter/scratch@sha256:0af5a09ba89419d5c70ffa2ee9ee7850a62c3c75347525d1004ee9e3a1f1f012'
# $ podman image pull "$scratch_image"
# $ podman image tag "$scratch_image" docker.io/library/scratch:latest

FROM scratch AS stage0

COPY --link --from=stage0-0 / /

ENV LANG=C LC_CTYPE=C.UTF-8 LC_COLLATE=C

WORKDIR /
USER 0:0
STOPSIGNAL SIGRTMIN+3
CMD ["/sbin/init"]
