#!/bin/bash

readonly SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
readonly BUILD_DIR=$(realpath "$SCRIPT_DIR"/../build)

readonly buildkit_image='docker.io/moby/buildkit:v0.25.0@sha256:faffcac91decfb3b981234bf2762d88ed6c90771b689a3d8a5049cd0e874759a'

readonly REGISTRY_PORT=51350
readonly REGISTRY_HOST="localhost:${REGISTRY_PORT}"

readonly run_id=$(date +%s)

BUILDX_CMD=''
builder_instance=''
registry_instance=''


_cleanup() {
  echo "[*] Cleaning up builder instance..."

  (set -x; $BUILDX_CMD rm -f "$builder_instance") || :

  (set -x; docker container stop "$registry_instance") || :
}

build_image() {
  local -r name="$1"
  shift
  local extra_args=("$@")

  echo "[*] Building ${name}..."

  mkdir -p "${BUILD_DIR}/${name}"

  (set -x;
  $BUILDX_CMD build \
   --builder "$builder_instance" \
   --tag "${REGISTRY_HOST}/tmp/${name}:latest" \
   --tag "${REGISTRY_HOST}/tmp/${name}:run-${run_id}" \
   --output "type=registry,name-canonical=true,oci-mediatypes=true,oci-artifact=true,compression=estargz,store=false" \
   --iidfile "$BUILD_DIR"/"$name"/image-id \
   --metadata-file "${BUILD_DIR}"/"$name"/metadata.json \
   --cache-to "type=registry,ref=${REGISTRY_HOST}/tmp/${name}-cache,mode=max" \
   --cache-from "type=registry,ref=${REGISTRY_HOST}/tmp/${name}-cache" \
   --build-context repo-snapshot="docker-image://ghcr.io/hsw0/almalinux-repo-snapshot:latest" \
   --progress plain \
   "${extra_args[@]}" \
   "${SCRIPT_DIR}/${name}/" \
  ;)
}

main () {
  set -eu -o pipefail

  trap '_cleanup' EXIT

  readonly BUILDX_CMD="docker-buildx"
  readonly builder_instance=tmp-builder-$run_id
  readonly registry_instance=tmp-registry-$run_id

  mkdir -p "$BUILD_DIR"/registry

  echo "[*] Starting ephemeral registry..."
  (set -x;
  docker container run \
    --name "$registry_instance" \
    --rm \
    --detach \
    --publish "127.0.0.1:$REGISTRY_PORT:5000" \
    --volume "${BUILD_DIR}/registry:/var/lib/registry:Z" \
    docker.io/library/registry:3.0.0@sha256:3725021071ec9383eb3d87ddbdff9ed602439b3f7c958c9c2fb941049ea6531d \
  ;)

  echo "[*] Starting ephemeral builder..."
  (set -x;
  $BUILDX_CMD create --name "$builder_instance" \
    --bootstrap \
    --driver docker-container \
    --driver-opt image="$buildkit_image" \
    --driver-opt network=host \
    --buildkitd-flags "--oci-worker-snapshotter=stargz" \
  ;)

  $BUILDX_CMD inspect --builder "$builder_instance"

  export SOURCE_DATE_EPOCH=0

  build_image stage0

  build_image stage1 \
    --build-context stage0="docker-image://${REGISTRY_HOST}/tmp/stage0:run-${run_id}" \
  ;

  build_image stage2 \
    --build-context stage1="docker-image://${REGISTRY_HOST}/tmp/stage1:run-${run_id}" \
  ;

  build_image stage3 \
    --build-context stage0="docker-image://${REGISTRY_HOST}/tmp/stage0:run-${run_id}" \
    --build-context stage2="docker-image://${REGISTRY_HOST}/tmp/stage2:run-${run_id}" \
  ;


  return 0
}

main "$@"
exit $?
