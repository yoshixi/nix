---
name: task-cleanup
description: Close a finished task - stop its workers, close its herdr space, and remove its worktree. Use when the user says a review or feature task is done.
---

# Task cleanup

Always confirm with the user first, naming the space, the workers and the
worktree path that will go away.

1. **Workers.** `hc ls`, then for each worker of this task (its `cwd` is in
   the worktree): `hc kill <t>; hc rm <t>`.
2. **Space.** Find its id in `herdr-app ls` by name, then
   `herdr-app do space.close --id <id> --confirmed true`.
3. **Worktree.** Run `git -C <worktree> status --porcelain`.
   - Empty: `git -C <repo> worktree remove <worktree>`. `.orch/` reports go
     with it; copy any the user wants to keep first.
   - Not empty: stop and show the user the changes. Never use `--force`
     unless they say so.
4. **Branch.** Leave it. Delete it only if the user asks.

Report what was removed and anything left behind.
