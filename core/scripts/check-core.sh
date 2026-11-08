#!/bin/sh
# Fails when the Go core crosses a boundary that AGENTS.md forbids.
set -eu

cd "$(dirname "$0")/.."

status=0
fail() {
	echo "check-core: $1" >&2
	status=1
}

for file in $(grep -rl --include='*.go' -E '^[[:space:]]*(import[[:space:]]+)?"C"$|^[[:space:]]*[._[:alnum:]]+[[:space:]]+"C"$' . | grep -v '^\./ffi/' || true); do
	fail "import \"C\" outside ffi: $file"
done

for file in $(grep -rl --include='*.go' -E '^[[:space:]]*(import[[:space:]]+)?([._[:alnum:]]+[[:space:]]+)?"net(/[^"]*)?"$' . || true); do
	fail "net import: $file"
done

for file in $(grep -rl --include='*.go' -E 'time\.Now\(' domain service 2>/dev/null || true); do
	fail "time.Now in domain/service: $file"
done

exit "$status"
