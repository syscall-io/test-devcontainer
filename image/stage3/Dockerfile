# syntax=docker/dockerfile:1.19.0@sha256:b6afd42430b15f2d2a4c5a02b919e98a525b785b1aaff16747d2f623364e39b6

FROM docker.io/almalinux/10-toolbox:10.0-20250909@sha256:7008515eb22deb3ab06a6f7cefb9e6d561da65a12825364188511ea5a99c03e1 AS toolbox

FROM toolbox AS download-bazelisk
RUN --mount=type=cache,id=download-bazelisk,target=/var/cache/download <<RUNEOF
set -eux -o pipefail

bazelisk_version='1.27.0'
bazelisk_release_ts='2025-08-12T16:32:55Z'

arch=$(rpm --eval '%{_arch}')
case $arch in
  x86_64) goarch='amd64' ; bazelisk_sha256='e1508323f347ad1465a887bc5d2bfb91cffc232d11e8e997b623227c6b32fb76' ;;
  aarch64) goarch='arm64' ; bazelisk_sha256='bb608519a440d45d10304eb684a73a2b6bb7699c5b0e5434361661b25f113a5d' ;;
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


FROM toolbox AS download-uv
RUN --mount=type=cache,id=download-uv,target=/var/cache/download <<RUNEOF
set -eux -o pipefail

uv_version='0.9.2'
uv_release_ts='2025-10-10T19:02:50Z'

arch=$(rpm --eval '%{_arch}')
case $arch in
  x86_64) rust_arch='x86_64-unknown-linux-gnu' ; uv_sha256='b775bb84c72210c6c0b9670cfaad0ac2e3953f12a2947d52b57603b4fbae3798' ;;
  aarch64) rust_arch='aarch64-unknown-linux-gnu' ; uv_sha256='0f0ecf2abcb50f8fb5d2b52c8095af4c133897086e3f2e0259f4fcb3d8ddf273' ;;
  *) echo "Unsupported architecture: $arch" >&2 ; exit 1 ;;
esac


uv_archive="/var/cache/download/${uv_sha256}"

if [[ ! -f "$uv_archive" ]]; then
  chmod 1777 /var/cache/download
  tmpfile=$(runuser -u nobody -- mktemp -p /var/cache/download)
  runuser -u nobody -- curl -fSLo "$tmpfile"  "https://github.com/astral-sh/uv/releases/download/${uv_version}/uv-${rust_arch}.tar.gz"
  echo "${uv_sha256}  ${tmpfile}" | sha256sum -c --strict -
  mv "$tmpfile" "$uv_archive"
fi

tmpdir=$(runuser -u nobody -- mktemp -d)
cd "$tmpdir"

tar xvf "$uv_archive" --strip-components=1
install -o root -g root -m 755 uv uvx /usr/local/bin/
touch --date="${uv_release_ts}" /usr/local/bin/{uv,uvx}

RUNEOF

FROM toolbox AS download-sccache
RUN --mount=type=cache,id=download-sccache,target=/var/cache/download <<RUNEOF
set -eux -o pipefail

sccache_version='0.11.0'
sccache_release_ts='2025-10-10T19:12:27Z'

arch=$(rpm --eval '%{_arch}')
case $arch in
  x86_64) rust_arch='x86_64-unknown-linux-musl' ; sccache_sha256='c861cdb23e83433e1a9929f15b2e829c6f8f82d6e7ea2a6dc188b91e3c3e12fb' ;;
  aarch64) rust_arch='aarch64-unknown-linux-musl' ; sccache_sha256='46aaa502e06fdf3ac4c96f6a58f3579c6f76c6bcb3062098a1101fcffda2d021' ;;
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

cmake_version='4.1.1'
cmake_release_ts='2025-08-27T17:46:25Z'
cmake_version_major='4.1'
cmake_prefix="/usr/local/cmake-${cmake_version_major}"

arch=$(rpm --eval '%{_arch}')
case $arch in
  x86_64) cmake_arch='x86_64' ; cmake_sha256='5a6c61cb62b38e153148a2c8d4af7b3d387f0c8c32b6dbceb5eb4af113efd65a' ;;
  aarch64) cmake_arch='aarch64' ; cmake_sha256='a34bc76b1ebe76ca0bbd6067f68d4614b93221912770dc08f466aec1923e9bef' ;;
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

rustup_version='1.28.2'
rustup_release_ts='2025-05-05T16:01:20Z'

arch=$(rpm --eval '%{_arch}')
case $arch in
  x86_64) rust_arch='x86_64-unknown-linux-gnu' ; rustup_sha256='20a06e644b0d9bd2fbdbfd52d42540bdde820ea7df86e92e533c073da0cdd43c' ;;
  aarch64) rust_arch='aarch64-unknown-linux-gnu' ; rustup_sha256='e3853c5a252fca15252d07cb23a1bdd9377a8c6f3efa01531109281ae47f841c' ;;
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

COPY --link --from=download-bazelisk /usr/local/bin/bazelisk /usr/local/bin/bazel /usr/local/bin/

COPY --link --from=download-uv /usr/local/bin/uv /usr/local/bin/uvx /usr/local/bin/

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

npm install --cache /var/cache/npm --global 'corepack@0.34.0' && rm -rf /root/.npm
python3 -m pip --disable-pip-version-check --cache-dir /var/cache/pip install \
  meson==1.9.1 \
  ninja==1.13.0 \
;

RUNEOF


RUN --network=none --mount=type=tmpfs,target=/tmp <<RUNEOF
set -eux -o pipefail

cmake_version_major=4.1
cmake_prefix="/usr/local/cmake-${cmake_version_major}"

cd /usr/local/bin

ln -s ../"cmake-${cmake_version_major}"/bin/* ./

runuser -u nobody -- python3 --version
runuser -u nobody -- python3 -m pip --version
runuser -u nobody -- java -version

#runuser -u nobody -- bazelisk --version # Skipped: downloads latest bazel
runuser -u nobody -- sccache --version
runuser -u nobody -- cmake --version
runuser -u nobody -- rustup --version
runuser -u nobody -- uv --version
runuser -u nobody -- corepack --version

RUNEOF
