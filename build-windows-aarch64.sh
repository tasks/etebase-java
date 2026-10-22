#!/usr/bin/env bash

set -euo pipefail

LIBSODIUM_VERSION=1.0.22
LIBSODIUM_URL=https://github.com/jedisct1/libsodium/releases/download/$LIBSODIUM_VERSION-RELEASE/libsodium-$LIBSODIUM_VERSION.tar.gz
LIBSODIUM_SHA256=adbdd8f16149e81ac6078a03aca6fc03b592b89ef7b5ed83841c086191be3349

TARGET=aarch64-pc-windows-gnullvm
ZIG_TARGET=aarch64-windows-gnu

cd "$(dirname "$0")"
root=$(pwd)
zig=(${ZIG:-zig})
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

curl -fsSL --retry 5 --retry-all-errors -o "$work/libsodium.tar.gz" "$LIBSODIUM_URL"
echo "$LIBSODIUM_SHA256  $work/libsodium.tar.gz" | sha256sum -c
tar -xzf "$work/libsodium.tar.gz" -C "$work"

sodium="$root/target/$TARGET/libsodium"
rm -rf "$sodium"
(
    cd "$work/libsodium-$LIBSODIUM_VERSION"
    "${zig[@]}" build -Dtarget=$ZIG_TARGET -Doptimize=ReleaseFast -Dshared=false -Dtest=false --prefix "$sodium"
)
cp "$sodium/lib/libsodium-static.lib" "$sodium/lib/libsodium.a"

SODIUM_LIB_DIR="$sodium/lib" cargo zigbuild --locked --target $TARGET --release --no-default-features --features jvm

lib="target/$TARGET/release/etebase_jni.dll"
file "$lib" | grep -q "PE32+ executable (DLL).*Aarch64" || { file "$lib" >&2; echo "expected an ARM64 DLL" >&2; exit 1; }
echo "$root/$lib"
