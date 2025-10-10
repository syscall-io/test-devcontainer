#!/bin/bash

readonly SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

main() {
  set -eu -o pipefail

  if command docker version | grep -q 'Client:\s*Podman Engine' ; then
    echo "[!] Podman detected. use start-podman.sh ." >&2
    return 1
  fi

  cidfile=$(mktemp)
  trap 'rm -f "$cidfile"' EXIT

  ssh_port=52322

    # FIXME: volume ownership is root:root, not user:user

  if ! docker volume inspect devcontainer-user-cache >& /dev/null; then
    docker volume create devcontainer-user-cache
  fi
  if ! docker volume exists devcontainer-user-local >& /dev/null; then
    docker volume create devcontainer-user-local
  fi

  container_image="ghcr.io/hsw0/test-devcontainer:master"
  args=(
    --cidfile "$cidfile"
    --name devcontainer
    --detach
    --tty
    --cpus 4
    --memory 8G
    --user 0
    --privileged
    --publish "127.0.0.1:${ssh_port}:22"
    --mount "type=volume,src=devcontainer-user-cache,dst=/home/user/.cache"
    --mount "type=volume,src=devcontainer-user-local,dst=/home/user/.local"
    --volume "${SCRIPT_DIR}/workspace:/workspace:Z"
  )

  rm -f "$cidfile"
  (set -x; docker container run "${args[@]}" "$container_image")

  local -r cid=$(< "$cidfile")
  echo "[*] Container ID: ${cid}"

  docker container exec -i --user user "$cid" /bin/bash -c 'umask 0077 && mkdir -p ~/.ssh && cat > ~/.ssh/authorized_keys' < "$SCRIPT_DIR"/authorized_keys

  return 0
}

main "$@"
exit $?
