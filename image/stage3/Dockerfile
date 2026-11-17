# syntax=docker/dockerfile:1.29.0@sha256:572cebbc2b15e6f84c077742952674889cb63cd5e9b80abdffcbe587b6f19183

ARG UV_IMG=ghcr.io/astral-sh/uv:0.13.8@sha256:5cc1805e2426484abca4ad46ea783bab281fdb225fd82d8ce6d66a81254bac85

FROM docker.io/almalinux/10-toolbox:10.3-20261116@sha256:6e37c1eae6c57189c8d90bd6b35497405df34e1f766ea7e6498e4afbb98a5e4f AS toolbox

FROM toolbox AS download-bazelisk
RUN --mount=type=cache,id=download-bazelisk,target=/var/cache/download <<RUNEOF
set -eux -o pipefail

bazelisk_version='1.30.0'
bazelisk_release_ts='2026-10-20T23:17:24Z'

arch=$(rpm --eval '%{_arch}')
case $arch in
  x86_64) goarch='amd64' ; bazelisk_sha256='a248ae2b2b62b5baebb748f6fba7203bff1a27e5d01b55399a8406744cb539e8' ;;
  aarch64) goarch='arm64' ; bazelisk_sha256='b2bcc040c213b44586b121bda6d983c35df121b917c3a7a66fb16f2fa0df1a4f' ;;
  *) echo "Unsupported architecture: $arch" >&2 ; exit 1 ;;
esac

bazelisk_archive="/var/cache/download/${bazelisk_sha256}"

if [[ ! -f "$bazelisk_archive" ]]; then
  chmod 1777 /var/cache/download
  tmpfile=$(runuser -u nobody -- mktemp -p /var/cache/download)
  runuser -u nobody -- curl -fSLo "$tmpfile" "https://github.com/bazelbuild/bazelisk/releases/download/v${bazelisk_version}/bazelisk-linux-${goarch}"
  echo "${bazelisk_sha256}  ${tmpfile}" | sha256sum -c --strict -
  mv "$tmpfile" "$bazelisk_archive"
fi


install -o root -g root -m 755 "$bazelisk_archive" /usr/local/bin/bazelisk
ln -s bazelisk /usr/local/bin/bazel

touch --date="${bazelisk_release_ts}" /usr/local/bin/{bazelisk,bazel}

RUNEOF

FROM ${UV_IMG} AS download-uv

FROM toolbox AS download-sccache
RUN --mount=type=cache,id=download-sccache,target=/var/cache/download <<RUNEOF
set -eux -o pipefail

sccache_version='0.19.0'
sccache_release_ts='2026-10-24T10:25:17Z'

arch=$(rpm --eval '%{_arch}')
case $arch in
  x86_64) rust_arch='x86_64-unknown-linux-musl' ; sccache_sha256='aa73c7270c997894038c0d8f0d297865f57569e1687883322bc431713d4bb9dd' ;;
  aarch64) rust_arch='aarch64-unknown-linux-musl' ; sccache_sha256='3e47fc4a71b1ddd1b4294a0de9d34498922fdf41e3cd0bda5df3954e3d6deb9d' ;;
  *) echo "Unsupported architecture: $arch" >&2 ; exit 1 ;;
esac

sccache_archive="/var/cache/download/${sccache_sha256}"

if [[ ! -f "$sccache_archive" ]]; then
  chmod 1777 /var/cache/download
  tmpfile=$(runuser -u nobody -- mktemp -p /var/cache/download)
  runuser -u nobody -- curl -fSLo "$tmpfile" "https://github.com/mozilla/sccache/releases/download/v${sccache_version}/sccache-v${sccache_version}-${rust_arch}.tar.gz"
  echo "${sccache_sha256}  ${tmpfile}" | sha256sum -c --strict -
  mv "$tmpfile" "$sccache_archive"
fi

tmpdir=$(runuser -u nobody -- mktemp -d)
cd "$tmpdir"

tar xvf "$sccache_archive" --strip-components=1
install -o root -g root -m 755 sccache /usr/local/bin/

touch --date="${sccache_release_ts}" /usr/local/bin/sccache

RUNEOF


FROM toolbox AS download-cmake
RUN --mount=type=cache,id=download-cmake,target=/var/cache/download <<RUNEOF
set -eux -o pipefail

cmake_version='4.5.0'
cmake_release_ts='2026-11-12T18:53:08Z'
cmake_version_major='4.5'
cmake_prefix="/usr/local/cmake-${cmake_version_major}"

arch=$(rpm --eval '%{_arch}')
case $arch in
  x86_64) cmake_arch='x86_64' ; cmake_sha256='81f0d5b0960fb6adc8197030ffc827fba937640d51e73e39e0e9e40d88c66f6f' ;;
  aarch64) cmake_arch='aarch64' ; cmake_sha256='0c8447e7bba9701467b5ac6155d157aa9e309e71af4981f78bd4b9176107f553' ;;
  *) echo "Unsupported architecture: $arch" >&2 ; exit 1 ;;
esac

cmake_archive="/var/cache/download/${cmake_sha256}"

