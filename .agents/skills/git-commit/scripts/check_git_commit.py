#!/usr/bin/env python3
"""Validate a commit message against the team convention.

Checks: no AI attribution trailer, Conventional Commit subject,
subject <= 72 chars, lowercase after the colon, no trailing period,
header only (no body), no task IDs in the header.

Usage:
  check_git_commit.py -m "feat(ui): add dark mode"
  check_git_commit.py -f path/to/COMMIT_MSG

Exit code 0 = PASS, 1 = FAIL. Mirrors the rules in
scripts/validate-message.sh and git-hooks/hooks/commit-msg.
"""
import argparse
import re
import sys

TYPES = ["feat", "fix", "perf", "refactor", "docs", "style",
         "test", "build", "ci", "chore", "revert"]

AI = re.compile(
    r"co-authored-by:.*(claude|anthropic|openai|chatgpt|gpt|copilot|cursor|gemini|codex|noreply@anthropic)"
    r"|generated with (claude|copilot|cursor|codex|ai)|\U0001F916 generated",
    re.IGNORECASE,
)
SUBJECT_RE = re.compile(r"^(%s)(\([a-z0-9._/-]+\))?!?: .+" % "|".join(TYPES))
SPECIAL = ("Merge ", "Revert ", "fixup! ", "squash! ", "amend! ")
TASK_ID = re.compile(r"[A-Z]{2,}-[0-9]+|#[0-9]+")


def check(message):
    errors = []
    lines = message.splitlines()

    for i, line in enumerate(lines, 1):
        if AI.search(line):
            errors.append("AI attribution trailer on line %d: %s" % (i, line.strip()))

    subject = ""
    for line in lines:
        s = line.strip()
        if s and not s.startswith("#"):
            subject = s
            break

    if not subject:
        errors.append("empty commit message")
        return errors

    if subject.startswith(SPECIAL):
        return errors  # merge/revert/fixup allowed through

    body = [l for l in lines if l.strip() and not l.strip().startswith("#")]
    if len(body) > 1:
        errors.append("message must be the header line only (no body or footer)")
    if TASK_ID.search(subject):
        errors.append("no task IDs in the header: %s" % subject)

    if not SUBJECT_RE.match(subject):
        errors.append("subject must be '<type>(<scope>)?: summary' (types: %s); got: %s"
                      % ("|".join(TYPES), subject))
    else:
        desc = re.sub(r"^[a-z]+(\([^)]*\))?!?:\s*", "", subject)
        if desc[:1].isupper():
            errors.append("start the summary lowercase: %s" % desc)
        if desc.endswith("."):
            errors.append("drop the trailing period in the subject")

    if len(subject) > 72:
        errors.append("subject is %d chars (max 72)" % len(subject))

    return errors


def main():
    ap = argparse.ArgumentParser(description="Validate a commit message.")
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument("-m", "--message", help="commit message text")
    g.add_argument("-f", "--file", help="path to a commit message file")
    args = ap.parse_args()

    if args.message is not None:
        message = args.message
    else:
        with open(args.file, encoding="utf-8") as fh:
            message = fh.read()

    errors = check(message)
    if errors:
        print("FAIL")
        for e in errors:
            print("  - %s" % e)
        sys.exit(1)
    print("PASS")


if __name__ == "__main__":
    main()
