#!/bin/bash

readonly SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

main() {
  set -eu -o pipefail

  cidfile=$(mktemp)
  trap 'rm -f "$cidfile"' EXIT

  ssh_port=52322

  if ! podman volume exists devcontainer-user-cache; then
    podman volume create --uid $(id -u) --gid $(id -g) devcontainer-user-cache
  fi
  if ! podman volume exists devcontainer-user-local; then
    podman volume create --uid $(id -u) --gid $(id -g) devcontainer-user-local
  fi

  container_image="ghcr.io/syscall-io/test-devcontainer:master"
  args=(
    --cidfile "$cidfile"
    --name devcontainer
    --detach
    --tty
    --cpus 4 --memory 8G
    --user 0
    --systemd always
    --security-opt label=disable
    --cap-add SYS_PTRACE
    --cap-add SYS_ADMIN
    --cap-add MKNOD
    --cap-add NET_RAW,BPF
    --cap-add SYS_RESOURCE
    --cap-add SYS_NICE
    --cap-add IPC_LOCK
    --cap-add PERFMON
    --publish "127.0.0.1:${ssh_port}:22"
    --mount "type=volume,src=devcontainer-user-cache,dst=/home/user/.cache"
    --mount "type=volume,src=devcontainer-user-local,dst=/home/user/.local"
    --volume "${SCRIPT_DIR}/workspace:/workspace:Z"
  )

  (set -x; podman container run "${args[@]}" "$container_image")

  local -r cid=$(< "$cidfile")
  echo "[*] Container ID: ${cid}"

  podman container exec -i --user user "$cid" /bin/bash -c 'umask 0077 && mkdir -p ~/.ssh && cat > ~/.ssh/authorized_keys' < "$SCRIPT_DIR"/authorized_keys

  return 0
}

main "$@"
exit $?
