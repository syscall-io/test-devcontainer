# syntax=docker/dockerfile:1.19.0@sha256:b6afd42430b15f2d2a4c5a02b919e98a525b785b1aaff16747d2f623364e39b6

FROM stage0 AS root

FROM root AS build

RUN --mount=type=cache,from=repo-snapshot,source=yum,target=/var/cache/yum --mount=type=cache,from=repo-snapshot,source=dnf,target=/var/cache/dnf --mount=type=tmpfs,target=/var/lib/dnf/repos --mount=type=tmpfs,target=/run --mount=type=tmpfs,target=/tmp --mount=type=tmpfs,target=/var/log <<RUNEOF
set -eux -o pipefail

export SYSTEMD_OFFLINE=1

dnf install --setopt=keepcache=1 --setopt=metadata_expire=-1 --assumeyes \
  systemd \
  polkit \
  sudo \
  openssh-server \
;

########################################

echo -n > /etc/machine-id

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

ln -snf multi-user.target /usr/lib/systemd/system/default.target
systemctl set-default multi-user.target

mkdir -p /var/lib/systemd/linger

rm -f /etc/sysconfig/sshd-permitrootlogin /etc/ssh/sshd_config.d/25-permitrootlogin.conf
cat <<'EOF' > /etc/ssh/sshd_config.d/0-devcontainer-custom.conf
PasswordAuthentication no
PermitEmptyPasswords no
KbdInteractiveAuthentication no
EOF

systemctl disable sshd.service
systemctl enable sshd.socket

rm /etc/adjtime.rpmnew

lastest_rpm_build_time=$(rpm -qa --queryformat '%{BUILDTIME}\t%{NAME}-%{VERSION}-%{RELEASE}\n' | sort -n | tail -1 | awk '{print $1}')
date --date=@${lastest_rpm_build_time} '+%Y%m%d_%H%M' > /etc/BUILDTIME
touch -d "@${lastest_rpm_build_time}" /etc/BUILDTIME

find / -mount -depth -newer /etc/BUILDTIME -exec touch --reference=/etc/BUILDTIME --no-dereference {} \;

########################################

RUNEOF

RUN --mount=type=cache,from=repo-snapshot,source=yum,target=/var/cache/yum --mount=type=cache,from=repo-snapshot,source=dnf,target=/var/cache/dnf --mount=type=tmpfs,target=/var/lib/dnf/repos --mount=type=tmpfs,target=/run --mount=type=tmpfs,target=/tmp --mount=type=tmpfs,target=/var/log <<RUNEOF
set -eux -o pipefail

export SYSTEMD_OFFLINE=1

dnf install --setopt=keepcache=1 --setopt=metadata_expire=-1 --assumeyes \
  7zip \
  acl \
  bash-completion \
  cpio \
  diffutils \
  file \
  git-core \
  gnupg2 \
  hostname \
  iproute \
  iputils \
  ldns-utils \
  less \
  lsof \
  make \
  man-db \
  moreutils \
  nmap-ncat \
  openssh-clients \
  perl-interpreter \
  procps-ng \
  psmisc \
  pv \
  ripgrep \
  rsync \
  socat \
  sqlite \
  tmux \
  tree \
  util-linux \
  vim-minimal \
  wget \
  which \
  xxd \
  zip \
;

########################################

lastest_rpm_build_time=$(rpm -qa --queryformat '%{BUILDTIME}\t%{NAME}-%{VERSION}-%{RELEASE}\n' | sort -n | tail -1 | awk '{print $1}')
date --date=@${lastest_rpm_build_time} '+%Y%m%d_%H%M' > /etc/BUILDTIME
touch -d "@${lastest_rpm_build_time}" /etc/BUILDTIME

find / -mount -depth -newer /etc/BUILDTIME -exec touch --reference=/etc/BUILDTIME --no-dereference {} \;

RUNEOF

ADD --chown=0:0 rootfs /

ARG DEV_USER_UID=1000
ARG DEV_USER_GID=1000
ARG DEV_USER_NAME=user

RUN --network=none <<RUNEOF
set -eux -o pipefail

ln -s ../../bin/vi /usr/local/bin/vim

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

install -d -o "$DEV_USER_UID" -g "$DEV_USER_GID" -m 700 "/home/${DEV_USER_NAME}"/.ssh
install -o "$DEV_USER_UID" -g "$DEV_USER_GID" -m 600 /dev/null "/home/${DEV_USER_NAME}"/.ssh/authorized_keys
install -o "$DEV_USER_UID" -g "$DEV_USER_GID" -m 600 /dev/null "/home/${DEV_USER_NAME}"/.ssh/known_hosts

echo "$DEV_USER_NAME ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/devuser
install -o 0 -g 0 -m 600 /dev/null /var/db/sudo/lectured/"$DEV_USER_UID"

#loginctl enable-linger "$DEV_USER_NAME"  # is not running
touch /var/lib/systemd/linger/"$DEV_USER_NAME"

runuser -u "$DEV_USER_NAME" -- systemd-tmpfiles --user  --create --remove --dry-run

find / -mount -depth -newer /etc/BUILDTIME -exec touch --reference=/etc/BUILDTIME --no-dereference {} \;

RUNEOF


################################################################################

FROM root

COPY --from=build \
  --exclude=usr/lib/sysimage/rpm/rpmdb.* \
  --exclude=var/lib/dnf/history.* \
  --exclude=var/cache/ldconfig/aux-cache \
  / /

COPY --from=build / /

STOPSIGNAL SIGRTMIN+3
CMD ["/sbin/init"]

LABEL devcontainer.metadata='[{ \
  "overrideCommand": false, \
  "capAdd": [ "SYS_PTRACE", "SYS_ADMIN", "MKNOD" ], \
  "remoteUser": "user" \
}]'
