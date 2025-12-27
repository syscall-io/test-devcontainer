# syntax=docker/dockerfile:1.20.0@sha256:26147acbda4f14c5add9946e2fd2ed543fc402884fd75146bd342a7f6271dc1d

FROM docker.io/almalinux/10-toolbox:10.1-20251124@sha256:5c733ba41634d8b760a437d43fb92d202ea33821d832b91656ad16e59ee30dc5 AS toolbox

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

uv_version='0.9.18'
uv_release_ts='2025-12-16T15:47:46Z'

arch=$(rpm --eval '%{_arch}')
case $arch in
  x86_64) rust_arch='x86_64-unknown-linux-gnu' ; uv_sha256='c2def3db178ade63933fa15ffc96e882c196ce53e06173dcee05b36c5f6f68f5' ;;
  aarch64) rust_arch='aarch64-unknown-linux-gnu' ; uv_sha256='f8e23ec786b18660ade6b033b6191b7e9c283c872eeb8c4531d56a873decf160' ;;
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

sccache_version='0.12.0'
sccache_release_ts='2025-10-20T22:38:10Z'

arch=$(rpm --eval '%{_arch}')
case $arch in
  x86_64) rust_arch='x86_64-unknown-linux-musl' ; sccache_sha256='b0e89ead6899224a4ba2b90e9073bf1ce036d95bab30f3dc33c1e1468bc4ad44' ;;
  aarch64) rust_arch='aarch64-unknown-linux-musl' ; sccache_sha256='111ddd28fb108cb3e17edb69ab62cefe1dcc97b02e5006ff9c1330f4f2e78368' ;;
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

cmake_version='4.1.2'
cmake_release_ts='2025-09-30T16:00:04Z'
cmake_version_major='4.1'
cmake_prefix="/usr/local/cmake-${cmake_version_major}"

arch=$(rpm --eval '%{_arch}')
case $arch in
  x86_64) cmake_arch='x86_64' ; cmake_sha256='773cc679c3a7395413bd096523f8e5d6c39f8718af4e12eb4e4195f72f35e4ab' ;;
  aarch64) cmake_arch='aarch64' ; cmake_sha256='0634996f918b3bab11f45522899c81c987b09c9a64d15f6a0d2bb51c42099534' ;;
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
python3.13 -m pip --disable-pip-version-check --cache-dir /var/cache/pip install \
  meson==1.9.1 \
  ninja==1.13.0 \
;

find / -mount -depth -newer /etc/BUILDTIME -exec touch --reference=/etc/BUILDTIME --no-create --no-dereference {} \;

RUNEOF


RUN --network=none --mount=type=tmpfs,target=/tmp <<RUNEOF
set -eux -o pipefail

cmake_version_major=4.1
cmake_prefix="/usr/local/cmake-${cmake_version_major}"

cd /usr/local/bin

ln -s ../"cmake-${cmake_version_major}"/bin/* ./

runuser -u nobody -- python3.13 --version
runuser -u nobody -- python3.13 -m pip --version
runuser -u nobody -- java -version

#runuser -u nobody -- bazelisk --version # Skipped: downloads latest bazel
runuser -u nobody -- sccache --version
runuser -u nobody -- cmake --version
runuser -u nobody -- rustup --version
runuser -u nobody -- uv --version
runuser -u nobody -- corepack --version

RUNEOF
