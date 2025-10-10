#!/bin/bash

readonly SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

main() {
  set -eu -o pipefail

  cidfile=$(mktemp)
  trap 'rm -f "$cidfile"' EXIT

  ssh_port=52322


  # FIXME: volume ownership is root:root, not user:user
  if ! container volume inspect devcontainer-user-cache >& /dev/null; then
    container volume create devcontainer-user-cache
  fi
  if ! container volume inspect devcontainer-user-local >& /dev/null; then
    container volume create devcontainer-user-local
  fi

  container_image="ghcr.io/hsw0/test-devcontainer:master"
  args=(
    --cidfile "$cidfile"
    --name devcontainer
    --detach
    --tty
    --cpus 4 --memory 8G
    --user 0
    --publish "127.0.0.1:${ssh_port}:22"
    --mount "type=volume,src=devcontainer-user-cache,dst=/home/user/.cache"
    --mount "type=volume,src=devcontainer-user-local,dst=/home/user/.local"
    --volume "${SCRIPT_DIR}/workspace:/workspace"
  )

  (set -x; container run "${args[@]}" "$container_image")

  local -r cid=$(< "$cidfile")
  echo "[*] Container ID: ${cid}"

  local -r container_cidr=$(container inspect "$cid" | jq -r '.[0].networks[0].address')
  local -r container_address=${container_cidr%/*}
  echo "[*] Container address: ${container_address}"

  container exec -i --user user "$cid" /bin/bash -c 'umask 0077 && mkdir -p ~/.ssh && cat > ~/.ssh/authorized_keys' < "$SCRIPT_DIR"/authorized_keys

  return 0
}

main "$@"
exit $?
