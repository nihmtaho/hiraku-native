---
name: hiraku-review
description: Coordinator reviews a pull request against its task record at one exact head SHA, decides PASS or FAIL, and returns findings. Use when a senior reports a PR ready, or when a PR head changes and needs re-review.
compatibility: Git and GitHub CLI; run from the repo root. Verdict command and status context come from the repo binding.
---

## Input

PR number, head SHA (40 characters), and the task record. If the SHA is not given
or does not match the PR head, stop and ask for the current SHA.

## Steps

1. **Pin the revision.** Read the PR head SHA. Review only that SHA; any later
   push needs a new review.
2. **Read the contract first.** Acceptance criteria, Checks and the file list from
   the record. Scope is what the record allows, not what looks nice.
3. **Read the diff.** Check for: behavior outside the criteria, missing error and
   rollback paths, changed files outside scope, secrets, debug output, dead code,
   and comments that describe code instead of why.
4. **Check the evidence.** Each check in the record needs a real result. Re-run
   the cheap ones when in doubt. Do not accept a self-review as proof.
5. **Check the gate state.** Required checks are green on this SHA, the PR is not
   a draft, and the base is correct. A pending check is not a pass.
6. **Decide.**
   - Findings that block: FAIL, list each with file, line and the criterion it
     breaks. Keep each finding short and actionable.
   - Nothing blocks and evidence is complete: PASS, with the checks you ran.
7. **Record the verdict** through the repo's verdict command for this SHA, then
   note it in the record's Independent review section.

## Edge cases

- **Head moved during review:** discard the verdict and restart at step 1.
- **Scope creep in the diff:** FAIL, even when the change looks correct.
- **Policy or checker file in the diff:** do not merge; route to the operator
  and say why.
- **Second FAIL on the same task:** stop the loop. Analyze the cause or ask the
  PO; do not keep sending findings.
- **Reviewing your own work:** not allowed. If the session wrote the code, hand
  the review to a fresh session.

## Output

Verdict (PASS or FAIL), SHA, findings list or "none", the checks you ran with
exit codes, and the record path updated. Done when the verdict is recorded for
the exact SHA.
