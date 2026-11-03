# Shared setup steps for orchestrator skills. Source this file.
# Each function prints its result on stdout; progress goes to stderr so
# callers can capture stdout cleanly.

# Extra folders that hold <owner>/<repo> clones, one per line, checked before
# ghq's root. A local untracked file, so machine-specific paths stay out of
# this repo. pr_review.zsh reads the same file.
ORCH_REPO_ROOTS_FILE="${ORCH_REPO_ROOTS_FILE:-$HOME/.config/repo-roots}"

orch_repo_roots() {
  if [[ -f "$ORCH_REPO_ROOTS_FILE" ]]; then
    sed -e 's/#.*//' -e "s|^~|$HOME|" -e '/^[[:space:]]*$/d' "$ORCH_REPO_ROOTS_FILE"
  fi
  printf '%s\n' "$(ghq root)/github.com"
}

# "feat/x" -> "feat-x". Matches worktree.zsh, so both tools find the same dirs.
orch_branch_dir() {
  printf '%s\n' "${1//\//-}"
}

# orch_repo_dir <owner/repo> -> local clone path, cloning with ghq if missing.
orch_repo_dir() {
  local repo="$1" root
  while IFS= read -r root; do
    [[ -d "$root/$repo/.git" ]] && { printf '%s\n' "$root/$repo"; return 0; }
  done < <(orch_repo_roots)
  ghq get "$repo" >&2 || return 1
  printf '%s\n' "$(ghq root)/github.com/$repo"
}

# Path of the worktree that has <branch> checked out, if any. A PR branch may
# already be checked out in the main clone; git refuses a second checkout.
_orch_worktree_of_branch() {
  local repo_dir="$1" branch="$2"
  git -C "$repo_dir" worktree list --porcelain | awk -v ref="refs/heads/$branch" '
    /^worktree / { path = substr($0, 10) }
    $0 == "branch " ref { print path; exit }'
}

# orch_worktree <repo_dir> <branch> [base] -> absolute worktree path.
# Reuses an existing checkout of the branch. Otherwise uses the local branch,
# then origin/<branch>, then makes a new branch from <base> (default: origin/HEAD).
orch_worktree() {
  local repo_dir="$1" branch="$2" base="${3:-}"
  local existing
  existing=$(_orch_worktree_of_branch "$repo_dir" "$branch")
  if [[ -n "$existing" ]]; then
    echo "Reusing worktree $existing" >&2
    printf '%s\n' "$existing"
    return 0
  fi

  # Not `path`: in zsh that name is tied to PATH and would break `git`.
  local wt_path="$repo_dir/.worktree/$(orch_branch_dir "$branch")"
  if git -C "$repo_dir" show-ref --verify --quiet "refs/heads/$branch"; then
    git -C "$repo_dir" worktree add "$wt_path" "$branch" >&2 || return 1
  elif git -C "$repo_dir" show-ref --verify --quiet "refs/remotes/origin/$branch"; then
    git -C "$repo_dir" worktree add --track -b "$branch" "$wt_path" "origin/$branch" >&2 || return 1
  else
    [[ -z "$base" ]] && base=$(git -C "$repo_dir" rev-parse --abbrev-ref origin/HEAD)
    git -C "$repo_dir" worktree add --no-track -b "$branch" "$wt_path" "$base" >&2 || return 1
  fi
  printf '%s\n' "$wt_path"
}

# Workers write reports to <worktree>/.orch/. Ignore it through the repo's
# shared info/exclude so it never shows up in git status or a commit.
orch_task_dir() {
  local wt="$1"
  local exclude
  exclude="$(git -C "$wt" rev-parse --path-format=absolute --git-common-dir)/info/exclude"
  mkdir -p "$(dirname "$exclude")" "$wt/.orch"
  grep -qxF '.orch/' "$exclude" 2>/dev/null || echo '.orch/' >> "$exclude"
  printf '%s\n' "$wt/.orch"
}

# orch_space <name> <folder> -> space id. Reuses an open space with that name;
# otherwise makes one with a plain shell tab named "shell".
orch_space() {
  local name="$1" folder="$2" id
  # An empty folder would make a space rooted wherever the window is focused.
  [[ -n "$folder" && -d "$folder" ]] || { echo "orch_space: folder missing: '$folder'" >&2; return 1; }
  id=$(herdr-app ls | jq -r --arg n "$name" 'first(.spaces[] | select(.name == $n) | .id) // empty')
  if [[ -n "$id" ]]; then
    echo "Reusing space $name" >&2
  else
    id=$(herdr-app do space.new --name "$name" --folder "$folder" --tab shell | jq -r '.space // empty')
    [[ -n "$id" ]] || { echo "Failed to create space $name" >&2; return 1; }
  fi
  printf '%s\n' "$id"
}
