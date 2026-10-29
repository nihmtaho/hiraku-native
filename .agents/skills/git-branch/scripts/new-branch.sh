#!/usr/bin/env sh
# Create a conventionally-named branch off a fresh base, then switch to it.
#
# Usage: new-branch.sh [-b <base-branch>] <type> <summary words...>
#   type    : feat|fix|hotfix|refactor|docs|test|chore|release
#   summary : one or more words; joined and sanitized to kebab-case.
#             Lead with an issue id to get <type>/<id>-<summary>.
#
# Examples:
#   new-branch.sh feat passkey login            -> feat/passkey-login
#   new-branch.sh fix 142 null token crash      -> fix/142-null-token-crash
#   new-branch.sh -b develop feat dark mode     -> feat/dark-mode  (off develop)
set -eu

BASE=""
if [ "${1:-}" = "-b" ]; then
  BASE="${2:?-b needs a base branch}"; shift 2
fi

TYPE="${1:?usage: new-branch.sh [-b base] <type> <summary words...>}"; shift
[ "$#" -ge 1 ] || { echo "ERROR: provide a summary." >&2; exit 1; }

case "$TYPE" in
  feat|fix|hotfix|refactor|docs|test|chore|release) ;;
  *) echo "ERROR: invalid type '$TYPE'. Use feat|fix|hotfix|refactor|docs|test|chore|release." >&2; exit 1 ;;
esac

# Join remaining args, lowercase, non-alnum -> '-', squeeze and trim '-'.
RAW=$(printf '%s' "$*" | tr '[:upper:]' '[:lower:]' \
  | sed -E 's/[^a-z0-9]+/-/g; s/-+/-/g; s/^-//; s/-$//')
[ -n "$RAW" ] || { echo "ERROR: summary is empty after sanitizing." >&2; exit 1; }

BRANCH="$TYPE/$RAW"

# Detect base if not given: origin/HEAD, then main/master/develop.
if [ -z "$BASE" ]; then
  BASE=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##' || true)
  if [ -z "$BASE" ]; then
    for c in main master develop; do
      if git show-ref --verify --quiet "refs/heads/$c"; then BASE="$c"; break; fi
    done
  fi
fi
[ -n "$BASE" ] || { echo "ERROR: could not detect base branch; pass -b <base>." >&2; exit 1; }

echo "Creating $BRANCH off $BASE ..."
git fetch origin "$BASE" 2>/dev/null || true
if git show-ref --verify --quiet "refs/remotes/origin/$BASE"; then
  git switch -c "$BRANCH" "origin/$BASE"
else
  git switch -c "$BRANCH" "$BASE"
fi
echo "On branch $BRANCH"
