#!/usr/bin/env python3
"""Inspect the publishable OCI image and enforce its component boundaries."""
import argparse
import hashlib
import json
import pathlib
import sys

CONFIG_FIELDS = (
    "User", "Env", "Entrypoint", "Cmd", "WorkingDir", "Labels", "StopSignal",
    "ExposedPorts", "Volumes",
)


def inspect_image(path, source_config, package_groups):
    root = pathlib.Path(path)
    if (root / "image/oci-layout").exists():
        root /= "image"

    def blob(digest):
        algorithm, value = digest.split(":", 1)
        if algorithm != "sha256" or len(value) != 64 or any(c not in "0123456789abcdef" for c in value):
            raise ValueError("unsupported or malformed OCI digest")
        data = (root / "blobs/sha256" / value).read_bytes()
        if hashlib.sha256(data).hexdigest() != value:
            raise ValueError(f"corrupt OCI metadata: {digest}")
        return json.loads(data)

    index = json.loads((root / "index.json").read_text())
    if len(index["manifests"]) != 1:
        raise ValueError("expected one rechunked platform image")
    digest = index["manifests"][0]["digest"]
    manifest = blob(digest)
    config = blob(manifest["config"]["digest"])
    changed = [k for k in CONFIG_FIELDS
               if (config["config"].get(k) or None) != (source_config["Config"].get(k) or None)]
    if changed or config["architecture"] != source_config["Architecture"]:
        raise ValueError(f"rechunking changed runtime configuration: {changed or ['Architecture']}")

    separate = {"xattr/mutable", *(f"xattr/{name}" for name in package_groups)}
    layers = {}
    for layer in manifest["layers"]:
        name = layer.get("annotations", {}).get("org.chunkah.component")
        if not name or name in layers:
            raise ValueError("missing or duplicate layer component annotations")
        members = name.split()
        if separate.intersection(members) and len(members) != 1:
            raise ValueError(f"explicit component was merged with other components: {name}")
        layers[name] = {"digest": layer["digest"], "size": layer["size"]}
    if missing := separate.difference(layers):
        raise ValueError(f"missing dedicated component layers: {sorted(missing)}")
    return {"digest": digest, "layer_count": len(layers),
            "compressed_bytes": sum(x["size"] for x in layers.values()), "layers": layers}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("image")
    parser.add_argument("--config", required=True)
    args = parser.parse_args()
    try:
        source = json.loads(pathlib.Path(args.config).read_text())
        groups = json.loads(pathlib.Path(__file__).with_name("package-groups.json").read_text())
        print(json.dumps(inspect_image(args.image, source, groups), indent=2))
    except (ValueError, KeyError, OSError) as error:
        print(f"OCI inspection failed: {error}", file=sys.stderr)
        sys.exit(1)
