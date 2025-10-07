#!/bin/bash

readonly SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

main() {
  set -eu -o pipefail

  cidfile=$(mktemp)
  trap 'rm -f "$cidfile"' EXIT

  ssh_port=52322

  (set -x; container run \
    --cidfile "$cidfile" \
    --name devcontainer \
    --detach \
    --tty \
    --cpus 4 --memory 8G \
    --publish "127.0.0.1:${ssh_port}:22" \
    --volume "${SCRIPT_DIR}/workspace:/workspace" \
    --volume "${SCRIPT_DIR}/home/.cache:/home/user/.cache" \
    --volume "${SCRIPT_DIR}/home/.config:/home/user/.config" \
    ghcr.io/hsw0/test-devcontainer:master \
  ;)

  local -r cid=$(< "$cidfile")
  echo "[*] Container ID: ${cid}"

  local -r container_cidr=$(container inspect devcontainer | jq -r '.[0].networks[0].address')
  local -r container_address=${container_cidr%/*}
  echo "[*] Container address: ${container_address}"

  container exec -i --user user devcontainer /bin/bash -c 'cat > ~/.ssh/authorized_keys' < "$SCRIPT_DIR"/authorized_keys

  return 0
}

main "$@"
exit $?
