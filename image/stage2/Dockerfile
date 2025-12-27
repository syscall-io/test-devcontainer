# syntax=docker/dockerfile:1.20.0@sha256:26147acbda4f14c5add9946e2fd2ed543fc402884fd75146bd342a7f6271dc1d

FROM stage1 AS root

FROM root AS s0

# empty, reserved for future use

FROM s0 AS s1

RUN --mount=from=container-script,target=/tmp/container-script,readonly \
    --mount=type=tmpfs,target=/tmp --mount=type=tmpfs,target=/run \
    --mount=type=tmpfs,target=/var/log \
    --mount=type=cache,from=repo-snapshot,target=/var/cache/dnf --mount=type=tmpfs,target=/var/lib/dnf/repos \
<<RUNEOF
set -eux -o pipefail

/tmp/container-script/dnf-wrapper.sh install \
  autoconf automake \
  binutils \
  bison \
  byacc \
  clang \
  clang-tools-extra \
  elfutils \
  flex \
  gcc gcc-c++ \
  gdb-minimal gdb-gdbserver \
  gettext \
  libtool libtool-ltdl \
  lld \
  lldb \
  llvm \
  pkgconf-pkg-config \
  perl-FindBin \
  perl-lib \
  readline \
;

/tmp/container-script/dnf-wrapper.sh install --setopt=tsflags=nodocs \
  rpm-build \
;

/tmp/container-script/dnf-wrapper.sh install --setopt=tsflags=nodocs \
  elfutils-libelf-devel \
  gettext-devel \
  libcap-devel \
  libcurl-devel \
  libevent-devel \
  libicu-devel \
  libunwind-devel \
  liburing-devel \
  libxml2-devel \
  libxslt-devel \
  libzstd-devel \
  lz4-devel \
  ncurses-devel \
  nss-devel \
  numactl-devel \
  openssl-devel \
  pam-devel \
  pcre2-devel \
  readline-devel \
  sqlite-devel \
  swig \
  systemd-devel \
  uuid-devel \
  zlib-devel \
;

rm -f /etc/{passwd,shadow,group,gshadow,subuid,subgid}-

rpm --restore --all || :
find / -mount -depth -newer /etc/BUILDTIME -exec touch --reference=/etc/BUILDTIME --no-create --no-dereference {} \;

RUNEOF

FROM s1 AS s2

RUN --mount=from=container-script,target=/tmp/container-script,readonly \
    --mount=type=tmpfs,target=/tmp --mount=type=tmpfs,target=/run \
    --mount=type=tmpfs,target=/var/log \
    --mount=type=cache,from=repo-snapshot,target=/var/cache/dnf --mount=type=tmpfs,target=/var/lib/dnf/repos \
<<RUNEOF
set -eux -o pipefail

/tmp/container-script/dnf-wrapper.sh install --setopt=tsflags=nodocs  \
  python3.12-devel python3.12-{pip,cffi,lxml,cryptography} \
;

alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 110

rpm --restore --all || :
find / -mount -depth -newer /etc/BUILDTIME -exec touch --reference=/etc/BUILDTIME --no-create --no-dereference {} \;

RUNEOF

FROM s2 AS s3

RUN --mount=from=container-script,target=/tmp/container-script,readonly \
    --mount=type=tmpfs,target=/tmp --mount=type=tmpfs,target=/run \
    --mount=type=tmpfs,target=/var/log \
    --mount=type=cache,from=repo-snapshot,target=/var/cache/dnf --mount=type=tmpfs,target=/var/lib/dnf/repos \
<<RUNEOF
set -eux -o pipefail

/tmp/container-script/dnf-wrapper.sh install --setopt=tsflags=nodocs \
  nodejs22 nodejs22-devel nodejs-npm \
;

rpm --restore --all || :
find / -mount -depth -newer /etc/BUILDTIME -exec touch --reference=/etc/BUILDTIME --no-create --no-dereference {} \;

RUNEOF

FROM s3 AS s4

RUN --mount=from=container-script,target=/tmp/container-script,readonly \
    --mount=type=tmpfs,target=/tmp --mount=type=tmpfs,target=/run \
    --mount=type=tmpfs,target=/var/log \
    --mount=type=cache,from=repo-snapshot,target=/var/cache/dnf --mount=type=tmpfs,target=/var/lib/dnf/repos \
<<RUNEOF
set -eux -o pipefail

/tmp/container-script/dnf-wrapper.sh install --setopt=tsflags=nodocs \
  java-25-openjdk-devel \
;

rpm --restore --all || :
find / -mount -depth -newer /etc/BUILDTIME -exec touch --reference=/etc/BUILDTIME --no-create --no-dereference {} \;

RUNEOF

################################################################################

FROM root

COPY --from=s0 \
  --exclude=usr/lib/sysimage/rpm/rpmdb.* \
  --exclude=var/lib/dnf/history.* \
  --exclude=var/cache/ldconfig/aux-cache \
  / /

COPY --from=s1 \
  --exclude=usr/lib/sysimage/rpm/rpmdb.* \
  --exclude=var/lib/dnf/history.* \
  --exclude=var/cache/ldconfig/aux-cache \
  / /

COPY --from=s2 \
  --exclude=usr/lib/sysimage/rpm/rpmdb.* \
  --exclude=var/lib/dnf/history.* \
  --exclude=var/cache/ldconfig/aux-cache \
  / /

COPY --from=s3 \
  --exclude=usr/lib/sysimage/rpm/rpmdb.* \
  --exclude=var/lib/dnf/history.* \
  --exclude=var/cache/ldconfig/aux-cache \
  / /

COPY --from=s4 \
  --exclude=usr/lib/sysimage/rpm/rpmdb.* \
  --exclude=var/lib/dnf/history.* \
  --exclude=var/cache/ldconfig/aux-cache \
  / /

COPY --from=s4 / /
