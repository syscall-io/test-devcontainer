#!/bin/bash

readonly SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

main() {
  set -eu -o pipefail

  cidfile=$(mktemp)
  trap 'rm -f "$cidfile"' EXIT

  (set -x; container run \
    --cidfile "$cidfile" \
    --name devcontainer \
    --detach \
    --tty \
    --cpus 2 --memory 4G \
    ghcr.io/hsw0/test-devcontainer/tmp@sha256:df28c6b821c654443ffe0dc663cdfd04e8479abad8ec562f287a68ac19682223 \
  ;)

  local -r cid=$(< "$cidfile")
  echo "[*] Container ID: ${cid}"

  # 192.168.64.19/24
  local -r container_cidr=$(container inspect devcontainer | jq -r '.[0].networks[0].address')
  local -r container_address=${container_cidr%/*}
  echo "[*] Container address: ${container_address}"

  container exec -i --user user devcontainer /bin/bash -c 'cat > ~/.ssh/authorized_keys' < "$SCRIPT_DIR"/authorized_keys

  return 0
}

main "$@"
exit $?
