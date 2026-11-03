---
name: workspace
description: Set up a workspace only - a git worktree of a repo on a branch, plus a herdr space opened on it. No workers. Use for requests like "create a space for <repo> with a worktree on branch X" or "set up a workspace for <repo>".
---

# Workspace

## 1. Get the inputs

- **Repo:** `owner/repo` (e.g. `moderepo/sandboxes`) or a local path.
- **Branch:** an existing branch, or a new one to create.
- Optional: a base for a new branch (default `origin/HEAD`) and a space name
  (default `<repo name>/<branch>`).

Ask only for what is missing.

## 2. Set up

```sh
~/.ai/orch/skills/workspace/setup.sh <repo> <branch> [base] [space-name]
```

It prints JSON: `worktree`, `task_dir`, `space`, `space_name`, `base`, and
`new` (whether the branch, worktree and space were created or reused). It is
safe to run again. Pass `""` for `base` when you only want to set a space name.

## 3. Report

Tell the user the worktree path, the space name, and whether each part was new
or reused. Then ask what work to do there. Do not start workers until they say.

Close it later with the `task-cleanup` skill.
