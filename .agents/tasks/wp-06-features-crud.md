# wp-06-features-crud — Folders, decks and words

## Contract

- Status: review
- Owner: coordinator / senior (Q-29)
- Milestone / WP: M1a / WP-06
- Branch / PR: `feat/wp-06-crud` / PR 91
- Base / head SHA: 38733ce / 4262d56
- Dependencies: WP-02b, WP-05
- Required reading: use-cases §4.0.1, UC-01, UC-02, UC-03; ADR-18, ADR-27; COPY.md (Q-28 terms)
- Blocking Q / gate: GATE-1 decisions closed 2026-11-08; waiver for device debt (S-1 iOS/60 fps, S-3 real IME); S-7 verified by slice #43
- Goal: Folder/deck/word CRUD, search, drag reorder, unsaved-change protection, note-type-driven forms.
- Out of scope: Study screens; import.
- Files / modules allowed to change: core/proto/hiraku/v1, core/gen, core/store, core/service, core/ffi (dispatch only), core/testdata, Packages/HirakuModels, Packages/HirakuBridge, Packages/HirakuTesting, Packages/Features/FeatureFolders, FeatureDecks, FeatureWords, Packages/DesignSystem (only the recorded debt items), App/Composition, App/Shell, App/Hiraku (adopt DesignSystem + catalog), App/Hiraku.xcodeproj (package references), App/HirakuTests, Scripts/check-imports.sh (feature allowlist), .github/workflows/ci.yml (feature package tests), docs/plans, docs/product/COPY.md wiring notes, CHANGELOG.md, ROADMAP.md, Kanban
- Permissions or PO decisions granted: Q-19, Q-20, Q-21 B, Q-22, Q-24, Q-27, Q-28; ADR-20/21/24/26/32 confirmed (PO 2026-11-08)

## Acceptance criteria

CRUD flows persist through the bridge; search returns paged results under 150 ms on the 50,000-note fixture; drag reorder survives restart; leaving an edited form asks before discarding; empty states render.

DesignSystem debts to close when these screens wire it:

- [ ] `HKButton` and `HKField` show a visible focus state; the custom styles draw none today (DESIGN §Components makes focus mandatory).
- [ ] A regular-width iPad passes `.pad` to `HKTextStyle.font(_:)`.
- [ ] The secondary button stroke widens to `HKBorder.increased` under Increase Contrast, like `HKCard` and `HKField`.
- [ ] The app sets `.tint(HKColor.tertiary)` at the scene root and collapses the duplicate font registration: `App/Hiraku/NotoFont.swift` registers the app's own copy from `Bundle.main`, so it either calls `HKFont.registerBundledFonts()` or drops the local copy.
- [ ] A DesignSystem test pins that `jp-hero` is the only style without a Dynamic Type anchor.

## Execution plan

- Plan: `docs/plans/2026-11-08-m1a.md` (wp-06 section)
- When working, mention both this record and the plan path; on resume, read both.

## GitHub issues

| # | Slice | Plan anchor | Status |
|---|---|---|---|
| 58 | folders | docs/plans/2026-11-08-m1a.md | open |
| 59 | decks | docs/plans/2026-11-08-m1a.md | open |
| 60 | words | docs/plans/2026-11-08-m1a.md | open |
| 61 | protection | docs/plans/2026-11-08-m1a.md | open |

Record is authority for the contract; plan is authority for progress; issues track slice status.

## Checks

| Criterion | Command / manual check | Result / exit code | Revision / artifact |
|---|---|---|---|
| App tests | `xcodebuild test -project App/Hiraku.xcodeproj -scheme Hiraku -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO` | exit 0, TEST SUCCEEDED, 7 tests | `d5fc566` |
| Search timing | `manual: 50,000 notes, search < 150 ms` | Not run — fixture not measured; deferred to S-1 follow-up | — |

## Coding

- Branch `feat/wp-06-crud` from `develop` at `38733ce`.
- Core: `catalog.proto` + `common.proto` method enum, `store/catalog.go` (note types, counts, move, duplicate meaning, exists), counts added to folder/deck queries, `service/catalog.go` (17 handlers, hand-built `ChangeSet` per mutation like `Grade`), dispatch arm, 8 service tests.
- Swift: `HirakuModels` (IDs, `Folder`/`Deck`/`NoteType`/`Note`, repositories, `AppClock`, `ChangeEvents`, `Route`, `LoadPhase`, `NameError`), `CatalogClient`, `HirakuBridge.changeSet` covers 13 methods (grade included), `ManualClock`/`FakeChangeEvents`/`FakeCatalog`, folder/deck/word controllers + views + entry points, App container/root with folder → deck → word navigation.
- Strings: 78 keys added to `App/Hiraku/Localizable.xcstrings` from COPY.md.
- `Scripts/check-imports.sh` now skips `.build` checkouts (dependency sources produced false positives).
- Review round 3 fixes: the `docs/archive/` bundle is removed from the branch for real (`git rm --cached`, files stay untracked on disk), the folder meta line uses the catalogue key, a store test proves a foreign deck cannot be reordered, and the record rows carry the evidence.
- Review round 2 fixes: COPY.md applies Q-28 "bộ thẻ"/"hồ sơ" at the source, custom field placeholders render verbatim, `reorderDecks` is scoped to its folder, and the unused `AppClock` left the folder/deck controllers.
- Review round 1 fixes: unsaved-change guard on the folder and deck sheets, Q-28 "bộ thẻ" across the deck copy, deck-specific name errors, word rows with reading and a state dot (`StateDot` in DesignSystem), CI runs the three feature test suites, deletes report `NOT_FOUND`, `now_ms > 0` on every mutation, `reorderDecks` requires the folder, and the deck/folder sheets read `isSaving` live.
- Debts recorded in the plan: contract golden bytes, `.pad` wiring for iPad, UI tests, "view existing word" navigation, first-field autofocus and keyboard shortcuts.

## Independent review

## Delivery

## Next

Read the plan section and the open issues above.
