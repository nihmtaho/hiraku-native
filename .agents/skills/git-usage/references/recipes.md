# Git Recipes

Snapshot first: `scripts/inspect.sh`. Commands marked ⚠️ can lose work — confirm with the user first.

## Branching
```sh
git switch -c feature/x            # create + switch to a new branch
git switch main                    # switch to an existing branch
git branch -d feature/x            # delete a merged branch
git branch -D feature/x            # ⚠️ force-delete an unmerged branch
```

## Staging & inspecting
```sh
git add -p                         # stage interactively, hunk by hunk
git restore --staged <file>        # unstage, keep changes in working tree
git diff                           # unstaged changes
git diff --cached                  # staged changes
```

## Stashing
```sh
git stash push -m "wip: x"         # shelve current changes
git stash list
git stash pop                      # re-apply most recent and drop it
git stash drop stash@{0}           # ⚠️ discard a stash entry
```

## Syncing with the remote
```sh
git fetch --all --prune
git pull --rebase origin main      # rebase local work on top of upstream
git push -u origin HEAD            # push current branch, set upstream
git push --force-with-lease        # ⚠️ safe-ish force push after a rebase
```

## Undoing (safely)
```sh
git restore <file>                 # ⚠️ discard unstaged changes to a file
git revert <sha>                   # create a new commit that undoes <sha>
git reset --soft HEAD~1            # undo last commit, keep changes staged
git reset --mixed HEAD~1          # undo last commit, keep changes unstaged
git reset --hard HEAD~1           # ⚠️ undo last commit AND discard changes
```

## Recovery
```sh
git reflog                         # find a lost commit/branch tip
git switch -c rescue <sha>         # restore it onto a new branch
git cherry-pick <sha>              # copy a commit onto the current branch
```

## Resolving merge/rebase conflicts
```sh
git status                         # list conflicted files
# edit files, remove <<<<<<< ======= >>>>>>> markers
git add <file>
git rebase --continue              # or: git merge --continue
git rebase --abort                 # ⚠️ bail out, back to pre-rebase state
```

## Rebase / rewrite history ⚠️
```sh
git rebase -i HEAD~3               # squash/reorder/reword last 3 commits
```
Only rewrite history on branches that have NOT been shared, or where everyone
agrees. After an interactive rebase, push with `--force-with-lease`.
