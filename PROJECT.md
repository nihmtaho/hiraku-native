# PROJECT.md — hiraku

## Project

hiraku — a Japanese vocabulary app built on FSRS. Business logic and data live in a Go
core; everything the user touches is native SwiftUI on iOS, iPadOS, and macOS 26+ (Apple
silicon). Offline by default, no accounts; iCloud sync is optional and off by default.
UI strings and documentation are Vietnamese; identifiers, code comments, commits, and PRs
are English.

```
App/            Xcode project: App/Hiraku (targets), App/HirakuTests
Packages/       Swift packages: HirakuModels, HirakuBridge, HirakuTesting, DesignSystem,
                StudyKit, Features/Feature*
core/           Go: domain/, service/, store/, ffi/, gen/, proto/hiraku/v1, scripts/
Scripts/        Repository-level shell scripts (check-imports.sh)
docs/           plans/, reports/, architecture/, product/, process/
.agents/        scripts/, skills/, templates/, tasks/, tmp/
```

The kit's neutral template this profile was adapted from lives at
`.tmp/flowkit/PROJECT.md.example`.

## Status tracking

Work-item state lives in three places that must always agree, plus one task record per
task. States (same five values in the Kanban): `bl` Backlog · `rd` Ready · `ip` In
progress · `rv` In review · `dn` Done. A blocked item keeps its state, gets `blk` in the
Kanban, and names the blocking `Q-xx` in the note.

- Work items: the table in `ROADMAP.md` §11.
- Board: the `raw` array in `ROADMAP hiraku — Kanban.html` (fifth field of each card).
- Changelog: `## [Unreleased]` in `CHANGELOG.md`, one Vietnamese line under `Thêm`,
  `Đổi`, `Sửa`, `Xóa`, `Tài liệu`, or `Bảo mật`, ending with `(WP-xx, PR n)`.
- Task record: `.agents/tasks/<task-id>.md`, created from `.agents/templates/task.md`.

Write state and check consistency with `wp-status.mjs`; read one item's context with
`task-context.mjs`; never edit either status place by hand when the script can do it:

```sh
node .agents/scripts/wp-status.mjs <id> <bl|rd|ip|rv|dn> [--pr <ref>] [--note "<text>"]
node .agents/scripts/wp-status.mjs <id> <state> [--blk Q-xx | --clear-blk]
node .agents/scripts/wp-status.mjs --check
node .agents/scripts/task-context.mjs <WP-xx|S-x|Q-xx>
node --test .agents/hiraku/tests/*.test.mjs
```

`--check` is the consistency check and must pass before a task closes; run
`node --test` after editing anything under `.agents/scripts/` or the process docs.

## Git & PR

Base branch: `develop`. Every task is one branch and one PR into `develop`; `main` only
receives `release/vX.Y.Z` and `hotfix/*`.

- Branch: `<type>/<task-id>-<short-summary>`, cut from `develop`. Types: `feat`, `fix`,
  `refactor`, `docs`, `test`, `chore`, `release`, `hotfix`. Example:
  `feat/wp-03-fsrs-grade`.
- Create the branch with the explicit base, because auto-detection picks `main`:
  `.agents/skills/git-branch/scripts/new-branch.sh -b develop feat wp-03 fsrs grade`
- Commit: Conventional Commits, one line, `<type>(<scope>): <subject>`, English,
  imperative, no body, no footer, no task ID, no AI co-author or robot icon. Task ID and
  FR/UC/ADR references belong in the PR body and the task record.
- Rebase the task branch onto `develop` (never merge `develop` into it). Force-push only
  with `git push --force-with-lease` on a task branch; never on `develop` or `main`.
- PR: title `<type>(<scope>): <subject>` in English; body from
  `.github/pull_request_template.md`; list only checks actually run with command, exit
  code, and revision; a check not run is written `Not run`.
- Merge: `gh pr merge <pr> --squash --match-head-commit <sha>`, only after an independent
  review returned PASS on exactly that SHA and required CI is green. A new push voids the
  verdict. `main` uses a merge commit.
- Human operator reviews these before merge (no automated gate): `AGENTS.md`,
  `docs/process/`, `docs/architecture/DECISIONS.md`, `.github/`, `.agents/` except
  `.agents/tasks/`, agent tool config and `opencode.json`, any `check-*` script,
  `core/scripts/build-xcframework.sh`, `core/gen/` and Swift `Generated/` directories.
- Tagging and releasing belong to the PO and operator, not to agents (ADR-33).
  `docs/process/RELEASE.md` describes the release flow.

## Checks

Run from the repository root unless noted. A check that was not run is reported as
`Not run`; never mark it passed.

```sh
./core/scripts/check-core.sh                      # Go boundary law: import "C", net, time.Now in domain/service
cd core && go vet ./... && go test -race ./...
buf lint                                          # contract style, core/proto/hiraku/v1
buf breaking --against '.git#branch=develop'      # required when the contract changes
buf generate                                      # regenerate core/gen from core/proto/hiraku/v1
./Scripts/check-imports.sh                        # Swift import allowlists, ARCHITECTURE §4.1
node .agents/scripts/wp-status.mjs --check        # ROADMAP §11 and the Kanban agree
xcodebuild test -project App/Hiraku.xcodeproj -scheme Hiraku -destination 'platform=macOS'
xcodebuild test -project App/Hiraku.xcodeproj -scheme Hiraku -destination 'platform=iOS Simulator,name=iPhone 18 Pro'
```

CI (`.github/workflows/ci.yml`) has two jobs. `ci` runs `go vet`, `go test -race`,
`check-core.sh`, `check-imports.sh`, `buf lint`, the skill tests, and the status check.
`swift` builds the cgo archives and Swift packages, then runs `xcodebuild test` on macOS.

