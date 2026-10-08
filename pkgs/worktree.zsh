_worktree_dir=".worktree"

_worktree_usage() {
  echo "Usage: worktree <command> [args]"
  echo "Commands:"
  echo "  create <branch>  Create worktree and herdr workspace for branch"
  echo "  ls               List all worktrees"
  echo "  cd               Fuzzy-pick a worktree and cd into it"
  echo "  delete           Fuzzy-pick one or more worktrees (space to multi-select) and remove them"
}

_worktree_create() {
  local branch="${1:-}"
  if [[ -z "$branch" ]]; then
    _worktree_usage
    return 1
  fi

  local dir_name="${branch//\//-}"
  local worktree_path="$_worktree_dir/$dir_name"

  local is_new_branch=false
  if ! git worktree add "$worktree_path" "$branch" 2>/dev/null; then
    git worktree add -b "$branch" "$worktree_path"
    is_new_branch=true
  fi

  echo "Worktree created at $worktree_path"

  local root="$(git rev-parse --show-toplevel)"
  local abs_path="$(pwd)/$worktree_path"
  local repo_name="$(basename "$root")"

  # Prefix the label with the branch's author, but only for an existing
  # branch (i.e. reviewing someone else's PR) — a brand new branch has no
  # commits of its own yet, so its "author" would just be whoever last
  # committed to the base ref, not you.
  local author_prefix=""
  if [[ "$is_new_branch" == false ]]; then
    local branch_author my_name
    branch_author="$(git -C "$worktree_path" log -1 --format='%an' 2>/dev/null)"
    my_name="$(git config user.name 2>/dev/null)"
    [[ -n "$branch_author" && "$branch_author" != "$my_name" ]] && author_prefix="${branch_author}/"
  fi
  local ws_label="${author_prefix}${repo_name}/${dir_name}"

  # Create (or focus, if it already exists) a herdr workspace for this worktree.
  # Matched by checkout path, not label: every worktree of this repo now
  # shares the same label, so label can no longer identify one branch.
  local ws_id
  ws_id=$(herdr worktree list --cwd "$root" --json 2>/dev/null | \
    jq -r --arg p "$abs_path" \
      'first(.result.worktrees[] | select(.path == $p) | .open_workspace_id) // empty')

  if [[ -n "$ws_id" ]]; then
    echo "Focusing existing herdr workspace '$ws_label' ($ws_id)"
    herdr workspace focus "$ws_id" >/dev/null
  else
    echo "Creating herdr workspace '$ws_label'"
    herdr workspace create --label "$ws_label" --cwd "$abs_path" --focus >/dev/null
  fi
}

_worktree_list() {
  # Output: "<path>\t<branch>  <hash>  <commit msg>" — fzf displays only the second field
  git worktree list | awk '
  {
    path = $1; hash = $2; branch = $3
    gsub(/[\[\]]/, "", branch)
    if (length(branch) > 50) branch = substr(branch, 1, 48) ".."
    cmd = "git -C " path " log -1 --format=%s 2>/dev/null"
    msg = ""
    if ((cmd | getline msg) > 0) {
      if (length(msg) > 40) msg = substr(msg, 1, 38) ".."
    }
    close(cmd)
    paths[NR] = path; branches[NR] = branch; hashes[NR] = hash; msgs[NR] = msg
    if (length(branch) > max_len) max_len = length(branch)
  }
  END {
    fmt = "%s\t%-" max_len "s  %s  %s\n"
    for (i = 1; i <= NR; i++)
      printf fmt, paths[i], branches[i], hashes[i], msgs[i]
  }'
}

_worktree_cd() {
  local selected
  selected=$(_worktree_list | fzf --prompt="worktree > " --height=40% --reverse \
    --delimiter='\t' --with-nth=2 | cut -f1)
  [[ -z "$selected" ]] && return 0
  cd "$selected"
}

_worktree_delete() {
  local root="$(git rev-parse --show-toplevel)"
  local -a selected
  selected=("${(@f)$(_worktree_list | awk -F'\t' -v root="$root" '$1 != root' | \
    fzf --prompt="delete worktree(s) > " --height=40% --reverse --multi \
      --bind 'space:toggle+down' \
      --delimiter='\t' --with-nth=2 | cut -f1)}")
  [[ -z "${selected[1]:-}" ]] && return 0

  # Map path -> herdr workspace id before removing anything: once a worktree
  # is gone, herdr can no longer tell us which workspace was pointed at it.
  local herdr_worktrees
  herdr_worktrees=$(herdr worktree list --cwd "$root" --json 2>/dev/null)

  # Closing a workspace shifts herdr's focus elsewhere even when it wasn't
  # the focused one, so remember where we started and jump back at the end.
  local origin_ws_id
  origin_ws_id=$(herdr workspace list 2>/dev/null | \
    jq -r 'first(.result.workspaces[] | select(.focused) | .workspace_id) // empty')

  # NOTE: don't name this loop var "path" - it's a special zsh parameter
  # tied to $PATH, and reassigning it breaks command lookup mid-loop.
  local wt_path
  for wt_path in "${selected[@]}"; do
    local ws_id
    ws_id=$(jq -r --arg p "$wt_path" \
      'first(.result.worktrees[] | select(.path == $p) | .open_workspace_id) // empty' \
      <<<"$herdr_worktrees")

    if git worktree remove "$wt_path" || git worktree remove --force "$wt_path"; then
      echo "Removed worktree: $wt_path"
      if [[ -n "$ws_id" ]]; then
        herdr workspace close "$ws_id" >/dev/null 2>&1 \
          && echo "Closed herdr workspace $ws_id" \
          || echo "Failed to close herdr workspace $ws_id" >&2
      fi
    else
      echo "Failed to remove worktree: $wt_path" >&2
    fi
  done

  [[ -n "$origin_ws_id" ]] && herdr workspace focus "$origin_ws_id" >/dev/null 2>&1
}

_worktree_ls() {
  if [[ "${1:-}" == "-p" || "${1:-}" == "--path" ]]; then
    _worktree_list | awk -F'\t' '{printf "%-30s %s\n", $2, $1}'
  else
    _worktree_list | awk -F'\t' '{print $2}'
  fi
}

worktree() {
  case "${1:-}" in
    create) shift; _worktree_create "$@" ;;
    cd)     _worktree_cd ;;
    delete) _worktree_delete ;;
    ls)     shift; _worktree_ls "$@" ;;
    *)      _worktree_usage ;;
  esac
}
