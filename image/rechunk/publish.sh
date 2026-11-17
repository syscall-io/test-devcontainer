#!/bin/bash
set -euo pipefail

if [[ $# -ne 4 ]]; then
  echo 'Usage: publish.sh SOURCE_REF DESTINATION_REF OUTPUT_DIRECTORY BUILDER' >&2
  exit 2
fi
readonly source_ref=$1 destination_ref=$2 output_dir=$(realpath -m "$3") builder=$4
readonly script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "${script_dir}/../build-inputs.env"
mkdir -p "${output_dir}"
docker buildx imagetools inspect "${source_ref}" --format '{{json .Image}}' \
  > "${output_dir}/source-config.json"
python3 - "${output_dir}" <<'PY'
import json, pathlib, sys
root = pathlib.Path(sys.argv[1])
config = json.loads((root / 'source-config.json').read_text())
# Image config formatting may return a platform map for an index.
if 'config' not in config:
    configs = [v for v in config.values() if isinstance(v, dict) and 'config' in v]
    if len(configs) != 1:
        raise ValueError('expected one platform config for the stage3 digest')
    config = configs[0]
(root / 'config.json').write_text(json.dumps({
    'Config': config['config'], 'Architecture': config['architecture'], 'Created': config.get('created'),
}))
PY
docker buildx build --builder "${builder}" \
  --build-context "stage3=docker-image://${source_ref}" \
  --build-arg "CHUNKAH_CONFIG_STR=$(cat "${output_dir}/config.json")" \
  --build-arg "MAX_LAYERS=${MAX_LAYERS:-64}" \
  --output "type=local,dest=${output_dir}/rechunk" --progress=plain "${script_dir}"
python3 "${script_dir}/oci.py" "${output_dir}/rechunk" \
  --config "${output_dir}/config.json" > "${output_dir}/layers.json"

# regctl reads the existing Docker login, and preserves OCI layer annotations.
docker run --rm --user=0:0 --env DOCKER_CONFIG=/auth \
  --mount "type=bind,src=${DOCKER_CONFIG:-${HOME}/.docker},dst=/auth,readonly" \
  --mount "type=bind,src=${output_dir}/rechunk/image,dst=/image,readonly" \
  "${REGCTL_IMAGE}" image copy ocidir:///image:rechunked "${destination_ref}"
python3 - "${output_dir}" <<'PY'
import json, pathlib, sys
root = pathlib.Path(sys.argv[1])
digest = json.loads((root / 'layers.json').read_text())['digest']
(root / 'metadata.json').write_text(json.dumps({'containerimage.digest': digest}))
PY
