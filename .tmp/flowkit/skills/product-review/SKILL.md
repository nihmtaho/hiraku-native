---
name: product-review
description: >-
  Review a spec, PRD, or design read-only: check the problem evidence, goals and
  non-goals, scope, success metrics, acceptance criteria, risks, and consistency with
  existing product docs; return findings by severity and a READY or CHANGES NEEDED
  verdict. Use when the PO or coordinator asks whether a document is ready before
  implementation starts.
compatibility: Read-only; documents per PROJECT.md §Docs map; run from the repository root.
---

You review a spec, PRD, or design and change nothing: during the review you never
edit files. Find the document under review through `PROJECT.md` §Docs map, and read
the architecture rules it leans on in `PROJECT.md` §Architecture rules.

## Checklist

- Real problem with evidence — not a solution in search of a problem.
- Goals and non-goals clear; scope not over-built: no speculative features or
  extension points nobody asked for.
- Success metrics measurable: numbers, not adjectives.
- Acceptance criteria complete: every goal has a checkable criterion.
- Risks and dependencies listed, each with an owner or mitigation.
- Design serves the stated user goals and stays consistent with the existing product
  documents it references (spec, use cases, design — per `PROJECT.md` §Docs map).
- Accessibility expectations noted; link the `accessibility` skill if installed.

## Workflow

1. Read the whole document and the product documents it references; confirm claims
   against those sources, never against the summary alone.
2. Turn each gap into a finding: location (section), severity, and why it matters.
3. Severity: **blocker** — ship-stopping (no problem evidence, unmeasurable success,
   incomplete acceptance criteria, unowned risk); **should-fix** — causes rework
   (vague scope, missing non-goals, contradicts existing docs); **suggestion** —
   improvement with no rework risk.
4. Verdict: `READY` when there are no blockers, otherwise `CHANGES NEEDED`, plus the
   findings list.

## Limits

- Never edit files during review — no fixes, no rewording, no commits. Findings are
  the deliverable; the author applies them.
- Do not invent requirements the product documents do not state, and do not propose
  refactors by preference.
- No verdict without reading the full document and the product docs it references.

## Output

Verdict `READY` or `CHANGES NEEDED`, findings (location, severity, why), documents
read, and parts not reviewed.
