# syntax=docker/dockerfile:1.19.0@sha256:b6afd42430b15f2d2a4c5a02b919e98a525b785b1aaff16747d2f623364e39b6
# Syntax: https://github.com/moby/buildkit/blob/v0.25/frontend/dockerfile/docs/reference.md

# https://raw.githubusercontent.com/AlmaLinux/container-images/9ec2d07542f07e6781d6f388e66f1e3f2aac889e/Containerfiles/10/Containerfile.minimal
FROM docker.io/almalinux/10-minimal:10.0-20250909@sha256:f430e3c8e1078c519de768fa41bbccfe2b673bacc2f10d7193b11c71267bcecb AS bootstrap

ENV LANG=C LC_CTYPE=C.UTF-8 LC_COLLATE=C

RUN --mount=type=cache,target=/var/cache/yum --mount=type=cache,target=/var/cache/dnf --mount=type=cache,target=/var/lib/dnf/repos --mount=type=tmpfs,target=/run --mount=type=tmpfs,target=/tmp --mount=type=tmpfs,target=/var/log <<RUNEOF
set -eux -o pipefail

printf "LANG=${LANG}\nLC_CTYPE=${LC_CTYPE}\nLC_COLLATE=${LC_COLLATE}\n" > /etc/locale.conf

printf '\ninstall_weak_deps=0\n' >> /etc/dnf/dnf.conf

export SYSTEMD_OFFLINE=1

microdnf remove --assumeyes \
  libusbx \
;

microdnf makecache

microdnf upgrade --setopt=keepcache=1 --setopt=tsflags=nodocs --assumeyes

microdnf install --setopt=keepcache=1 --setopt=tsflags=nodocs --assumeyes \
 dnf dnf-plugins-core epel-release \
;

dnf remove --setopt=keepcache=1 --assumeyes \
  microdnf \
;

rpmkeys --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-10
crb enable

dnf makecache --repo=crb --repo=epel

dnf install --setopt=keepcache=1 --allowerasing --assumeyes \
  glibc-langpack-en \
  pam \
  findutils grep gawk sed which \
  curl openssl \
  ca-certificates \
  tar unzip gzip bzip2 zstd lz4 xz \
  jq \
;

########################################

pushd /tmp

dnf download util-linux
rpm2archive --nocompression --format=pax util-linux-*.rpm > util-linux.tar
tar xvf util-linux.tar -C / ./usr/sbin/runuser

popd

cat <<EOF > /etc/pam.d/runuser
#%PAM-1.0
auth            sufficient      pam_rootok.so
session         sufficient      pam_permit.so
EOF

########################################

rm -f /usr/share/cracklib/*.{hwm,pwd,pwi}

find /usr/lib/locale -maxdepth 1 -type d -name 'en*' \! \( -name 'en_US*' \) -exec rm -rf {} +

# buildx --output's rewrite-timestamp=true is too slow...
lastest_rpm_build_time=$(rpm -qa --queryformat '%{BUILDTIME}\t%{NAME}-%{VERSION}-%{RELEASE}\n' | sort -n | tail -1 | awk '{print $1}')

if [ ! -e /etc/BUILDTIME ] || [ "$(stat -c %Y /etc/BUILDTIME)" -lt "${lastest_rpm_build_time}" ]; then
  date --date=@${lastest_rpm_build_time} '+%Y%m%d_%H%M' > /etc/BUILDTIME
  touch -d "@${lastest_rpm_build_time}" /etc/BUILDTIME
fi

find / -mount -depth -newer /etc/BUILDTIME -exec touch --reference=/etc/BUILDTIME --no-dereference {} \;

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

find / -mount -depth -newer /etc/BUILDTIME -exec touch --reference=/etc/BUILDTIME --no-dereference {} \;

RUNEOF


FROM scratch AS stage0

COPY --link --from=bootstrap --exclude=.non_deterministic / /

COPY --link --from=bootstrap /.non_deterministic/ /

ENV LANG=C LC_CTYPE=C.UTF-8 LC_COLLATE=C
CMD ["/bin/bash"]
