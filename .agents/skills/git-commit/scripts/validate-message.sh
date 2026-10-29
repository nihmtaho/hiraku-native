#!/usr/bin/env sh
# Validate a commit message against the team convention BEFORE committing.
# Checks: no AI trailer, Conventional Commit subject, subject <= 72 chars,
#         lowercase start after the colon, no trailing period,
#         header only (no body), no task IDs in the header.
#
# Usage: validate-message.sh <message-file>
# Reused by commit.sh; mirrors the rules enforced by git-hooks/hooks/commit-msg.
set -eu
DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
FILE="${1:?usage: validate-message.sh <message-file>}"
[ -f "$FILE" ] || { echo "validate: no such file: $FILE" >&2; exit 2; }

# 1) AI attribution (reuse the shared guard).
"$DIR/guard-no-ai-trailer.sh" "$FILE"

# First non-comment, non-empty line = subject.
SUBJECT=$(grep -vE '^[[:space:]]*#' "$FILE" | grep -vE '^[[:space:]]*$' | head -n 1 || true)
[ -n "$SUBJECT" ] || { echo "validate: empty commit message." >&2; exit 1; }

# Let special commits through.
case "$SUBJECT" in
  "Merge "*|"Revert "*|"fixup! "*|"squash! "*|"amend! "*) exit 0 ;;
esac

TYPES='feat|fix|perf|refactor|docs|style|test|build|ci|chore|revert'
if ! printf '%s' "$SUBJECT" | grep -qE "^($TYPES)(\([a-z0-9._/-]+\))?!?: .+"; then
  echo "validate: subject must be '<type>(<scope>)?: summary'." >&2
  echo "  got:   $SUBJECT" >&2
  echo "  types: $TYPES" >&2
  exit 1
fi

# Header only: no body or footer.
LINES=$(grep -vE '^[[:space:]]*#' "$FILE" | grep -cvE '^[[:space:]]*$' || true)
if [ "$LINES" -gt 1 ]; then
  echo "validate: message must be the header line only (no body or footer)." >&2
  exit 1
fi

if printf '%s' "$SUBJECT" | grep -qE '[A-Z]{2,}-[0-9]+|#[0-9]+'; then
  echo "validate: no task IDs in the header: '$SUBJECT'" >&2
  exit 1
fi

DESC=$(printf '%s' "$SUBJECT" | sed -E 's/^[a-z]+(\([^)]*\))?!?:[[:space:]]*//')
case "$DESC" in [A-Z]*) echo "validate: start the summary lowercase: '$DESC'" >&2; exit 1 ;; esac
case "$DESC" in *.)    echo "validate: drop the trailing period in the subject." >&2; exit 1 ;; esac

LEN=$(printf '%s' "$SUBJECT" | wc -c | tr -d ' ')
if [ "$LEN" -gt 72 ]; then
  echo "validate: subject is ${LEN} chars (max 72). Shorten it." >&2
  exit 1
fi

exit 0