if [[ ! -f "$cmake_archive" ]]; then
  chmod 1777 /var/cache/download
  tmpfile=$(runuser -u nobody -- mktemp -p /var/cache/download)
  runuser -u nobody -- curl -fSLo "$tmpfile" "https://github.com/Kitware/CMake/releases/download/v${cmake_version}/cmake-${cmake_version}-linux-${cmake_arch}.tar.gz"
  echo "${cmake_sha256}  ${tmpfile}" | sha256sum -c --strict -
  mv "$tmpfile" "$cmake_archive"
fi

mkdir -p "$cmake_prefix"

gzip -dc "$cmake_archive" | tar x --directory="$cmake_prefix" --no-same-owner --strip-components=1
rm -rf "$cmake_prefix/share/cmake-$cmake_version_major"/Help
rm -rf "$cmake_prefix"/share/{applications,icons,emacs}
rm -rf "$cmake_prefix"/doc
rm -rf "$cmake_prefix"/bin/{ccmake,cmake-gui}

find "$cmake_prefix" -mount -depth -exec touch --date="${cmake_release_ts}" --no-create --no-dereference {} \;

RUNEOF


FROM toolbox AS download-rust

ENV RUSTUP_HOME=/usr/local/rustup
ENV CARGO_HOME=/usr/local/cargo
ENV PATH="$PATH:$CARGO_HOME/bin"

RUN --mount=type=cache,id=download-rustup,target=/var/cache/download <<RUNEOF
set -eux -o pipefail

rustup_version='1.29.3'
rustup_release_ts='2026-11-03T16:29:35Z'

arch=$(rpm --eval '%{_arch}')
case $arch in
  x86_64) rust_arch='x86_64-unknown-linux-gnu' ; rustup_sha256='b1c8cb14e30889e7e2999e6b69e62d9e9b9ffc0f4df8180564d306d9680e6c55' ;;
  aarch64) rust_arch='aarch64-unknown-linux-gnu' ; rustup_sha256='9f608c142e0e38a78957d0661ba1dfaf0b6fb37184cfaa4b9a0aa57af6184282' ;;
  *) echo "Unsupported architecture: $arch" >&2 ; exit 1 ;;
esac

rustup_archive="/var/cache/download/${rustup_sha256}"

if [[ ! -f "$rustup_archive" ]]; then
  chmod 1777 /var/cache/download
  tmpfile=$(runuser -u nobody -- mktemp -p /var/cache/download)
  runuser -u nobody -- curl -fSLo "$tmpfile" "https://static.rust-lang.org/rustup/archive/${rustup_version}/${rust_arch}/rustup-init"
  echo "${rustup_sha256}  ${tmpfile}" | sha256sum -c --strict -
  mv "$tmpfile" "$rustup_archive"
fi

cd /tmp/

install "$rustup_archive" rustup-init
./rustup-init -y --verbose --no-modify-path --profile minimal --default-host "$rust_arch" --default-toolchain none

rm -rf -- "$RUSTUP_HOME"/toolchains/*/share/doc

find "$RUSTUP_HOME" "$CARGO_HOME" -mount -depth -exec touch --date="${rustup_release_ts}" --no-create --no-dereference {} \;


RUNEOF

################################################################################

FROM stage2

COPY --link --from=download-bazelisk /usr/local/bin/bazelisk /usr/local/bin/

COPY --link --chown=0:0 --chmod=0755 --from=download-uv /uv /uvx /usr/local/bin/

COPY --link --from=download-sccache /usr/local/bin/sccache /usr/local/bin/

COPY --link --from=download-cmake /usr/local/ /usr/local/


ENV RUSTUP_HOME=/usr/local/rustup CARGO_HOME=/usr/local/cargo RUSTC_WRAPPER=/usr/local/bin/sccache
ENV PATH="$PATH:$CARGO_HOME/bin"

COPY --link --from=download-rust "$CARGO_HOME" "$CARGO_HOME"
COPY --link --from=download-rust "$RUSTUP_HOME" "$RUSTUP_HOME"

ENV DOTNET_CLI_TELEMETRY_OPTOUT=1


RUN --mount=type=tmpfs,target=/tmp --mount=type=cache,target=/var/cache/npm --mount=type=cache,target=/var/cache/pip <<RUNEOF
set -eux -o pipefail

export SOURCE_DATE_EPOCH=0

python3.14 -m pip --disable-pip-version-check --cache-dir /var/cache/pip install \
  meson==1.12.1 \
  ninja==1.13.2 \
;

find / -mount -depth -newer /etc/BUILDTIME -exec touch --reference=/etc/BUILDTIME --no-create --no-dereference {} \;

RUNEOF


RUN --network=none --mount=type=tmpfs,target=/tmp <<RUNEOF
set -eux -o pipefail

cmake_version_major=4.5
cmake_prefix="/usr/local/cmake-${cmake_version_major}"

cd /usr/local/bin

ln -s ../"cmake-${cmake_version_major}"/bin/* ./
ln -s bazelisk bazel

runuser -u nobody -- python3.14 --version
runuser -u nobody -- python3.14 -m pip --version
runuser -u nobody -- java -version

#runuser -u nobody -- bazelisk --version # Skipped: downloads latest bazel
runuser -u nobody -- sccache --version
runuser -u nobody -- cmake --version
runuser -u nobody -- rustup --version
runuser -u nobody -- uv --version

RUNEOF
