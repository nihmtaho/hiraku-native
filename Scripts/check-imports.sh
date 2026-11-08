#!/bin/sh
# Fails when a Swift feature imports outside the allowlist in ARCHITECTURE §4.1.
set -eu

cd "$(dirname "$0")/.."

status=0
fail() {
	echo "check-imports: $1" >&2
	status=1
}

for file in $(find Packages/Features -path '*/Sources/*' -name '*.swift' 2>/dev/null); do
	feature=$(echo "$file" | sed -n 's|Packages/Features/\([^/]*\)/.*|\1|p')
	for module in $(sed -nE 's/^[[:space:]]*(@testable[[:space:]]+)?import[[:space:]]+([A-Za-z0-9_]+).*/\1\2/p' "$file"); do
		case "$module" in
		@testable*) fail "testable import in feature: $file ($module)" ;;
		SwiftUI|Foundation|Observation|HirakuModels|DesignSystem) ;;
		StudyKit)
			case "$feature" in
			FeatureStudy|FeatureFlashcard|FeatureTyping) ;;
			*) fail "StudyKit outside study features: $file" ;;
			esac
			;;
		*) fail "feature imports $module: $file" ;;
		esac
	done
done

exit "$status"
