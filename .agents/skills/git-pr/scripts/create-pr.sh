#!/usr/bin/env sh
# Push the current branch and open a pull request with the GitHub CLI.
# Blocks AI attribution trailers in the PR body.
#
# Usage: create-pr.sh <title> <body-file> [<base-branch>] [extra gh args...]
#   e.g. create-pr.sh "feat(ui): add dark mode" .git/PR_BODY.md main --draft
set -eu
DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

TITLE="${1:?usage: create-pr.sh <title> <body-file> [base] [gh args...]}"
BODY="${2:?missing body file}"
shift 2
BASE="${1:-}"
if [ -n "$BASE" ]; then shift; fi

"$DIR/guard-no-ai-trailer.sh" "$BODY"

command -v gh >/dev/null 2>&1 || {
  echo "ERROR: GitHub CLI (gh) not found. Install it or open the PR manually." >&2
  exit 1
}

git push -u origin HEAD

set -- --title "$TITLE" --body-file "$BODY" "$@"
[ -n "$BASE" ] && set -- --base "$BASE" "$@"
gh pr create "$@"
