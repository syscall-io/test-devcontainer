# syntax=docker/dockerfile:1.19.0@sha256:b6afd42430b15f2d2a4c5a02b919e98a525b785b1aaff16747d2f623364e39b6

FROM stage0

ARG SYSTEMD_OFFLINE=1

RUN --mount=type=cache,id=dnf,target=/var/cache/dnf --mount=type=cache,target=/var/lib/dnf/repos --mount=type=tmpfs,target=/run --mount=type=tmpfs,target=/tmp --mount=type=tmpfs,target=/var/log <<RUNEOF
set -eux -o pipefail

dnf install --setopt=keepcache=1 --assumeyes \
  sudo polkit \
  which util-linux moreutils diffutils procps-ng psmisc file less lsof xxd tree \
  ripgrep \
  pv \
  iputils iproute hostname \
  socat nmap-ncat \
  wget rsync openssh-clients ldns-utils \
  git-core git-lfs \
  sqlite \
  gnupg2 \
  zip cpio \
  tmux \
  man-db \
  ncurses readline \
  perl-interpreter \
  vim-enhanced \
;

########################################

dnf install --setopt=keepcache=1 --setopt=tsflags=nodocs --assumeyes \
  gcc gcc-c++ clang lld binutils elfutils \
  make patch autoconf automake \
  libtool libtool-ltdl pkgconf-pkg-config \
  llvm clang-tools-extra \
  strace gdb-gdbserver lldb \
  flex bison byacc \
  gettext \
  rpm-build \
  bash-completion \
;

########################################

dnf install --setopt=keepcache=1 --setopt=tsflags=nodocs --assumeyes \
  zlib-devel lz4-devel libzstd-devel \
  gettext-devel ncurses-devel readline-devel \
  elfutils-libelf-devel libunwind-devel \
  nss-devel openssl-devel \
  libcurl-devel \
  libxml2-devel libxslt-devel \
  sqlite-devel \
  systemd-devel libcap-devel \
  libevent-devel liburing-devel \
  numactl-devel \
  libicu-devel \
  uuid-devel \
  swig \
;

########################################

dnf install --setopt=keepcache=1 --setopt=tsflags=nodocs --assumeyes \
  xterm \
;

dnf install --setopt=keepcache=1 --setopt=tsflags=nodocs --assumeyes \
  python3.12 python3.12-{pip,cffi,lxml,cryptography} \
  python3.12-devel \
;

dnf install --setopt=keepcache=1 --setopt=tsflags=nodocs --assumeyes \
  nodejs22 nodejs22-devel nodejs-npm \
;

dnf install --setopt=keepcache=1 --setopt=tsflags=nodocs --assumeyes \
  java-21-openjdk-devel \
;

########################################

alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 110

ln -s vim /usr/bin/vi

########################################

lastest_rpm_build_time=$(rpm -qa --queryformat '%{BUILDTIME}\t%{NAME}-%{VERSION}-%{RELEASE}\n' | sort -n | tail -1 | awk '{print $1}')
date --date=@${lastest_rpm_build_time} '+%Y%m%d_%H%M' > /etc/BUILDTIME
touch -d "@${lastest_rpm_build_time}" /etc/BUILDTIME

find / -mount -depth -newer /etc/BUILDTIME -ls -exec touch --reference=/etc/BUILDTIME --no-dereference {} \;

RUNEOF