## Docs map

| What | Where |
|---|---|
| Implementation plans | `docs/plans/` |
| Spike results, milestone reports | `docs/reports/` |
| Spike report template | `.agents/skills/flow-spike/references/report-template.md` |
| Task records | `.agents/tasks/<task-id>.md` from `.agents/templates/task.md` |
| Scratch files, agent logs, PR drafts | `.agents/tmp/` |
| Product spec, use cases, design | `docs/product/spec.md`, `docs/product/use-cases.md`, `docs/product/DESIGN.md` |
| Architecture law and decisions | `docs/architecture/ARCHITECTURE.md`, `docs/architecture/DECISIONS.md` |
| Process (agents, git, release) | `docs/process/AGENT_WORKFLOW.md`, `docs/process/GIT_WORKFLOW.md`, `docs/process/RELEASE.md` |
| UI strings | `COPY.md` and the String Catalog |
| Milestones and the changelog | `ROADMAP.md`, `ROADMAP hiraku — Kanban.html`, `CHANGELOG.md` |
| Kit profile example | `.tmp/flowkit/PROJECT.md.example` |
| Document index | `docs/README.md` |

Spike evidence is recorded in `docs/reports/M0_SPIKE.md` in a fixed shape. Root keeps
only `AGENTS.md`, `PROJECT.md`, `CHANGELOG.md`, `COPY.md`, `ROADMAP.md`, and the Kanban;
every other document goes under `docs/`.

## Architecture rules

Law: `docs/architecture/ARCHITECTURE.md` v2.2 — Swift laws L1–L11, Go laws G1–G8,
style rules C1–C8, module map §3–§4, extensions checklist §13. Decisions and open
questions: `docs/architecture/DECISIONS.md` (every ADR, plus `Q-xx` entries).
An open decision with `Trạng thái: *Mở*` is answered by the PO, never by an agent.

Hard boundaries:

- If the logic does not need to know it is running on Apple hardware, it belongs in the
  Go core (`core/`).
- Only `core/ffi` imports `"C"`; only `HirakuBridge` calls `hk_*`. Swift never touches
  `core/gen/`.
- No `net*` imports and no global mutable state in Go. No `time.Now()` in `domain` or
  `service`; time enters through `now_ms`. `unsafe` only inside `ffi`.
- Swift time comes from `AppClock` as `now_ms`; no `Date()` or `Task.sleep` in
  Controllers.
- A feature package imports only Foundation, SwiftUI, `HirakuModels`, and `DesignSystem`;
  `FeatureStudy`, `FeatureFlashcard`, and `FeatureTyping` may also import `StudyKit`.
  Never `HirakuBridge`, never another feature. UI talks to the core through Controller →
  Repository protocols.
- Swift has no transactions and never writes `card_states` or `review_logs`; every
  multi-table write is one core RPC.
- `core/proto/hiraku/v1` is the single contract source. Never hand-edit `core/gen/` or
  Swift generated code, never reuse a field number. A contract change needs
  `buf breaking` green, new goldens, and an ADR when behavior changes.
- The core does not know what a profile is and never picks a database path; Swift owns
  the profile list and the path passed to `hk_open`. Never split the database per deck.
- Custom fields (ADR-27): never hard-code the four built-in fields outside the system
  note-type definition. Learning, typing, duplicate checks, search, and script selection
  follow the field **role**, not its name; values key on `field_id`. FSRS and logs key on
  `card_id`, never `word_id`. Field and profile names the user typed are data, not UI
  strings.

## Quality rules

- Style rules C1–C8 in `docs/architecture/ARCHITECTURE.md` §4.4 apply to all code,
  including AI-written code: simplest thing that works, no speculative abstraction, no
  clever tricks, short functions, early return, nesting at most three levels, standard
  library first, touch only what the task asks, no dead code, no leftover `print` or
  `fmt.Println`, no unused imports, behavior-level tests with one idea each.
- Comments: one line, English, only the *why*. No restating the code, no FR/UC/ADR/WP
  references, no history, no long blocks. `// TODO(Q-xx): …` is the only exception.
  Doc comments only for public APIs, at most two lines.
- UI: tokens `HK*`, icons through `AppIcon` (SF Symbols), strings in the Vietnamese
  String Catalog. No hard-coded color, string, or font size. Documents, UI strings, and
  changelog lines are Vietnamese; identifiers, comments, commits, PRs, and tests are
  English.
- Swift 6 strict concurrency, no `try!`, no force unwrap in business logic. New
  dependencies need an ADR; already settled: `github.com/mattn/go-sqlite3` (ADR-32),
  `swift-protobuf`, `google.golang.org/protobuf`, buf (ADR-22).
- Every task's PR adds a `CHANGELOG.md` `[Unreleased]` line and updates `ROADMAP.md` §11
  and the Kanban in the same branch. A behavior change also updates spec, use cases, and
  design.

## PM hooks

- Large, vague, or cross-cutting request → run `write-spec` first; the product spec lives
  in `docs/product/spec.md`, and the implementation plan goes to `docs/plans/`.
- Milestone closed or gate passed → run `stakeholder-update`; report against `ROADMAP.md`
  §3 (milestones) and §7 (definition of done). Milestone acceptance and gate decisions
  (`ROADMAP.md` §4) stay with the PO; merge does not mean acceptance.
- Roadmap, scope, or schedule change → run `roadmap-update`; edit `ROADMAP.md` under
  §8 change control and keep `ROADMAP hiraku — Kanban.html` in step.
- Milestone kickoff → run `sprint-planning` to split the milestone into work items before
  any task record is written.
- Tagging, release, and TestFlight/App Store steps are PO and operator actions
  (`docs/process/RELEASE.md`); never a PM skill's job.
