#!/bin/bash

set -eu -o pipefail

main() {
  options=(
    --setopt=cachedir=/var/cache/dnf
    --setopt=keepcache=1
    --setopt=metadata_timer_sync=0
    --setopt=check_config_file_age=0
    --setopt=metadata_expire=never
    --setopt=baseos.metadata_expire=never
    --setopt=appstream.metadata_expire=never
    --setopt=extras.metadata_expire=never
    --setopt=crb.metadata_expire=never
    --setopt=epel.metadata_expire=never
    --setopt=install_weak_deps=0
    --assumeyes
  )

  export LANG=C LC_CTYPE=C.UTF-8 LC_COLLATE=C
  export TZ=UTC

  export SYSTEMD_OFFLINE=1

  set -x
  exec dnf "${options[@]}" "$@"

  return 0
}

main "$@"
exit $?
