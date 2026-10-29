#!/usr/bin/env sh
# Draft release notes grouped by Conventional Commit type (gitmoji sections).
#
# Usage:
#   draft-release-notes.sh [<base-ref>] [<version>]
#     base-ref : compare from here; defaults to the most recent tag.
#     version  : title + used in the "Full Changelog" link (e.g. v1.2.0).
#
# Prints Markdown to stdout. Only non-empty sections are shown.
set -eu

BASE="${1:-}"
VERSION="${2:-}"
if [ -z "$BASE" ]; then
  BASE=$(git describe --tags --abbrev=0 2>/dev/null || true)
fi
if [ -n "$BASE" ]; then RANGE="$BASE..HEAD"; else RANGE="HEAD"; fi

TAB=$(printf '\t')
printf '## %s\n\n' "${VERSION:-Unreleased}"

emit() { # <type-alternation> <heading>
  matched=$(git log --no-merges --reverse --pretty=format:"%s${TAB}%an" "$RANGE" \
    | grep -iE "^($1)(\([^)]*\))?!?:" || true)
  [ -z "$matched" ] && return 0
  printf '### %s\n\n' "$2"
  printf '%s\n' "$matched" | while IFS="$TAB" read -r subject author; do
    desc=$(printf '%s' "$subject" | sed -E 's/^[a-zA-Z]+(\([^)]*\))?!?:[[:space:]]*//')
    scope=$(printf '%s' "$subject" | sed -nE 's/^[a-zA-Z]+\(([^)]*)\).*/\1/p')
    if [ -n "$scope" ]; then
      printf -- '- (%s) %s by @%s\n' "$scope" "$desc" "$author"
    else
      printf -- '- %s by @%s\n' "$desc" "$author"
    fi
  done
  printf '\n'
}

emit 'feat'                '✨ Features'
emit 'fix'                 '🐛 Bug Fixes'
emit 'perf'                '⚡ Performance'
emit 'refactor'            '♻️ Refactoring'
emit 'docs'                '📝 Documentation'
emit 'test'                '✅ Tests'
emit 'build|ci'            '📦 Build & CI'
emit 'style|chore|revert'  '🔧 Chores'

if [ -n "$BASE" ]; then
  printf '**Full Changelog**: %s...%s\n' "$BASE" "${VERSION:-HEAD}"
fi
