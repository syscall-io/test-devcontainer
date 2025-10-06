# syntax=docker/dockerfile:1.19.0@sha256:b6afd42430b15f2d2a4c5a02b919e98a525b785b1aaff16747d2f623364e39b6

FROM stage0

RUN --mount=type=cache,target=/var/cache/yum --mount=type=cache,target=/var/cache/dnf --mount=type=cache,target=/var/lib/dnf/repos --mount=type=tmpfs,target=/run --mount=type=tmpfs,target=/tmp --mount=type=tmpfs,target=/var/log <<RUNEOF
set -eux -o pipefail

export SYSTEMD_OFFLINE=1

dnf install --setopt=keepcache=1 --assumeyes \
  systemd polkit \
  sudo \
  util-linux \
  moreutils \
  diffutils \
  procps-ng psmisc lsof \
  which file less xxd tree \
  ripgrep \
  pv \
  iputils iproute hostname \
  socat nmap-ncat \
  wget rsync openssh-clients ldns-utils \
  git-core \
  sqlite \
  gnupg2 \
  zip cpio 7zip \
  tmux \
  man-db \
  perl-interpreter \
  vim-enhanced \
  bash-completion \
  make \
;

########################################

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


ln -s vim /usr/bin/vi

########################################

lastest_rpm_build_time=$(rpm -qa --queryformat '%{BUILDTIME}\t%{NAME}-%{VERSION}-%{RELEASE}\n' | sort -n | tail -1 | awk '{print $1}')
date --date=@${lastest_rpm_build_time} '+%Y%m%d_%H%M' > /etc/BUILDTIME
touch -d "@${lastest_rpm_build_time}" /etc/BUILDTIME

find / -mount -depth -newer /etc/BUILDTIME -exec touch --reference=/etc/BUILDTIME --no-dereference {} \;

RUNEOF

STOPSIGNAL SIGRTMIN+3
CMD ["/sbin/init"]
