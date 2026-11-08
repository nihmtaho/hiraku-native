#!/bin/sh
# Fails when a Swift feature or package imports across a boundary AGENTS.md forbids.
set -eu

cd "$(dirname "$0")/.."

status=0
fail() {
	echo "check-imports: $1" >&2
	status=1
}

for file in $(find Packages/Features -name '*.swift' 2>/dev/null); do
	for module in $(sed -n 's/^[[:space:]]*import[[:space:]]\{1,\}\([A-Za-z0-9_]*\).*/\1/p' "$file"); do
		case "$module" in
		SwiftUI|Foundation|Observation|HirakuModels|DesignSystem|StudyKit|HirakuTesting) ;;
		Feature*) fail "feature imports another feature: $file ($module)" ;;
		HirakuBridge) fail "feature imports HirakuBridge: $file" ;;
		esac
	done
done

exit "$status"
