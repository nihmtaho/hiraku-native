#!/bin/sh
# Fails when Swift packages import outside the allowlists in ARCHITECTURE §4.1.
set -eu

cd "$(dirname "$0")/.."

status=0
fail() {
	echo "check-imports: $1" >&2
	status=1
}

check_package() {
	dir=$1
	pattern=$2
	for file in $(find "$dir" -path '*/Sources/*' -name '*.swift' 2>/dev/null); do
		case "$file" in
		*/Generated/*) continue ;;
		esac
		for module in $(sed -nE 's/^[[:space:]]*(@testable[[:space:]]+)?import[[:space:]]+([A-Za-z0-9_]+).*/\1\2/p' "$file"); do
			case "$module" in
			@testable*) fail "testable import: $file" ;;
			*)
				if ! echo "$module" | grep -Eq "$pattern"; then
					fail "import $module not allowed in $dir: $file"
				fi
				;;
			esac
		done
	done
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

check_package Packages/HirakuTesting '^(Foundation|Testing|HirakuModels)$'
check_package Packages/HirakuModels '^(Foundation|SwiftProtobuf|HirakuModels)$'
check_package Packages/HirakuBridge '^(Foundation|CHirakuBridge|HirakuModels)$'

exit "$status"
