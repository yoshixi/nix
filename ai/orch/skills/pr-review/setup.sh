#!/usr/bin/env bash
# Usage: setup.sh <PR url>
# Checks out the PR's head branch in a worktree, opens a herdr space for it,
# and prints JSON the orchestrator uses to start reviewers.
set -euo pipefail
# Fixed path, not relative to $0: ~/.ai/orch/.claude/skills is a separate
# store copy of skills/ with no lib/ beside it.
source "${ORCH_LIB:-$HOME/.ai/orch/lib}/workspace.sh"

url="${1:?usage: setup.sh <PR url>}"
repo="${url#https://github.com/}"
repo="${repo%%/pull/*}"

info=$(gh pr view "$url" --json number,title,headRefName,baseRefName,isCrossRepository,author)
number=$(jq -r .number <<<"$info")
base=$(jq -r .baseRefName <<<"$info")

repo_dir=$(orch_repo_dir "$repo")

# A fork's branch is not on origin, so fetch it through the PR ref into a
# local pr/<n> branch. Same-repo PRs keep their real branch name.
if [[ "$(jq -r .isCrossRepository <<<"$info")" == true ]]; then
  branch="pr/$number"
  git -C "$repo_dir" fetch origin "+pull/$number/head:$branch" >&2 2>/dev/null || \
    git -C "$repo_dir" fetch origin "pull/$number/head" >&2
else
  branch=$(jq -r .headRefName <<<"$info")
  # Fast-forward the local branch when possible; this fails if it is checked
  # out or has diverged, and then only origin/<branch> is updated.
  git -C "$repo_dir" fetch origin "$branch:$branch" >&2 2>/dev/null || \
    git -C "$repo_dir" fetch origin "$branch" >&2
fi
git -C "$repo_dir" fetch origin "$base" >&2 2>/dev/null || true

wt=$(orch_worktree "$repo_dir" "$branch")
# A reused worktree may be behind the PR; update it only when that is safe.
git -C "$wt" merge --ff-only "@{upstream}" >&2 2>/dev/null || true
task_dir=$(orch_task_dir "$wt")
space=$(orch_space "${repo##*/}#$number" "$wt")

jq -n \
  --arg url "$url" --arg repo "$repo" --argjson number "$number" \
  --arg title "$(jq -r .title <<<"$info")" --arg author "$(jq -r .author.login <<<"$info")" \
  --arg base "$base" --arg branch "$branch" --arg worktree "$wt" \
  --arg task_dir "$task_dir" --arg space "$space" \
  --argjson changed "$(git -C "$wt" diff --name-only "origin/$base...HEAD" | wc -l | tr -d " ")" \
  '{url: $url, repo: $repo, number: $number, title: $title, author: $author,
    base: $base, branch: $branch, worktree: $worktree, task_dir: $task_dir,
    space: $space, changed_files: $changed}'
