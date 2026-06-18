WORKTREE_DIR=".worktree"

usage() {
  echo "Usage: $0 create <branch-name>"
  exit 1
}

cmd_create() {
  local branch="${1:-}"
  if [[ -z "$branch" ]]; then
    usage
  fi

  local dir_name="${branch//\//-}"
  local worktree_path="$WORKTREE_DIR/$dir_name"

  git worktree add "$worktree_path" "$branch" 2>/dev/null || \
    git worktree add -b "$branch" "$worktree_path"

  echo "Worktree created at $worktree_path"

  local abs_path
  abs_path="$(pwd)/$worktree_path"
  local repo_name
  repo_name="$(basename "$(git rev-parse --show-toplevel)")"
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

case "${1:-}" in
  create) shift; cmd_create "$@" ;;
  *) usage ;;
esac
