#!/usr/bin/env bash
# Builds the three c-archive slices (same discipline as spike-build.sh) and
# packages them into Frameworks/HirakuCore.xcframework with headers.
set -eu

root="$(cd "$(dirname "$0")/../.." && pwd)"
out="$root"
fw="$root/Frameworks/HirakuCore.xcframework"
hdr="$root/Frameworks/include"

bash "$root/core/scripts/spike-build.sh"

mkdir -p "$hdr"
cp "$root/core/ffi/include/hk.h" "$root/core/ffi/include/module.modulemap" "$hdr/"

rm -rf "$fw"
xcodebuild -create-xcframework \
	-library "$out/core/.spike/darwin_arm64.a" -headers "$hdr" \
	-library "$out/core/.spike/iossimulator_arm64.a" -headers "$hdr" \
	-library "$out/core/.spike/ios_arm64.a" -headers "$hdr" \
	-output "$fw" >/dev/null

echo "created $fw"
find "$fw" -maxdepth 2 -print | sort
du -sh "$fw"
