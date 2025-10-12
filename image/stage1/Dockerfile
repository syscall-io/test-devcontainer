# syntax=docker/dockerfile:1.19.0@sha256:b6afd42430b15f2d2a4c5a02b919e98a525b785b1aaff16747d2f623364e39b6

FROM stage0 AS root

FROM root AS s0-install-systemd

RUN --mount=from=container-script,target=/tmp/container-script,readonly \
    --mount=type=tmpfs,target=/tmp --mount=type=tmpfs,target=/run \
    --mount=type=tmpfs,target=/var/log \
    --mount=type=cache,from=repo-snapshot,target=/var/cache/dnf --mount=type=tmpfs,target=/var/lib/dnf/repos \
<<RUNEOF
set -eux -o pipefail

/tmp/container-script/dnf-wrapper.sh install \
  systemd \
  polkit \
;

########################################

echo -n > /etc/machine-id

ln -snf multi-user.target /usr/lib/systemd/system/default.target

systemctl mask \
  modprobe@.service \
  dev-hugepages.mount \
  sys-kernel-config.mount \
  sys-fs-fuse-connections.mount \
  systemd-remount-fs.service \
  systemd-udev-trigger.service \
  systemd-udevd.service \
  systemd-random-seed.service \
  systemd-machine-id-commit.service \
;

systemctl disable \
  systemd-userdbd.socket \
  systemd-network-generator.service \
;

rm -f /etc/{passwd,shadow,group,gshadow,subuid,subgid}-

########################################

find / -mount -depth -newer /etc/BUILDTIME -exec touch --reference=/etc/BUILDTIME --no-dereference {} \;

RUNEOF

FROM s0-install-systemd AS s1-install-packages

RUN --mount=from=container-script,target=/tmp/container-script,readonly \
    --mount=type=tmpfs,target=/tmp --mount=type=tmpfs,target=/run \
    --mount=type=tmpfs,target=/var/log \
    --mount=type=cache,from=repo-snapshot,target=/var/cache/dnf --mount=type=tmpfs,target=/var/lib/dnf/repos \
<<RUNEOF
set -eux -o pipefail

/tmp/container-script/dnf-wrapper.sh install \
  7zip \
  acl \
  bash-color-prompt \
  bash-completion \
  cpio \
  diffutils \
  file \
  gawk \
  git-core \
  gnupg2 \
  grep \
  gzip \
  hostname \
  iproute \
  iputils \
  jq \
  ldns-utils \
  less \
  lsof \
  lz4 \
  make \
  man-db \
  moreutils \
  nmap-ncat \
  openssh-clients \
  openssh-server \
  openssl \
  patch \
  perf \
  perl-interpreter \
  procps-ng \
  psmisc \
  pv \
  ripgrep \
  rootfiles \
  rsync \
  sed  \
  socat \
  sqlite \
  strace \
  sudo \
  tar \
  tcpdump \
  tmux \
  tree \
  unzip \
  util-linux \
  vim-minimal \
  wget \
  which \
  xxd \
  xz \
  zip \
  zstd \
;

########################################

systemd-tmpfiles --create /usr/lib/tmpfiles.d/rootfiles.conf

rm -f /etc/{passwd,shadow,group,gshadow,subuid,subgid}-

