# Flowkit — portable agent skills kit

Flowkit is a copy-in skills kit that works in any repository. It holds 20 skills:
10 ported process skills (one task from work item to reviewed and merged PR), 8
product-management skills, and two new skills, `flow-debug` and `product-review`.

Everything repository-specific lives in `PROJECT.md` at the consumer repo root: project
facts, status commands, git and PR rules, checks, docs map, architecture rules, quality
rules, and PM hooks. Every `flow-*` skill reads it first and stops if it is missing.
Universal quality rules stay in the skills; the profile only adds project specifics.

Scope note: `flow-feature` and `flow-interface` assume an app with an MVC/contract
architecture (a controller/view layer over a logic core); their vocabulary is adapted per
project through `PROJECT.md`.

## Prerequisites

- The delivery skills (`flow-*`) need a GitHub remote, Git, and the `gh` CLI signed in.
- Commits follow the `git-commit` skill, or an equivalent Conventional Commit rule in
  `PROJECT.md` §Git & PR.
- Plan execution uses the `executing-plans` skill, or inline execution of the plan file.
- `AGENTS.md` is optional; the skills read it only if the project has one.

## Install

1. Copy `skills/` into the skills directory your harness reads (for example
   `.agents/skills/`). Keep the directory names; skill ids and cross-references use them.
   Carry `LICENSE.pm-skills` along with it: Apache-2.0 §4(a) requires the license text to
   travel with the product-management skills.
2. Copy `PROJECT.md.example` to `PROJECT.md` at the repo root and fill every section.
3. Optional: start `AGENTS.md` from `AGENTS.template.md` and replace every bracketed
   placeholder with facts about the repository before committing it.

Before copying, run the check below in the kit; it reads the kit, not the installed copy.

`profiles/hiraku-native.md` is a worked example: a fully filled `PROJECT.md` for a real
project, useful as a shape to copy. It is evidence, not an install step.

## Skill map from the original kit

The 10 process skills were ported 1:1 from the `hiraku-*` set: same steps, same
guardrails, same verdict model, with repository-specific facts replaced and review
hardening added.

| Original skill | Flowkit skill | What it does |
|---|---|---|
| `hiraku-coordinator` | `flow-coordinator` | Coordinate a task from work item to merged PR |
| `hiraku-task` | `flow-task` | Create or update the task record |
| `hiraku-coding` | `flow-implement` | Senior implements the task and pushes the branch |
| `hiraku-create-pr` | `flow-pr` | Open or fix the task PR |
| `hiraku-review` | `flow-review` | Independent review against the exact head SHA |
| `hiraku-ship` | `flow-ship` | Merge after a PASS on that SHA |
| `hiraku-wp-status` | `flow-status` | Keep board, task record, and changelog in step |
| `hiraku-contract` | `flow-interface` | Change a contract across every layer it reaches |
| `hiraku-feature` | `flow-feature` | Add a feature as a vertical slice |
| `hiraku-spike-report` | `flow-spike` | Run a time-boxed spike and record the evidence |

The other 10 skills are the 8 product-management skills plus two new ones, `flow-debug`
and `product-review`. The product-management ids keep their names from the source plugin.

## Licenses

The 12 skills outside product management are this repository's own work, except the
SwiftUI tips in `flow-feature`, which are adapted from `swiftui-patterns` by
affaan-m/ecc (MIT, commit `b38be6a`) and keep that notice. The 8 product-management
skills are ported from the Product Management plugin, version 1.2.0, and carry
Apache-2.0; the full text is in `LICENSE.pm-skills`.

## Note on `.tmp/` placement

This copy lives in `.tmp/flowkit/` on a review branch on purpose: the owner evaluates the
kit before anything replaces the skills currently in use. That is a deliberate exception
to the repository's file-placement rule and does not change after install — copy the kit
wherever your harness expects skills.

## Check

```sh
node .tmp/flowkit/scripts/check-kit.mjs
```

Exit 0 prints `flowkit check: OK`. Any other result prints one violation per line and
exits 1: a missing skill or frontmatter field, a name that does not match its directory,
a banned project token inside `skills/`, a duplicate skill name, a missing
`PROJECT.md.example` section or anchor word, or a `flow-*` skill that does not point at
`PROJECT.md`. Run it after every edit to the kit.
