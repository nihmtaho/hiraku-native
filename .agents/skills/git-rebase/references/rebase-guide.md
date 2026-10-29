# Rebase Guide

Always run `scripts/safe-start.sh` first — it creates a `backup/<branch>-<ts>`
ref so any rewrite is recoverable.

## Interactive rebase todo list
`git rebase -i <base>` opens an editor with one line per commit (oldest at top):
```
pick 1a2b3c add login form
pick 4d5e6f fix typo
pick 7g8h9i wire up submit
```
Change the leading verb:
| Verb       | Effect                                             |
| ---------- | -------------------------------------------------- |
| `pick`     | keep the commit as-is                              |
| `reword`   | keep changes, edit the message                     |
| `squash`   | merge into the previous commit, combine messages   |
| `fixup`    | like squash, but discard this commit's message     |
| `drop`     | remove the commit entirely                         |
| `edit`     | stop here to amend the commit / split it           |
Reorder by moving lines. Save and close to run.

Example — fold the typo fix into the login form commit:
```
pick   1a2b3c add login form
fixup  4d5e6f fix typo
pick   7g8h9i wire up submit
```

## Autosquash
If you committed with `git commit --fixup <sha>` / `--squash <sha>`, let git
arrange them automatically:
```sh
git rebase -i --autosquash <base>
```

## Conflicts
```sh
# git stops on a conflicted commit
git status                 # see conflicted files
# edit files, remove <<<<<<< ======= >>>>>>> markers
git add <file>
git rebase --continue      # or: git rebase --skip to drop the current commit
git rebase --abort         # cancel entirely, back to the starting state
```

## Push after rewriting
```sh
git push --force-with-lease
```
`--force-with-lease` refuses to overwrite if someone else pushed in the meantime;
plain `--force` would clobber their work.

## Recovery
- From the safety branch: `git reset --hard backup/<branch>-<ts>`
- From reflog: `git reflog` → find the pre-rebase tip → `git reset --hard <sha>`
