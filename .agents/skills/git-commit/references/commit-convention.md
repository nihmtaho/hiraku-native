# Commit Convention (Conventional Commits)

## Format
```
<type>(<scope>): <subject>
```
Header only. No body, no footer.
- `<scope>` is optional (e.g. `api`, `ui`, `auth`). Omit if it adds nothing.
- `<subject>`: imperative mood, lower-case start, no trailing period, ≤ 72 chars.
  Good: `fix(auth): reject expired refresh tokens`
  Bad:  `Fixed the bug.`
- Say only what the change does. No task IDs (`WP-01`, `ADR-29`, `FR-12`, `#12`),
  no references to tickets, plans or history.
- Keep it simple: plain words, shortest accurate wording.
- Breaking change: add `!` after type/scope, e.g. `feat(api)!: drop v1 tokens`.

## Types
| Type       | Use for                                         |
| ---------- | ----------------------------------------------- |
| `feat`     | A new feature                                   |
| `fix`      | A bug fix                                        |
| `perf`     | Performance improvement                         |
| `refactor` | Code change that is neither a feature nor a fix |
| `docs`     | Documentation only                              |
| `style`    | Formatting, whitespace, no logic change         |
| `test`     | Adding or fixing tests                          |
| `build`    | Build system, dependencies                      |
| `ci`       | CI configuration and scripts                    |
| `chore`    | Maintenance, tooling, no src/test change        |
| `revert`   | Reverts a previous commit                       |

These types map directly to the release sections in the `git-release` skill.

## Footer — forbidden lines
Header-only means there is no footer at all. Never include any of these
(the guard script rejects them):
```
Co-authored-by: Claude <noreply@anthropic.com>
🤖 Generated with Claude Code
```

## Examples
```
feat(editor): add autosave every 30s
```
```
fix(parser): handle empty input without throwing
```
```
refactor(sync): split merge into smaller functions
```
