---
name: flow-feature
description: >-
  Add a new feature as a vertical slice following the module map in PROJECT.md
  §Architecture rules: package layout, dependency protocols, the layers your
  architecture names, wiring, and tests. Use for a new feature or a new mode; not for
  small fixes inside an existing feature.
compatibility: Git; the UI toolchain named in PROJECT.md; run from the repository root.
---

Read `PROJECT.md` at the repo root first. If it is missing, stop and ask the user to
create it from the kit's `PROJECT.md.example`.

You add a feature as one vertical slice. Paths are relative to the repository root.

## Input and sources

Receive the task packet with its use cases, milestone, platform scope, and the core
APIs it needs.

Read the sections of the architecture rules file named in `PROJECT.md` §Architecture
rules that this feature touches, the spec and use cases for the task, and the design
and copy documents per `PROJECT.md` §Docs map. An unresolved business decision: do not
stub it in the UI layer — return BLOCKED.

## Workflow

1. Check the existing features and the module map in `PROJECT.md` §Architecture rules.
   Prefer extending an existing feature; never add a package only to split files.
2. Create the feature package with the layers your architecture names (for example
   model, view, and controller) and tests, following the layout the architecture rules
   name and the pattern of neighboring features. It may depend only on modules the
   architecture permits; declare the testing module in both the package dependencies and
   the test target when it uses fakes.
3. Define dependencies behind protocols with a public entry point. Business logic that
   does not need the platform belongs on the core side per `PROJECT.md` §Architecture
   rules. A missing RPC: use the `flow-interface` skill and keep the dependency order;
   never parse the stored records or query the database from the UI side.
4. Write the controller as main-actor and observable, receiving dependencies through
   init with no I/O in init; load in `start()`, cancel tasks in `stop()`; use the app
   clock and fakes to test success, failure, cancellation, and that a failed write
   never advances to the next step.
5. Write passive views: design tokens, app icon symbols, the string catalog, and
   native chrome per `PROJECT.md` §Quality rules. Names the user gives fields or
   profiles are data; never put them in the catalog.
6. Wire the route in the models module, and the mapping and dependencies at the app
   composition root; compose through route, closure, or slot — never import another
   feature or the bridge module. A new study-mode equivalent (if any) implements the
   mode protocol and registers in your feature registry; the base study feature must not
   learn concrete modes.
7. Check layout within the milestone scope, focus and IME behavior, Dynamic Type and
   VoiceOver, Reduce Motion, and error, empty, and loading states. State which
   platforms are not implemented per the task; never claim a simulator replaces
   acceptance on real devices.
8. Update the import rules and the module/feature table when a module is truly added;
   update spec, use cases, design, and copy for the change. Protected policy or
   checker changes: hand them to the PO/operator to apply; never bypass the process.
9. Run the package tests with fakes, the import check, and the app integration tests
   listed in `PROJECT.md` §Checks. Independent package checks must not require linking
   the real core.

## Optional SwiftUI example

Optional example only, for a SwiftUI project. Do not change the layer model in
`PROJECT.md` §Architecture rules; these are tips inside that frame and come from
`swiftui-patterns` by affaan-m/ecc (MIT, commit `b38be6a`):

- Simplest wrapper: `@State` for the view's own state (sheet, focus), `@Bindable` for
  the passed controller, `@Environment(Type.self)` instead of `@EnvironmentObject`; no
  new `ObservableObject`/`@Published`.
- Split small subviews, pass values instead of the whole controller, so only property
  reads trigger redraws.
- `List`/`ForEach` use a stable `id` (wrapped-ID types), never the index; no heavy
  computation or formatting in `body` — move it to the controller.
- `.task` calls `controller.start()`; cancel with the view's lifecycle, never hold a
  `Task` yourself.
- Previews build the controller with a fake from the testing module named in
  `PROJECT.md` §Architecture rules.

## Handoff and stop conditions

Return the entry point, wiring, resources, tests, and evidence against the task's
criteria. A missing API, decision, toolchain, or required check: PARTIAL/BLOCKED.
Never add a singleton, never put a mock in production code, never bypass concurrency
just to get a build.

If you are reviewing: only check the checklist and run authorized tests; do not create
packages, update import rules, or edit source.
