---
name: flow-review
description: >-
  Independently review a PR or diff against the exact head SHA: check it against the
  task record and the architecture rules, run the checks, then return a PASS, FAIL, or
  BLOCKED verdict to the coordinator. Use when the coordinator assigns a PR review, or
  a SHA must be checked before merge. Runs in a fresh session, never the session that
  wrote the code.
compatibility: gh signed in; run from the repository root.
---

Read `PROJECT.md` at the repo root first. If it is missing, stop and ask the user to
create it from the kit's `PROJECT.md.example`.

You review independently and change nothing. The senior's report is only a lead, not a
substitute for reading the diff and its call flow.

## Workflow

1. Confirm this session did not write the PR's code. If it did, stop and tell the
   coordinator: a verdict from this session must not be recorded.
2. Get the exact SHA: `gh pr view <pr> --json headRefOid,baseRefName,state`. Head
   differs from the assigned SHA → stop and report that the head changed.
3. Read the task record, scope, and acceptance criteria, and the diff for that SHA
   (`gh pr diff <pr>`). Read the callers and callees that matter.
4. Check against:
   - files outside the task scope, or an unresolved open decision left unhandled;
   - business-logic errors, data loss, atomicity, concurrency and lifetime, error and
     cancellation handling, missing wiring;
   - the architecture rules named in `PROJECT.md` §Architecture rules, in the sections
     the change touches;
   - the project-specific invariants named there (state ownership, module boundaries,
     generated files, contract compatibility).
5. Contract or feature change: load `flow-interface` or `flow-feature` to run their
   checklist. Do not perform their write or code-generation steps.
6. Required checks: the diff adds a `[Unreleased]` line to the changelog named in
   `PROJECT.md` §Docs map, and the status places named in `PROJECT.md` §Status tracking
   agree (run the status check command listed there). Missing or divergent is a blocking
   finding.
7. Run the relevant checks: the commands in `PROJECT.md` §Checks. Record each command
   and exit code. A check that was not run is written `Not run`.
8. Choose the verdict:
   - `PASS`: enough evidence, no blocking findings, and the exact assigned SHA was read.
   - `FAIL`: a finding with file and line, severity, reproduction path, and the check
     that is missing.
   - `BLOCKED`: a missing decision, environment, diff, or required check. Do not record
     a verdict.
9. Return to the coordinator: verdict, SHA, findings, commands run with exit codes, and
   unverified parts. Do not post status on GitHub; the coordinator decides from this
   verdict.

## Review hardening

- Read connected code (callers, callees), not just the diff.
- Check: data loss, security/secrets, error handling, races/lifetime, missing wiring,
  and the architecture rules from `PROJECT.md` §Architecture rules.
- Never PASS when a required check has not run — `Not run` is a finding.
- Findings format: file + line, severity, reproduction path, missing check.

## Limits

- Do not edit source, golden files, policy, the task record, or the PR. No commits, no
  pushes.
- Temporary files go in the scratch directory named in `PROJECT.md` §Docs map.
- Do not propose refactors by preference. Grep or unit tests do not replace manual
  review for rules that need reading.
- Never write `PASS` for a SHA whose diff was not read, or when a required check has
  not run.
- No merge, no `gh pr review`, no `gh api`.
- Never read signing or credential secrets (`.env*` except `.env.example`, `*.p8`,
  `*.p12`, `*.pem`, `*.key`).

## Output

A block with: `verdict`, `pr`, `sha`, findings (file:line, severity, reproduction
path), commands run with exit codes, and unverified parts.
