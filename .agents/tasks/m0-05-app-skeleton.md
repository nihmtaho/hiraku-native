# m0-05-app-skeleton — Minimal SwiftUI app shell for the remaining M0 spikes

## Contract

- Status: blocked
- Owner: hiraku-coder
- Milestone / WP: M0 (infrastructure for S-3, S-4, S-6, S-7, S-8)
- Branch / PR: none; working tree only
- Base / head SHA: `develop` = `62502e9e0996f6f8222c908c67714d725195e33e`
- Dependencies: none; unblocks S-3/S-4/S-6/S-7/S-8
- Required reading: `AGENTS.md` (Swift laws 4, 6, 7, 9; file placement), `docs/architecture/ARCHITECTURE.md` §4.4 (C1–C8) and the Swift layer rules (L1–L11), `docs/product/DESIGN.md` (tokens, appearance), `docs/architecture/DECISIONS.md` ADR-13/ADR-15/ADR-17/ADR-21
- Blocking Q / gate: PO approved creating a minimal app shell inside M0 on 2026-10-31 (answer to "Tạo khung app tối thiểu trong M0"). Q-12/Q-13 (bundle id, team) are not needed for a simulator-only shell: use a placeholder bundle id and automatic signing with no team; record them as unverified.
- Goal: a SwiftUI app that builds and runs on an iOS 27 simulator and on macOS 26, so the remaining spikes have a real host. One window, one screen, no product behaviour.
- Out of scope: App Group and widget target (S-7), `HirakuBridge`/XCFramework linking (S-8), IME wrapping (S-3), adaptive layout decisions (S-4), font packaging (S-6), any study/marketing/product screen, routing, controllers, persistence, localization beyond a placeholder, CI, signing identity.
- Files / modules allowed to change: `App/**` (new: `.xcodeproj`, sources, assets, Info.plist), `Scripts/**` (new build/run helper if needed), `docs/reports/M0_SPIKE.md` (new `## App shell` note), `CHANGELOG.md` `[Unreleased]`, `ROADMAP.md` §11, `ROADMAP hiraku — Kanban.html`, `.agents/tmp/**` (scratch, gitignored).
- Permissions or PO decisions granted: PO approved the M0 app shell on 2026-10-31. Do not add third-party build tools or package managers (no xcodegen/tuist/CocoaPods/SPM deps); the project must be a checked-in Xcode project that builds with the installed Xcode 27.1.

## Acceptance criteria

1. **Project exists and builds**: `App/Hiraku.xcodeproj` with one app target usable on iOS 26+ (iPhone and iPad) and macOS 26+, deployment targets exactly 26.0 per ADR-13, Swift 6 language mode with strict concurrency (`SWIFT_STRICT_CONCURRENCY = complete`), bundle identifier placeholder `com.example.hiraku` (record that it is a placeholder).
2. **Runs on iOS simulator**: `xcodebuild -project App/Hiraku.xcodeproj -scheme Hiraku -destination 'platform=iOS Simulator,name=iPhone 18 Pro' build` succeeds, and `xcrun simctl install/launch` of the built app shows a window without crashing. Record the simulator UDID and the app path.
3. **Runs on macOS**: the same scheme builds and launches on this Mac (arm64, macOS 27). Record how it was launched and the exit code.
4. **Placeholder screen only**: one screen with the app name and a short label stating it is the M0 spike shell. No feature logic, no persistence, no network, no timers.
5. **Conventions**: no `print`, no `try!`, no force unwraps; comments in English one-liners only where the why is not obvious; no hard-coded colours or font sizes — use `Color.accentColor`/system styles only, since `DesignSystem` does not exist yet (state this explicitly in the report as a temporary exception).
6. **Structure**: `App/Hiraku/` holds the Swift sources; the project file is checked in (not generated at build time); no build output committed (extend `.gitignore` if needed — `.gitignore` is editable).
7. **Evidence**: `docs/reports/M0_SPIKE.md` `## App shell` section with the exact build/launch commands, exit codes, simulator/target used, what a screenshot would show, and the "chưa xác minh" list (signing/team, App Group, device, XCFramework).
8. **Docs/status**: CHANGELOG `[Unreleased]` entry; no ROADMAP §11 row exists for this task — add one row `App shell` with `rv` in `ROADMAP.md` §11 and a matching Kanban entry (same value), or state why not.

## Checks

| Criterion | Command / manual check | Result / exit code | Revision / artifact |
|---|---|---|---|
| Xcode version | `xcodebuild -version` | Not run | |
| iOS build | `xcodebuild -project App/Hiraku.xcodeproj -scheme Hiraku -destination 'platform=iOS Simulator,name=iPhone 18 Pro' build` | Not run | |
| iOS launch | `xcrun simctl boot/install/launch` + `xcrun simctl spawn … log` or `launchctl` check | Not run | |
| macOS build | `xcodebuild -project App/Hiraku.xcodeproj -scheme Hiraku -destination 'platform=macOS' build` | Not run | |
| macOS launch | `open`/direct binary run, confirm no crash | Not run | |
| No forbidden constructs | `grep -rn -e 'try!' -e 'print(' App` | Not run | |

## Coding

Not started.

## Independent review

- Reviewer / session: `ses_e71c8702affekKLrmNBRcFLQUU`
- Revision: working tree on `develop` = `b37073e` (the packet base `62502e9` was superseded by PR #5, agent-config restructure, which is outside this task); no commit of the task changes
- Verdict: **PASS** (draft — working tree only, not merge-eligible)
- Findings: only Low/Info — (1) `Text("hiraku")` used a localized key missing from `Localizable.xcstrings`; (2) `objectVersion = 56` will prompt an Xcode 27 upgrade notice; (3) `ENABLE_USER_SCRIPT_SANDBOXING = YES` will block a script phase when S-8 adds XCFramework generation unless declared; (4) packet wording wrongly cited Q-12/Q-13 for bundle id/team (those are ADR-17 concerns; Q-12 is the M1a/M1b split, Q-13 doc naming).
- Checks the reviewer actually ran: `plutil -lint` 0, `xmllint` 0, `xcodebuild -list` 0, iOS simulator build 0, macOS build 0, `simctl install/launch/terminate` 0, `open` + `lsappinfo` + quit 0, `grep` for `try!`/`print`/`as!`/`Date()`/`Task.sleep`/`URLSession`/hex colours → no matches, `sips` on the screenshot, `wp-status --check` 0.
- Fix applied after the verdict: `Text(verbatim: "hiraku")` plus the report sentence; `xcodebuild` iOS simulator build re-ran green and the Lead relaunched the app on simulator `379C674F-…` (PID 381, still alive after 3 s) at the fixed revision.

## Decision

- The shell is the host for S-8 (bridge/XCFramework), S-7 (App Group + second target), S-3 (IME) and S-4 (layout). Keep `ENABLE_USER_SCRIPT_SANDBOXING = YES` until a script phase needs it, then declare inputs/outputs rather than disabling the sandbox.
- Bundle id `com.example.hiraku` and an empty signing team are deliberate placeholders until WP-38/MR (ADR-17).

## Delivery

- CHANGELOG entry and ROADMAP/Kanban status updated in the PR: required in working tree
- Status: not requested
- CI / integration revision:
- Gate / PO approval:
- Actions actually taken / evidence from the target system:

## Next

On PASS, S-8 (XCFramework + bridge + device run), S-7 (App Group), S-3 (IME) and S-4 (layout) can each be dispatched against this shell, and S-6 can verify rendering. Signing team and bundle id stay placeholder until PO answers Q-12/Q-13.
