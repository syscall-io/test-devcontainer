# syntax=docker/dockerfile:1.19.0@sha256:b6afd42430b15f2d2a4c5a02b919e98a525b785b1aaff16747d2f623364e39b6
# Syntax: https://github.com/moby/buildkit/blob/v0.25/frontend/dockerfile/docs/reference.md

# https://raw.githubusercontent.com/AlmaLinux/container-images/9ec2d07542f07e6781d6f388e66f1e3f2aac889e/Containerfiles/10/Containerfile.base
FROM docker.io/almalinux/10-base:10.0-20250909@sha256:926e495c38418bcac4500f67c91def1b6062cd5e7a7f48be77327abfd8f45528 AS bootstrap

ENV LANG=C LC_CTYPE=C.UTF-8 LC_COLLATE=C

RUN --mount=type=cache,id=dnf,target=/var/cache/dnf --mount=type=cache,target=/var/lib/dnf/repos --mount=type=tmpfs,target=/run --mount=type=tmpfs,target=/tmp --mount=type=tmpfs,target=/var/log <<RUNEOF
set -eux -o pipefail

printf "LANG=${LANG}\nLC_CTYPE=${LC_CTYPE}\nLC_COLLATE=${LC_COLLATE}\n" > /etc/locale.conf

printf '\ninstall_weak_deps=0\n' >> /etc/dnf/dnf.conf

export SYSTEMD_OFFLINE=1

dnf remove --assumeyes \
  libuser \
  libusbx \
  dmidecode \
  usermode \
  virt-what \
  gdb-gdbserver \
  openldap \
  vim-minimal \
  less \
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
  glibc-langpack-en \
  findutils grep gawk sed which \
  curl openssl \
  ca-certificates \
  tar unzip gzip bzip2 zstd lz4 xz \
  jq \
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
  systemd-tpm2-setup.service \
  systemd-tpm2-setup-early.service \
  modprobe@.service \
;

systemctl disable \
  dnf-makecache.timer \
  fstrim.timer \
  systemd-network-generator.service \
  fips-crypto-policy-overlay.service \
  systemd-hostnamed.socket \
  systemd-userdbd.socket \
;

systemctl enable \
  tmp.mount \
;

systemctl unmask \
  systemd-logind.service \
;

# buildx --output's rewrite-timestamp=true is too slow...
lastest_rpm_build_time=$(rpm -qa --queryformat '%{BUILDTIME}\t%{NAME}-%{VERSION}-%{RELEASE}\n' | sort -n | tail -1 | awk '{print $1}')

if [ ! -e /etc/BUILDTIME ] || [ "$(stat -c %Y /etc/BUILDTIME)" -lt "${lastest_rpm_build_time}" ]; then
  date --date=@${lastest_rpm_build_time} '+%Y%m%d_%H%M' > /etc/BUILDTIME
  touch -d "@${lastest_rpm_build_time}" /etc/BUILDTIME
fi

find / -mount -depth -newer /etc/BUILDTIME -ls -exec touch --reference=/etc/BUILDTIME --no-dereference {} \;

RUNEOF


RUN --network=none --mount=type=tmpfs,target=/tmp <<RUNEOF
set -eux -o pipefail

mkdir /.non_deterministic

non_deterministic_files=(
  /usr/lib/sysimage/rpm/rpmdb.*
  /var/lib/dnf/history.*
  /var/cache/ldconfig/aux-cache
)

cp -va --parents "${non_deterministic_files[@]}" /.non_deterministic/
rm -f "${non_deterministic_files[@]}"

find / -mount -depth -newer /etc/BUILDTIME -ls -exec touch --reference=/etc/BUILDTIME --no-dereference {} \;

RUNEOF


FROM scratch AS stage0

COPY --link --from=bootstrap --exclude=.non_deterministic / /

COPY --link --from=bootstrap /.non_deterministic/ /

ENV LANG=C LC_CTYPE=C.UTF-8 LC_COLLATE=C

WORKDIR /
USER 0:0
STOPSIGNAL SIGRTMIN+3
CMD ["/sbin/init"]
