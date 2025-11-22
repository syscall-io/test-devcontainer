# syntax=docker/dockerfile:1.20.0@sha256:26147acbda4f14c5add9946e2fd2ed543fc402884fd75146bd342a7f6271dc1d
# Syntax: https://github.com/moby/buildkit/blob/v0.25/frontend/dockerfile/docs/reference.md

# https://raw.githubusercontent.com/AlmaLinux/container-images/9ec2d07542f07e6781d6f388e66f1e3f2aac889e/Containerfiles/10/Containerfile.toolbox
FROM docker.io/almalinux/10-toolbox:10.0-20251117@sha256:0fb9c08b0b9d40aef015c4b8ecdcfed2badcda3e4e2b88771c8db0ad49c55481 AS s0

ENV LANG=C LC_CTYPE=C.UTF-8 LC_COLLATE=C
ENV SYSTEMD_OFFLINE=1

RUN --mount=from=container-script,target=/tmp/container-script,readonly \
    --mount=type=tmpfs,target=/tmp --mount=type=tmpfs,target=/run \
    --mount=type=tmpfs,target=/var/log \
    --mount=type=cache,from=repo-snapshot,target=/var/cache/dnf --mount=type=tmpfs,target=/var/lib/dnf/repos \
<<RUNEOF
set -eux -o pipefail

mkdir /rootfs

rpmdb --root=/rootfs --initdb
rpmkeys --root=/rootfs --import /etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux-10
rpmkeys --root=/rootfs --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-10

/tmp/container-script/dnf-wrapper.sh install \
  --installroot=/rootfs \
  --releasever 10 \
  --nodocs \
  \
  basesystem \
;

/tmp/container-script/dnf-wrapper.sh install \
  --installroot=/rootfs \
  --nodocs \
  \
  glibc \
  glibc-minimal-langpack glibc-langpack-en \
  libgcc \
  libstdc++ \
  tzdata \
  ca-certificates \
  crypto-policies \
  \
  dbus-libs \
  libcurl-minimal \
  libevent \
  nss \
  mpfr \
  openssl-libs \
  pcre2 \
  systemd-libs \
  zlib \
;

rpm --root=/rootfs --erase --verbose --nodeps \
  bash coreutils coreutils-common grep sed findutils alternatives gawk \
;

/tmp/container-script/dnf-wrapper.sh autoremove \
  --installroot=/rootfs \
  "${DNF_CACHE_REUSE_ARGS[@]}" \
  --assumeyes \
;

find /rootfs/usr/lib/locale -maxdepth 1 -type d -name 'en*' \! \( -name 'en_US*' \) -exec rm -rf {} +

