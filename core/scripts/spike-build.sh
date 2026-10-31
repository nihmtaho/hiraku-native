#!/usr/bin/env bash
set -eu

root="$(cd "$(dirname "$0")/../.." && pwd)"
out="$root/core/.spike"
mkdir -p "$out"
cd "$root/core"

ios_sdk="$(xcrun --sdk iphoneos --show-sdk-path)"
sim_sdk="$(xcrun --sdk iphonesimulator --show-sdk-path)"
mac_sdk="$(xcrun --sdk macosx --show-sdk-path)"

rm -f "$out/ios_arm64.a"
CC="$(xcrun --sdk iphoneos --find clang)" \
CGO_CFLAGS="-isysroot $ios_sdk -mios-version-min=26.0" \
CGO_LDFLAGS="-isysroot $ios_sdk -mios-version-min=26.0" \
GOOS=ios GOARCH=arm64 CGO_ENABLED=1 \
	go build -buildmode=c-archive -o "$out/ios_arm64.a" ./ffi

rm -f "$out/iossimulator_arm64.a"
CC="$(xcrun --sdk iphonesimulator --find clang)" \
CGO_CFLAGS="-isysroot $sim_sdk -mios-simulator-version-min=26.0" \
CGO_LDFLAGS="-isysroot $sim_sdk -mios-simulator-version-min=26.0" \
GOOS=ios GOARCH=arm64 CGO_ENABLED=1 \
	go build -tags=iossimulator -buildmode=c-archive -o "$out/iossimulator_arm64.a" ./ffi

rm -f "$out/darwin_arm64.a"
CC="$(xcrun --sdk macosx --find clang)" \
CGO_CFLAGS="-isysroot $mac_sdk -mmacosx-version-min=26.0" \
CGO_LDFLAGS="-isysroot $mac_sdk -mmacosx-version-min=26.0" \
MACOSX_DEPLOYMENT_TARGET=26.0 \
GOOS=darwin GOARCH=arm64 CGO_ENABLED=1 \
	go build -buildmode=c-archive -o "$out/darwin_arm64.a" ./ffi
