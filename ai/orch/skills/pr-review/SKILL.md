---
name: pr-review
description: Review a GitHub pull request with reviewer workers. Use when the user gives a PR URL or number and asks for a review.
---

# PR review

## 1. Set up

Get the full PR URL (ask, or use `gh pr view <n> --json url` in the repo the
user names). Then run:

```sh
~/.ai/orch/skills/pr-review/setup.sh <PR url>
```

It prints JSON: `worktree`, `task_dir`, `space`, `base`, `branch`,
`changed_files`, and more. It reuses an existing worktree and space, so it is
safe to run again.

If `task_dir` already has a `review*.md` from an earlier run, tell the user
and ask whether to review again or just show the old report.

## 2. Start reviewers

- Up to ~15 changed files: one reviewer covering the whole diff.
- Larger PRs: 2–3 reviewers, each with its own scope (for example by folder,
  or one for correctness and one for tests). Tell the user the split.

Short task names: lowercase repo name and PR number, plus a scope suffix when
there is more than one, e.g. `api-123-review`, `api-123-tests`.

```sh
hc run --bg --name <name> --cwd <worktree> --label herdr.space=<space> reviewer \
  "Review PR <url> (<title>). Head branch is checked out here. \
Diff: git diff origin/<base>...HEAD. Description: gh pr view <url>. \
Scope: <whole diff | these paths>. \
Write the report to <task_dir>/<name>.md. Do not edit other files."
```

Check `first_message.sent` in the result (see `hc --skill`).

## 3. Tell the user, then check reports as they arrive

Right after the reviewers start, tell the user who is reviewing what and the
report paths. Don't wait for them to finish.

When a reviewer reports, read its report file. If it
is missing, empty or off-scope, read the worker's screen (`hc read <name>`) and
send it a correction instead of starting a new one.

## 4. Report to the user

- One-line verdict per reviewer and an overall verdict.
- The most important findings (title + file), merged across reviewers, with no duplicates.
- The full report paths.
- Say that nothing was posted to the PR. Ask whether to post comments, ask a
  reviewer follow-up questions, or clean up (`task-cleanup` skill).

Leave the reviewers running so the user can open their tab and ask follow-ups.
