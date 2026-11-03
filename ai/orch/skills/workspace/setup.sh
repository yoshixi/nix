#!/usr/bin/env bash
# Usage: setup.sh <repo> <branch> [base] [space-name]
# Checks out <branch> of <repo> in a worktree and opens a herdr space on it.
# Starts no workers. Prints JSON. Safe to run again with the same arguments.
#   <repo>        owner/repo, or a local path inside the repo
#   [base]        start point for a new branch (default: origin/HEAD)
#   [space-name]  default: <repo name>/<branch>
set -euo pipefail
# Fixed path, not relative to $0: ~/.ai/orch/.claude/skills is a separate
# store copy of skills/ with no lib/ beside it.
source "${ORCH_LIB:-$HOME/.ai/orch/lib}/workspace.sh"

repo="${1:?usage: setup.sh <repo> <branch> [base] [space-name]}"
branch="${2:?usage: setup.sh <repo> <branch> [base] [space-name]}"
base="${3:-}"

if [[ -d "$repo" ]]; then
  # The main clone, even when the path given is one of its worktrees.
  common=$(git -C "$repo" rev-parse --path-format=absolute --git-common-dir)
  repo_dir="${common%/.git}"
else
  repo_dir=$(orch_repo_dir "$repo")
fi
space_name="${4:-${repo_dir##*/}/$branch}"

git -C "$repo_dir" fetch origin >&2

# Record what exists now, so the JSON can say what was new and what was reused.
branch_new=true
git -C "$repo_dir" show-ref --verify --quiet "refs/heads/$branch" && branch_new=false
git -C "$repo_dir" show-ref --verify --quiet "refs/remotes/origin/$branch" && branch_new=false
worktree_new=true
[[ -n "$(_orch_worktree_of_branch "$repo_dir" "$branch")" ]] && worktree_new=false
space_new=true
herdr-app ls | jq -e --arg n "$space_name" 'any(.spaces[]; .name == $n)' >/dev/null && space_new=false

wt=$(orch_worktree "$repo_dir" "$branch" "$base")
[[ -z "$base" ]] && base=$(git -C "$repo_dir" rev-parse --abbrev-ref origin/HEAD)
task_dir=$(orch_task_dir "$wt")
space=$(orch_space "$space_name" "$wt")

jq -n \
  --arg repo "$repo" --arg repo_dir "$repo_dir" --arg branch "$branch" --arg base "$base" \
  --arg worktree "$wt" --arg task_dir "$task_dir" --arg space "$space" --arg space_name "$space_name" \
  --argjson branch_new "$branch_new" --argjson worktree_new "$worktree_new" --argjson space_new "$space_new" \
  '{repo: $repo, repo_dir: $repo_dir, branch: $branch, base: $base, worktree: $worktree,
    task_dir: $task_dir, space: $space, space_name: $space_name,
    new: {branch: $branch_new, worktree: $worktree_new, space: $space_new}}'