rm -rf /rootfs/var/log/dnf* /rootfs/var/log/yum.* /rootfs/var/log/hawkey.log /rootfs/var/cache/dnf /rootfs/var/lib/dnf/repos
rm -rf /rootfs/boot /rootfs/dev/null /rootfs/run/*
rm -f /rootfs/etc/{passwd,shadow,group,gshadow,subuid,subgid}-

cp /var/cache/dnf/.reposnapshot.BUILDTIME /rootfs/etc/BUILDTIME
touch --reference=/var/cache/dnf/.reposnapshot.BUILDTIME --no-create --no-dereference /rootfs/etc/BUILDTIME

rpm --root=/rootfs --restore -all || :
find /rootfs -mount -depth -newer /etc/BUILDTIME -exec touch --reference=/etc/BUILDTIME --no-create --no-dereference {} \;

RUNEOF

FROM s0 AS s1

ENV LANG=C LC_CTYPE=C.UTF-8 LC_COLLATE=C
ENV SYSTEMD_OFFLINE=1

RUN --mount=from=container-script,target=/tmp/container-script,readonly \
    --mount=type=tmpfs,target=/tmp --mount=type=tmpfs,target=/run \
    --mount=type=tmpfs,target=/var/log \
    --mount=type=cache,from=repo-snapshot,target=/var/cache/dnf --mount=type=tmpfs,target=/var/lib/dnf/repos \
<<RUNEOF
set -eux -o pipefail

# NOTE: rpm is signed.
# NOTE: it's not x86_64. it's a noarch package.
curl -fSL -o /tmp/epel-release.noarch.rpm https://repo.almalinux.org/almalinux/10/extras/x86_64/os/Packages/epel-release-10-6.el10.noarch.rpm

rpm --root=/rootfs --checksig /tmp/epel-release.noarch.rpm
rpm --root=/rootfs --install --verbose --nodeps /tmp/epel-release.noarch.rpm

/tmp/container-script/dnf-wrapper.sh install \
  --installroot=/rootfs \
  \
  bash \
  bzip2 \
  coreutils-full \
  crypto-policies-scripts \
  curl \
  dnf dnf-plugins-core \
  findutils \
  gawk \
  gettext-envsubst \
  grep \
  gzip \
  jq \
  lz4 \
  openssl \
  sed  \
  tar \
  unzip \
  xxd \
  xz \
  zstd \
;

rpm --root=/rootfs --erase --verbose --nodeps shadow-utils

/tmp/container-script/dnf-wrapper.sh check dependencies

rpm --root=/rootfs --restore --all || :
find /rootfs -mount -depth -newer /etc/BUILDTIME -exec touch --reference=/etc/BUILDTIME --no-create --no-dereference {} \;

RUNEOF

# minimal /usr/bin/runuser support
RUN --mount=from=container-script,target=/tmp/container-script,readonly \
    --mount=type=tmpfs,target=/tmp --mount=type=tmpfs,target=/run \
    --mount=type=tmpfs,target=/var/log \
    --mount=type=cache,from=repo-snapshot,target=/var/cache/dnf --mount=type=tmpfs,target=/var/lib/dnf/repos \
    --network=none \
<<RUNEOF
set -eux -o pipefail

cp -va /usr/sbin/runuser /rootfs/usr/sbin/runuser
cp -va /usr/lib64/security/pam_{rootok,permit}.so /rootfs/usr/lib64/security/

cat <<EOF > /rootfs/etc/pam.d/runuser
#%PAM-1.0
auth            sufficient      pam_rootok.so
session         sufficient      pam_permit.so
EOF

RUNEOF

RUN --mount=from=container-script,target=/tmp/container-script,readonly \
    --mount=type=tmpfs,target=/tmp --mount=type=tmpfs,target=/run \
    --mount=type=tmpfs,target=/var/log \
    --mount=type=cache,from=repo-snapshot,target=/var/cache/dnf --mount=type=tmpfs,target=/var/lib/dnf/repos \
    --network=none \
<<RUNEOF
set -eux -o pipefail

install -d -m 755 /rootfs/run/lock /rootfs/var/lib/systemd/coredump
install -d -m 700 /rootfs/var/cache/private /rootfs/var/lib/private

install -m 644 /dev/null /rootfs/etc/machine-id
install -m 644 /dev/null /rootfs/etc/resolv.conf
install -m 644 /dev/null /rootfs/etc/hostname
install -m 600 /dev/null /rootfs/etc/.pwd.lock

echo '%_install_langs C.utf8' > /rootfs/etc/rpm/macros.image-language-conf
echo 'container' > /rootfs/etc/dnf/vars/infra
printf '\ninstall_weak_deps=0\n' >> /rootfs/etc/dnf/dnf.conf

printf '0.0 0 0.0\n0\nUTC\n' > /rootfs/etc/adjtime
ln -s ../usr/share/zoneinfo/UTC /rootfs/etc/localtime

printf "LANG=${LANG}\nLC_CTYPE=${LC_CTYPE}\nLC_COLLATE=${LC_COLLATE}\n" > /rootfs/etc/locale.conf
echo 'KEYMAP="us"' > /rootfs/etc/vconsole.conf
echo 'FONT="eurlatgr"' >> /rootfs/etc/vconsole.conf

groupadd --root '/rootfs/' --system --password '!*' --gid 995 systemd-oom
useradd --root '/rootfs/' --no-log-init --system --comment 'systemd Userspace OOM Killer' --gid 995 --uid 995 --shell '/usr/sbin/nologin' --create-home --home-dir '/' systemd-oom

groupadd --root '/rootfs/' --system --password '!*' --gid 996 sgx

find /rootfs/usr/lib/locale -maxdepth 1 -type d -name 'en*' \! \( -name 'en_US*' \) -exec rm -rf {} +

rm -rf /rootfs/var/log/dnf* /rootfs/var/log/yum.* /rootfs/var/log/hawkey.log /rootfs/var/cache/dnf /rootfs/var/lib/dnf/repos

rm -rf /rootfs/boot /rootfs/dev/null /rootfs/run/*
rm -rf /rootfs/usr/share/doc/*

rm -f /rootfs/etc/{passwd,shadow,group,gshadow,subuid,subgid}-

rpm --root=/rootfs --restore --all || :
find /rootfs -mount -depth -newer /etc/BUILDTIME -exec touch --reference=/etc/BUILDTIME --no-create --no-dereference {} \;

RUNEOF

FROM scratch

COPY --from=s0 \
  --exclude=usr/lib/sysimage/rpm/rpmdb.* \
  --exclude=var/lib/dnf/history.* \
  --exclude=etc/ld.so.cache \
  --exclude=var/cache/ldconfig/aux-cache \
  /rootfs/ /

COPY --from=s1 \
  --exclude=usr/lib/sysimage/rpm/rpmdb.* \
  --exclude=var/lib/dnf/history.* \
  --exclude=var/cache/ldconfig/aux-cache \
  /rootfs/ /

COPY --from=s1 /rootfs/ /
# Intended: Add excluded files back

ENV LANG=C LC_CTYPE=C.UTF-8 LC_COLLATE=C
CMD ["/bin/bash"]
