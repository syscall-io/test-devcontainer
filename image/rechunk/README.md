# Content-based package layers

Stages 0–3 construct the filesystem and retain installation/download cache
boundaries. `Dockerfile` packages the finished filesystem with pinned chunkah
v0.7.1. Unspecified RPM files use chunkah's source-RPM grouping.

## Functional package groups

Edit `package-groups.json` to assign installed RPM payloads to named components.
The initial groups are Java (`java-*-openjdk*`, `javapackages-*`) and X11
(`libX*`, `libxcb*`, `xorg-x11-*`, and related packages). Each rule contains
package-name glob patterns, optional dedicated paths, and an update interval.

`components.py` queries the RPM database for file ownership and sets
`user.component` and `user.update-interval` xattrs. It tags regular package
files, avoiding shared directories and generated mutable files. Explicit
`paths` tag a dedicated tree and include its symlinks through inheritance;
do not list shared trees such as `/usr/lib64` or `/usr/share`.

Linux does not support user xattrs directly on symlinks. Package symlinks
outside dedicated trees retain chunkah's RPM grouping. Thus these rules group
the main package payloads rather than moving every RPM-owned path verbatim.

Chunkah can merge components when packing to its layer budget. The publisher
rejects an output where a configured functional component is missing or shares
a layer with another component. Increase `MAX_LAYERS` or adjust the policy if
this happens; its default is 64. `layers.json` records the final component map.

Non-RPM tools keep separate named components where practical. Generated state
(RPM databases, DNF history, ldconfig/fontconfig and other caches) is assigned
to `xattr/mutable`, which must also remain an independent layer.

## Publishing and inputs

The image config is passed from stage3, preserving the systemd command, stop
signal, environment and devcontainer metadata. The snapshot's `/etc/BUILDEPOCH`
anchors timestamp clamping. Outputs are gzip OCI layers, replacing eStargz.

`image/build-inputs.env` pins the repository snapshot, BuildKit and registry
client. Update the snapshot digest deliberately when changing the package
universe. The snapshot stores repository metadata, not RPM payloads; retain the
referenced RPMs in a mirror or artifact store for long-term rebuildability.

The publishing workflow exports the OCI layout, enforces component boundaries
and runtime configuration, then copies it with pinned regctl using the existing
Docker registry login. Manifest merging and provenance use the resulting digest.
