# syntax=docker/dockerfile:1.18.0@sha256:dabfc0969b935b2080555ace70ee69a5261af8a8f1b4df97b9e7fbcf6722eddf

FROM stage0

ARG SYSTEMD_OFFLINE=1

RUN --mount=type=cache,id=dnf,target=/var/cache/dnf --mount=type=tmpfs,target=/run --mount=type=tmpfs,target=/tmp --mount=type=tmpfs,target=/var/log <<RUNEOF
set -eux -o pipefail

dnf install --setopt=keepcache=1 --assumeyes \
  sudo polkit \
  which util-linux moreutils diffutils procps-ng psmisc file less lsof xxd \
  ripgrep perl-interpreter \
  iputils iproute hostname \
  socat nmap-ncat git-core git-lfs wget rsync openssh-clients ldns-utils \
  tree \
  sqlite \
  gnupg2 \
  zip cpio \
  tmux \
  man-db \
  ncurses readline \
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
RUNEOF
