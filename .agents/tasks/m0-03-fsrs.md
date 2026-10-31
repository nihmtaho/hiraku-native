# m0-03-fsrs — Spike S-2: evaluate a Go FSRS library against reference vectors

## Contract

- Status: blocked
- Owner: hiraku-coder
- Milestone / WP: M0 / S-2 (feeds GATE-1; blocks WP-03)
- Branch / PR: none; working tree only (the tree already carries the uncommitted `.agents/` migration and Spike 0 files — do not commit)
- Base / head SHA: `develop` = `62502e9e0996f6f8222c908c67714d725195e33e` at task start; `develop` moved to `b37073e` (PR #5, agent-config restructure) during execution — the task changes remain uncommitted
- Dependencies: none (`S-2` has no predecessor; `m0-02-mattn` is in review and touches no shared file)
- Required reading: `docs/product/spec.md` §7.1 and §3.3 S-2 (line ~139); `docs/architecture/DECISIONS.md` ADR-26, ADR-21; `AGENTS.md` G1–G8; `docs/reports/M0_SPIKE.md` (result format)
- Blocking Q / gate: GATE-1 requires S-2 to have a decision ("dùng hoặc tự cài"). No open Q blocks the evaluation. Do not pick the FSRS algorithm version on PO's behalf beyond "the newest version the reference implementation and the candidate both implement", and record it explicitly.
- Goal: decide, with evidence, whether an existing Go FSRS library can be used for `core/domain/fsrs` (ADR-26) or whether hiraku must implement FSRS itself.
- Out of scope: the production `core/domain/fsrs` package, RPC `Grade`, queue building, DB schema, Swift, fuzz, per-deck parameters, optimization/training of weights.
- Files / modules allowed to change: `core/go.mod`, `core/go.sum`, `core/spike/**` (evaluation test and vectors), `docs/reports/M0_SPIKE.md` (new `## S-2` section), `CHANGELOG.md` `[Unreleased]`, `ROADMAP.md` §11, `ROADMAP hiraku — Kanban.html`, `.agents/tmp/**` (scratch, gitignored).
- Permissions or PO decisions granted: PO chose mattn on 2026-10-30 for SQLite only; nothing else is pre-decided. `uv` (0.8+) and `python3` 3.14 are installed locally and may be used in `.agents/tmp/` to generate reference vectors. Network is allowed for `go get` and for installing `fsrs` into a throwaway venv.

## Acceptance criteria

1. **Candidate inventory**: for at least the maintained Go FSRS packages (`github.com/open-spaced-repetition/go-fsrs` and any other viable one found), record module path, latest version, license, last release/commit date, and whether it exposes a pure `Next(...)`-style function plus a preview of all ratings. A candidate is eligible only if license is compatible with a closed-source app store distribution (MIT/BSD/Apache) and the repo shows activity in the last 12 months.
2. **Reference vectors**: generate a vector table from the reference implementation (`fsrs` on PyPI, pinned version) in a throwaway venv under `.agents/tmp/`, using the spec's scheduler settings: `request_retention` from a stated value, `maximum_interval`, `enable_short_term = true`, `enable_fuzz = false`. Cover: new card graded each of 1–4, a Good→Good→Again→Good sequence, a lapse from Review, and a short-term step (Again on a New card producing a due of minutes). Record the exact py-fsrs version and the weights used.
3. **Match**: the candidate reproduces every reference `(state, due, stability, difficulty, reps, lapses)` value for the same inputs, with due times compared in whole seconds and a stated tolerance of 0 (declare any mismatch, however small, as a finding). If a mismatch exists, say whether it is a different algorithm version (then re-run against the version the candidate implements) or a defect.
4. **Short-term steps and purity**: the candidate supports short-term learning steps (`enable_short_term`), and its next-state function is pure: no clock read, no DB, no global state; inputs and outputs are plain values. State how `now` enters and what the caller must supply.
5. **Decision**: PASS → name the library, version, license, and the call shape for ADR-26's `Next(card, rating, now, settings)` / `Preview`. FAIL on any ADR-26 criterion → state which criterion failed and outline the self-implementation plan (data model, weights, which vectors the self-implementation must pass). Do not implement FSRS in this task.
6. **Evidence**: results in `docs/reports/M0_SPIKE.md` `## S-2` as Đạt/Không đạt rows with the exact command, exit code and file path. Every command that did not run is marked "không chạy" with the reason.
7. **Product surface untouched**: no `core/domain/**`, no `core/ffi` behaviour change for FSRS, no Swift.

## Checks

| Criterion | Command / manual check | Result / exit code | Revision / artifact |
|---|---|---|---|
| Python + uv available | `uv --version`, `python3 -V` | Not run | |
| Reference vectors generated | `.agents/tmp/fsrs-ref/` venv + script producing `core/spike/fsrs_vectors.json` | Not run | |
| Candidate builds | `go get <candidate>@<version>`, `go mod tidy`, `go test -race ./...` (cwd `core/`) | Not run | |
| Vector match | `go test -run TestFSRSVectors -v ./spike` (cwd `core/`) | Not run | |
| Purity / no clock | `grep -rn 'time.Now' $(go list -m -f '{{.Dir}}' <candidate>)` and source read | Not run | |
| License + maintenance | module `LICENSE`, `go list -m -versions`, upstream release page | Not run | |

## Coding

Round 1 (2026-10-30): candidate inventory, reference vectors from `fsrs 6.3.2` (FSRS-6), 17 vectors, 9 exact / 8 divergent; decision **Không đạt** under ADR-26's exact-match criterion. `ROADMAP.md:77,182`/Kanban `ADR 20–26` list fixed to `ADR-20, 21, 24, 26, 32`.

Round 2 (cleanup after the FAIL decision):

- Remove the rejected library from the module: delete `core/spike/fsrs_vectors_test.go`, `go mod tidy`, so `go test -race ./...` in `core/` is green again. A red default test suite is not an acceptable resting state.
- Keep the reference vectors as the future golden: `core/spike/fsrs_vectors.json` stays, and the generator script moves from gitignored `.agents/tmp/` to `core/spike/gen_fsrs_vectors.py` with a header pinning `fsrs==6.3.2`, the weights, and the settings. Document the regeneration command in `docs/reports/M0_SPIKE.md` §S-2.
- In `docs/reports/M0_SPIKE.md` §S-2, add one sentence: the comparison harness was a throwaway; the reproducible evidence is the generator + vectors + the divergence table.
- State in §S-2 that self-implementation in `core/domain/fsrs` is the outcome and that WP-03 owns it; do not create that package here.

## Independent review

- Reviewer / session: `ses_e7371ad2effe72a3u4ETtWL0KY`
- Revision: working tree (no commit), base `62502e9e0996f6f8222c908c67714d725195e33e`
- Verdict: **PASS** (draft — working tree only, not merge-eligible), then PASS on the round-3 nit fixes
- Findings: F1 missing pinned-version check in the generator; F2 wrong interpreter recorded; F3 regeneration command pointed at a non-existent root `.venv`; F4 candidate-side harness deleted so the divergence table is not one-command reproducible (Info, not applied); F5 `enable_short_term` is not a py-fsrs parameter; F6 no vector crosses 04:00; F7 the ts-fsrs alternative needs an ADR amendment, not a report note. F1–F3/F5–F7 applied in round 3 and confirmed.
- Checks the reviewer actually ran: `go test -race -count=1 ./...` 0, `go vet ./...` 0, `py_compile` 0, byte-identical regeneration with `fsrs==6.3.2` (Python 3.13.5), forced `fsrs==6.2.0`/`FSRS_VERSION=6.3.1` mismatch exits 1, scratch reproduction of the comparison gave the same 9 PASS / 8 FAIL, `wp-status --check` 0.
- Reviewer conclusion: FAIL is the correct reading of ADR-26 as written; `go-fsrs/v4` is not defective, it implements ts-fsrs/Anki scheduling policy (minute rounding on Hard, `hard < good < easy`, UTC calendar-day elapsed days).

## Decision

- **S-2 Không đạt** → self-implement FSRS in `core/domain/fsrs` (ADR-26 fallback). WP-03 owns it; the 17 vectors in `core/spike/fsrs_vectors.json` are the golden seed.
- Alternative requiring a PO-approved ADR-26/spec amendment (not taken): accept ts-fsrs semantics, define the float tolerance and the `day_start_hour` elapsed-day rule.

## Delivery

- CHANGELOG entry and ROADMAP/Kanban status updated in the PR: required in working tree
- Status: not requested
- CI / integration revision:
- Gate / PO approval:
- Actions actually taken / evidence from the target system:

## Next

Status: S-2 spike work is complete and reviewed PASS (working tree). Blocked on one PO-only edit in `docs/architecture/DECISIONS.md`: set ADR-26 to "Đã chốt — tự cài trong `core/domain/fsrs` (S-2 Không đạt)" and record the rejection reason (three semantic divergences from py-fsrs 6.3.2). Until then the S-2 row stays `rv` in ROADMAP §11 and the Kanban. WP-03 is the consumer of the golden vectors; it must add a vector crossing `day_start_hour` 04:00.