rm -f /rootfs/usr/share/cracklib/*.{hwm,pwd,pwi}

find / -mount -depth -newer /etc/BUILDTIME -exec touch --reference=/etc/BUILDTIME --no-create --no-dereference {} \;

RUNEOF

FROM s1-install-packages AS s2-install-gui-base

RUN --mount=from=container-script,target=/tmp/container-script,readonly \
    --mount=type=tmpfs,target=/tmp --mount=type=tmpfs,target=/run \
    --mount=type=tmpfs,target=/var/log \
    --mount=type=cache,from=repo-snapshot,target=/var/cache/dnf --mount=type=tmpfs,target=/var/lib/dnf/repos \
<<RUNEOF
set -eux -o pipefail

/tmp/container-script/dnf-wrapper.sh install \
  --setopt=tsflags=nodocs \
  fontconfig \
  libfontenc \
  mkfontscale \
  ttmkfdir \
  default-fonts-core \
  default-fonts-cjk \
  xorg-x11-fonts-Type1 \
;

/tmp/container-script/dnf-wrapper.sh install \
  --setopt=tsflags=nodocs \
  flatpak \
  wayland-utils \
  xorg-x11-xauth \
  xterm \
;

/tmp/container-script/dnf-wrapper.sh install \
  --setopt=tsflags=nodocs \
  weston \
  xorg-x11-server-Xwayland \
;

rm -f /etc/{passwd,shadow,group,gshadow,subuid,subgid}-

find / -mount -depth -newer /etc/BUILDTIME -exec touch --reference=/etc/BUILDTIME --no-dereference {} \;

RUNEOF


################################################################################

FROM root

ARG DEV_USER_UID=1000
ARG DEV_USER_GID=1000
ARG DEV_USER_NAME=user

COPY --from=s0-install-systemd \
  --exclude=usr/lib/sysimage/rpm/rpmdb.* \
  --exclude=var/lib/dnf/history.* \
  --exclude=var/cache/ldconfig/aux-cache \
  / /

COPY --from=s1-install-packages \
  --exclude=usr/lib/sysimage/rpm/rpmdb.* \
  --exclude=var/lib/dnf/history.* \
  --exclude=var/cache/ldconfig/aux-cache \
  / /

COPY --from=s2-install-gui-base \
  --exclude=usr/lib/sysimage/rpm/rpmdb.* \
  --exclude=var/lib/dnf/history.* \
  --exclude=var/cache/ldconfig/aux-cache \
  --exclude=usr/lib/fontconfig/cache/*.cache* \
  / /

COPY --from=s2-install-gui-base / /


# NOTE: empty "from=" is default context
RUN --mount=from=,target=/tmp/src \
    --mount=type=tmpfs,target=/tmp --mount=type=tmpfs,target=/run \
    --network=none \
<<RUNEOF
set -eux -o pipefail

cp -va /tmp/src/rootfs/* /

export SYSTEMD_OFFLINE=1

systemctl mask \
  sys-kernel-debug.mount \
  sys-kernel-tracing.mount \
  systemd-update-done.service \
  systemd-update-utmp.service \
  systemd-update-utmp-runlevel.service \
  systemd-tpm2-setup.service \
  systemd-tpm2-setup-early.service \
  getty.target \
  console-getty.service \
;

# in case of..
systemctl mask \
  systemd-resolved.service \
  systemd-networkd.service \
  NetworkManager.service \
;

systemctl disable \
  dnf-makecache.timer \
  fstrim.timer \
  fips-crypto-policy-overlay.service \
  sshd.service \
;

systemctl enable \
  tmp.mount \
  sshd.socket \
;

cat <<'EOF' > /etc/ssh/sshd_config.d/0-devcontainer-custom.conf
PasswordAuthentication no
PermitEmptyPasswords no
KbdInteractiveAuthentication no
EOF

ln -s ../../bin/vi /usr/local/bin/vim

cat <<'EOF' >> /etc/skel/.bashrc

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

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

install -d -o "$DEV_USER_UID" -g "$DEV_USER_GID" -m 700 "/home/${DEV_USER_NAME}"/.ssh
install -o "$DEV_USER_UID" -g "$DEV_USER_GID" -m 600 /dev/null "/home/${DEV_USER_NAME}"/.ssh/authorized_keys
install -o "$DEV_USER_UID" -g "$DEV_USER_GID" -m 600 /dev/null "/home/${DEV_USER_NAME}"/.ssh/known_hosts

echo "$DEV_USER_NAME ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/devuser
install -o 0 -g 0 -m 600 /dev/null /var/db/sudo/lectured/"$DEV_USER_UID"

#loginctl enable-linger "$DEV_USER_NAME"  # is not running
mkdir -p /var/lib/systemd/linger
touch /var/lib/systemd/linger/"$DEV_USER_NAME"

runuser -u "$DEV_USER_NAME" -- systemd-tmpfiles --user --create --remove --dry-run

find / -mount -depth -newer /etc/BUILDTIME -exec touch --reference=/etc/BUILDTIME --no-dereference {} \;

RUNEOF


STOPSIGNAL SIGRTMIN+3
CMD ["/sbin/init"]

LABEL devcontainer.metadata='[{ \
  "overrideCommand": false, \
  "capAdd": [ "SYS_PTRACE", "SYS_ADMIN", "MKNOD" ], \
  "remoteUser": "user" \
}]'
