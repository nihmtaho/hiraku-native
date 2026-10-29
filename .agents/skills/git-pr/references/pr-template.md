# Pull Request Template

## Title
Follow Conventional Commits, same as a commit subject:
```
<type>(<scope>): <summary>
```
e.g. `feat(auth): support passkey login`. Keep it ≤ 72 chars, imperative.

## Body
Fill only the sections that apply. Keep it tight.

```markdown
## Summary
<1–3 sentences: what this PR does and why.>

## Changes
- <key change 1>
- <key change 2>

## Testing
- <how you verified: commands run, cases covered, screenshots if UI>

## Risk & rollout
- <migrations, flags, breaking changes, or "none">

## Linked issues
Closes #<id>
```

## Rules
- "Summary" answers *why*; "Changes" answers *what*. Don't just paste the diff.
- Use `Closes #id` / `Fixes #id` so the issue auto-closes on merge.
- Call out breaking changes and required follow-up explicitly.
- Never include AI attribution lines (the guard script enforces this).
- For a work-in-progress PR, pass `--draft` to `scripts/create-pr.sh`.
