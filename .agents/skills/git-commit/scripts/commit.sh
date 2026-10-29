#!/usr/bin/env sh
# Commit staged changes from a prepared message file.
# Validates the message (format + no AI trailer), refuses empty commits,
# and refuses to commit directly on main/master.
#
# Usage: commit.sh <message-file> [extra git-commit args...]
# Override the branch guard once with: ALLOW_MAIN=1 commit.sh ...
set -eu
DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
FILE="${1:?usage: commit.sh <message-file> [git commit args...]}"
shift || true

BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
case "$BRANCH" in
  main|master)
    if [ "${ALLOW_MAIN:-0}" != "1" ]; then
      echo "ERROR: refusing to commit directly on '$BRANCH'." >&2
      echo "Create a branch first (see the git-branch skill), or set ALLOW_MAIN=1 to override." >&2
      exit 1
    fi ;;
esac

"$DIR/validate-message.sh" "$FILE"

if git diff --cached --quiet; then
  echo "ERROR: nothing staged. Stage changes with 'git add' first." >&2
  exit 1
fi

# --cleanup=strip removes comment lines and trailing whitespace.
git commit --file "$FILE" --cleanup=strip "$@"
