# syntax=docker/dockerfile:1.19.0@sha256:b6afd42430b15f2d2a4c5a02b919e98a525b785b1aaff16747d2f623364e39b6

FROM stage1

ARG SYSTEMD_OFFLINE=1

RUN --mount=type=cache,target=/var/cache/yum --mount=type=cache,target=/var/cache/dnf --mount=type=cache,target=/var/lib/dnf/repos --mount=type=tmpfs,target=/run --mount=type=tmpfs,target=/tmp --mount=type=tmpfs,target=/var/log <<RUNEOF
set -eux -o pipefail


########################################

dnf install --setopt=keepcache=1 --setopt=tsflags=nodocs --assumeyes \
  gcc gcc-c++ clang lld binutils elfutils \
  patch autoconf automake \
  libtool libtool-ltdl pkgconf-pkg-config \
  llvm clang-tools-extra \
  strace gdb-gdbserver lldb \
  flex bison byacc \
  gettext \
  readline \
  rpm-build \
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

########################################

lastest_rpm_build_time=$(rpm -qa --queryformat '%{BUILDTIME}\t%{NAME}-%{VERSION}-%{RELEASE}\n' | sort -n | tail -1 | awk '{print $1}')
date --date=@${lastest_rpm_build_time} '+%Y%m%d_%H%M' > /etc/BUILDTIME
touch -d "@${lastest_rpm_build_time}" /etc/BUILDTIME

find / -mount -depth -newer /etc/BUILDTIME -exec touch --reference=/etc/BUILDTIME --no-dereference {} \;

RUNEOF

ARG DEV_USER_UID=1000
ARG DEV_USER_GID=1000
ARG DEV_USER_NAME=user

RUN --network=none <<RUNEOF
set -eux -o pipefail

cat <<'EOF' >> /etc/skel/.bashrc

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

alias grep='grep --color=auto'
alias ls='ls --color=auto'

EOF

cat <<'EOF' >> /etc/skel/.bash_profile
export EDITOR=vim
export PAGER=less
export LESS='--quit-if-one-screen --squeeze-blank-lines --RAW-CONTROL-CHARS'
EOF

groupadd --gid "$DEV_USER_GID" "$DEV_USER_NAME"
useradd --no-log-init --uid "$DEV_USER_UID" --gid "$DEV_USER_GID" --create-home --shell /bin/bash "$DEV_USER_NAME"
usermod --append --groups wheel "$DEV_USER_NAME"
usermod --append --groups systemd-journal "$DEV_USER_NAME"

echo "$DEV_USER_NAME ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/devuser
install -o 0 -g 0 -m 600 /dev/null /var/db/sudo/lectured/"$DEV_USER_UID"

RUNEOF

LABEL devcontainer.metadata='[{ \
  "overrideCommand": false, \
  "capAdd": [ "SYS_PTRACE", "SYS_ADMIN", "MKNOD" ], \
  "remoteUser": "user" \
}]'
