# Changelog Format (Keep a Changelog)

Newest version at the top. Keep an `## [Unreleased]` section for pending work.

## Categories (in this order)
| Category     | Use for                                        |
| ------------ | ---------------------------------------------- |
| Added        | New features                                   |
| Changed      | Changes to existing behaviour                  |
| Deprecated   | Soon-to-be-removed features                    |
| Removed      | Removed features                               |
| Fixed        | Bug fixes                                      |
| Security     | Vulnerability fixes                            |

Maps roughly to commit types: `feat`→Added, behaviour `feat`/`refactor`→Changed,
`fix`→Fixed, security `fix`→Security.

## Shape
```markdown
# Changelog

All notable changes to this project are documented here.
Format: Keep a Changelog; versioning: Semantic Versioning.

## [Unreleased]

### Added
- New dark mode toggle

## [1.2.0] - 2026-10-12

### Added
- Passkey login

### Fixed
- Reject expired refresh tokens
```

## Rules
- One bullet per change, imperative-ish, user-facing language (not commit hashes).
- Date format `YYYY-MM-DD`. `scripts/changelog.sh release` uses today's date.
- `release <version>` renames `[Unreleased]` to `[<version>] - <date>` and inserts
  a new empty `[Unreleased]` above it.
- Omit empty categories in a released version.
