---
name: hiraku-ship
description: Coordinator merges a PR into the base only after an independent PASS and green required checks on the same head SHA; waits on pending checks, returns failures to the senior, and confirms the merged state. Use after hiraku-review returns PASS, or when a pending CI needs to be followed up.
compatibility: GitHub CLI and the repo's delivery script; run from the repo root. Gate names and script path come from the repo binding.
---

## Input

PR number and the head SHA that was reviewed with PASS.

## Steps

1. **Confirm the PASS is current.** The PR head must still equal the reviewed SHA.
   If it moved, stop and send the PR back through review.
2. **Read the checks.** Required checks on this SHA are one of: passing, pending,
   or failing.
3. **Act on the state.**
   - Pending: wait and re-read at a short interval. Do not merge while pending.
   - Failing: stop, and send the failing check name and log path to the senior.
     Do not re-run to hide a failure.
   - Passing and reviewed: go to step 4.
4. **Merge** through the repo's delivery script for this PR and SHA. Let the script
   enforce base, draft and protected-path rules. Do not call the raw merge command.
5. **Confirm.** Read the PR state. It must be merged, with the expected base.
   Update the task record's Delivery section with the merge SHA.

## Edge cases

- **Script refuses the merge:** report the reason verbatim. Do not work around
  it with raw git or gh commands.
- **PR touches policy, checker or CI:** the script refuses. Hand to the operator.
- **Branch behind the base:** the senior rebases and force-pushes the task branch
  with lease. Review again on the new SHA.
- **Tag, release or publish requested inside this skill:** refuse. These need an
  explicit request in their own session.

## Output

Merged PR number, merge SHA, base, and the record's updated Delivery section. Or:
the blocker and who must act next. Done when the merged state is confirmed from
the host, not assumed.
