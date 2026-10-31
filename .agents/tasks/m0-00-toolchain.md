# m0-00-toolchain — Enable the M0 spike toolchain

## Contract

- Status: blocked
- Owner: PO / operator (policy change; Lead cannot edit)
- Milestone / WP: M0 (prerequisite)
- Branch / PR: none
- Base / head SHA: `develop` = `62502e9e0996f6f8222c908c67714d725195e33e`; working-tree only, not eligible for merge
- Dependencies: PO decision 2026-10-30: open the minimal M0 allowlist; measure on MacBook, mark iOS/iPadOS unverified
- Required reading: `OPENCODE.md` §3, `docs/architecture/DECISIONS.md` ADR-31, `ROADMAP.md` §3.1, §4 GATE-1, `docs/product/spec.md` §3.3
- Blocking Q / gate: Q-11 partial (MacBook only, no iPhone/iPad)
- Goal: make the commands below available to `hiraku-coder` so Spike 0, S-2, S-1 (MacBook), S-8 build and the spike report can run without bypassing the guard.
- Out of scope: delivery rights (commit/push/merge), release, signing, network beyond `go get` module fetch and font download, device provisioning.
- Files / modules allowed to change: `opencode.json`, `.opencode/lib/guard.mjs`, `.opencode/tests/guard.test.mjs` only.
- Permissions or PO decisions granted: PO answered "Mở allowlist M0 tối thiểu" on 2026-10-30. Policy changes still applied by PO/operator, never by an agent.

## Requested grant (exact)

1. `opencode.json`, agent `hiraku-coder`, add shell resources:
   - `go version`
   - `go mod *`
   - `go get *`
   - `go list *`
   - `bash core/scripts/spike-build.sh`
2. `.opencode/lib/guard.mjs`, in `assertShell`, add only for `agent === "hiraku-coder"` and `directory === "core"`:
   - `go version`
   - `go mod init <module>` and `go mod tidy`
   - `go get <module>[@version]` (one argument, no shell metacharacters)
   - `go list -deps ./...`
   - `go test -run <pattern> ./...` and `go test -bench . -benchtime <n>x ./...`
   Then at root, coder-only: `bash core/scripts/spike-build.sh`.
3. `spike-build.sh` is created by the coder task `m0-01-spike0`; PO reviews its contents before granting. It may contain only `go build -buildmode=c-archive` for ios/arm64, iossimulator/arm64, darwin/arm64 with explicit GOOS/GOARCH/CGO_ENABLED and output paths under `core/.spike/`.
4. `.opencode/tests/guard.test.mjs`: add assertions that the new commands work only for coder in `core/`, that reviewer is denied, and that the spike script is coder-only. Existing deny cases must stay.
5. Run `node --test .opencode/tests/*.test.mjs` and `opencode debug config --standalone`; both results recorded here.

## Acceptance criteria

- Coder can run the listed Go commands in `core/` and `spike-build.sh`; every agent other than coder is denied; `git push`, compound commands and interpreter calls stay denied.
- Guard tests pass with the new cases.
- No other permission is widened; delivery stays closed.

## Checks

| Criterion | Command / manual check | Result / exit code | Revision / artifact |
|---|---|---|---|
| Guard tests | `node --test .opencode/tests/*.test.mjs` | PASS 63/63 on 2026-10-30 after operator applied the patch and removed `.opencode/**/.DS_Store` | — |
| Agent discovery | `opencode debug config --standalone` | Not run | — |
| Coder can init/tidy | manual: coder runs `go mod init`/`go mod tidy` in `core/` | Not run | — |
| Bypass still denied | manual: coder runs `git push`, `go mod tidy && git push`, `sh -c 'go mod tidy'` | Not run | — |

## Coding

Not started. This is a policy/environment task.

Lead attempted the edit on 2026-10-30 as delegated by PO; the guard returned `permission.rejected: edit` (protected policy path). The patch must be applied by the operator. `git status --short` is still rejected after the patch, so the operator must run the tests after applying the fix and restarting OpenCode to reload the plugin.

Second defect found: `evaluatePermission` guesses `cwd = root` for every shell resource except `go test`/`go vet` and calls `assertShell` with it. `go mod init`, `go get`, `go list -deps` and `bash core/scripts/spike-build.sh` are therefore denied before the real-cwd shell hook runs. Fix: the permission hook must only require resources; the `create.before` shell hook re-checks every command with the real cwd.

## Independent review

- Reviewer / session: required for the policy diff (PO is the operator; AI review optional)
- Revision:
- Verdict:
- Findings:
- Checks the reviewer actually ran:

## Delivery

- CHANGELOG entry and ROADMAP/Kanban status updated in the PR: no PR; record only
- Status: blocked
- CI / integration revision:
- Gate / PO approval: PO approved the direction on 2026-10-30; the patch still has to be applied
- Actions actually taken / evidence from the target system: none

## Next

PO/operator applies the patch and records the test output here. Then Lead releases `m0-01-spike0`.
