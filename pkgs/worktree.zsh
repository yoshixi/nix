_worktree_dir=".worktree"

_worktree_usage() {
  echo "Usage: worktree <command> [args]"
  echo "Commands:"
  echo "  create <branch>  Create worktree and tmux session for branch"
  echo "  ls               List all worktrees"
  echo "  cd               Fuzzy-pick a worktree and cd into it"
  echo "  delete           Fuzzy-pick a worktree and remove it"
}

_worktree_create() {
  local branch="${1:-}"
  if [[ -z "$branch" ]]; then
    _worktree_usage
    return 1
  fi

  local dir_name="${branch//\//-}"
  local worktree_path="$_worktree_dir/$dir_name"

  git worktree add "$worktree_path" "$branch" 2>/dev/null || \
    git worktree add -b "$branch" "$worktree_path"

  echo "Worktree created at $worktree_path"

  local abs_path="$(pwd)/$worktree_path"
  local repo_name="$(basename "$(git rev-parse --show-toplevel)")"
  local session_name="${repo_name}-${dir_name}"

  if tmux has-session -t "$session_name" 2>/dev/null; then
    echo "Attaching to existing tmux session '$session_name'"
    tmux switch-client -t "$session_name" 2>/dev/null || tmux attach-session -t "$session_name"
  else
    tmux new-session -d -s "$session_name" -c "$abs_path"
    echo "Tmux session '$session_name' created"
    tmux switch-client -t "$session_name" 2>/dev/null || tmux attach-session -t "$session_name"
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
  local selected
  selected=$(_worktree_list | awk -F'\t' -v root="$root" '$1 != root' | \
    fzf --prompt="delete worktree > " --height=40% --reverse \
      --delimiter='\t' --with-nth=2 | cut -f1)
  [[ -z "$selected" ]] && return 0
  git worktree remove "$selected" || git worktree remove --force "$selected"
  echo "Removed worktree: $selected"
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
