# Release Notes Template

## Versioning (SemVer: MAJOR.MINOR.PATCH)
- **MAJOR** — any breaking change (`feat!`, `fix!`, or a `BREAKING CHANGE:` footer).
- **MINOR** — at least one `feat`, no breaking changes.
- **PATCH** — only `fix` / `perf` / `refactor` / `docs` / chores.

## Template
`scripts/draft-release-notes.sh` emits exactly this shape. Only sections that
have commits are printed.

```markdown
## vX.Y.Z

### ✨ Features
- (scope) description by @author

### 🐛 Bug Fixes
- (scope) description by @author

### ⚡ Performance
- description by @author

### ♻️ Refactoring
- ...

### 📝 Documentation
- ...

### ✅ Tests
- ...

### 📦 Build & CI
- ...

### 🔧 Chores
- ...

**Full Changelog**: vX.Y.(Z-1)...vX.Y.Z
```

## Section ↔ commit type mapping
| Section            | Commit types             |
| ------------------ | ------------------------ |
| ✨ Features         | `feat`                   |
| 🐛 Bug Fixes        | `fix`                    |
| ⚡ Performance      | `perf`                   |
| ♻️ Refactoring      | `refactor`               |
| 📝 Documentation    | `docs`                   |
| ✅ Tests            | `test`                   |
| 📦 Build & CI       | `build`, `ci`            |
| 🔧 Chores           | `style`, `chore`, `revert` |

## Rules
- Bullet format: `- (scope) summary by @author`; drop `(scope)` when absent.
- Lead a MAJOR release with a short **Breaking changes** paragraph and migration steps.
- Keep bullets human-readable: trim the `type(scope):` prefix (the script does this).
- Never include AI attribution lines.

## Worked example
Latest tag `v1.0.164`, one commit since:
```
fix(linux): isolate XDG config during installer tests
```
→ bump to **v1.0.165** (patch), notes:
```markdown
## v1.0.165

### 🐛 Bug Fixes
- (linux) isolate XDG config during installer tests by @Whoosh

**Full Changelog**: v1.0.164...v1.0.165
```
