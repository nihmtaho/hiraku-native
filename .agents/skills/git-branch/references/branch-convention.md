# Branch Naming Convention

## Pattern
```
<type>/<summary>
<type>/<issue-id>-<summary>
```
- `<summary>`: lower-case kebab-case, letters/digits/hyphens only, ≤ ~40 chars.
- `<issue-id>`: the tracker number without `#` (e.g. `142`).

## Types
| Type       | Use for                                  |
| ---------- | ---------------------------------------- |
| `feat`     | New feature                              |
| `fix`      | Bug fix                                  |
| `hotfix`   | Urgent fix branched off a release/prod   |
| `refactor` | Internal change, no behaviour change     |
| `docs`     | Documentation                            |
| `test`     | Tests only                               |
| `chore`    | Tooling, deps, maintenance               |
| `release`  | Release prep (e.g. `release/v1.2.0`)     |

## Rules
- Keep names short but meaningful: `feat/passkey-login`, not `feat/stuff`.
- Include the issue id when one exists so branches link back to the tracker.
- No spaces, uppercase, or `~^:?*[\` characters (git refname rules).
- `new-branch.sh` sanitizes the summary automatically (lowercase, spaces→`-`).

## Examples
```
feat/passkey-login
fix/142-null-token-crash
hotfix/payment-timeout
refactor/extract-auth-service
release/v1.2.0
```
