_worktree_dir=".worktree"

_worktree_usage() {
  echo "Usage: worktree <command> [args]"
  echo "Commands:"
  echo "  create <branch>  Create worktree and herdr workspace for branch"
  echo "  ls               List all worktrees"
  echo "  cd               Fuzzy-pick a worktree and cd into it"
  echo "  delete           Fuzzy-pick one or more worktrees (space to multi-select) and remove them"
  echo "  relabel          Rename open herdr workspaces of worktrees to the current label format"
  echo "  sort             Sort herdr workspaces by repo, then by name"
}

# The sidebar already groups workspaces by repo, so the label is just the
# branch. Someone else's branch (a PR under review) gets a short author tag;
# the full name was long enough to push the branch out of view.
_worktree_label() {
  local branch="$1" author="$2" my_name="$3"
  if [[ -n "$author" && "$author" != "$my_name" ]]; then
    local short="${(L)author// /}"
    echo "${short[1,4]}/$branch"
  else
    echo "$branch"
  fi
}

# Author of the newest commit that is on this branch but not on origin's
# default branch. Empty for a fresh branch with no commits of its own, where
# the newest commit belongs to whoever last committed to the base.
_worktree_branch_author() {
  local dir="$1" base
  base=$(git -C "$dir" rev-parse --abbrev-ref origin/HEAD 2>/dev/null) || base=""
  if [[ -n "$base" ]]; then
    git -C "$dir" log -1 --format='%an' "$base..HEAD" 2>/dev/null
  else
    git -C "$dir" log -1 --format='%an' 2>/dev/null
  fi
}

# Raw socket call for API methods the herdr CLI does not expose (workspace.move).
_herdr_call() {
  local method="$1" params="$2"
  printf '{"id":"zsh","method":"%s","params":%s}\n' "$method" "$params" | \
    nc -U -w 1 "${HERDR_SOCKET_PATH:-$HOME/.config/herdr/herdr.sock}" 2>/dev/null
}

# Order the sidebar by name: one block per repo (sorted by repo name), its
# main checkout first and then its worktrees. herdr nests a worktree under
# its repo only when they sit next to each other, so this also keeps the
# groups intact; `worktree open` always adds a new workspace at the bottom.
# Workspaces with no repo info sort by their own label.
_herdr_sort_workspaces() {
  local -a order
  order=("${(@f)$(herdr workspace list 2>/dev/null | jq -r '
    .result.workspaces
    | sort_by(
        (if .worktree then .worktree.repo_root | split("/") | last else .label end | ascii_downcase),
        (if .worktree.is_linked_worktree then 1 else 0 end),
        (.label | ascii_downcase))
    | .[].workspace_id')}")
  [[ -z "${order[1]:-}" ]] && return 0

  # Move each one into place front to back; a workspace not yet placed is
  # always further down, so insert_index i lands it at slot i.
  local -a current
  local i
  for (( i = 1; i <= ${#order}; i++ )); do
    current=("${(@f)$(herdr workspace list 2>/dev/null | jq -r '.result.workspaces[].workspace_id')}")
    [[ "${current[i]}" == "${order[i]}" ]] && continue
    _herdr_call workspace.move "{\"workspace_id\":\"${order[i]}\",\"insert_index\":$((i - 1))}" >/dev/null
  done
}

# Sets reply=(workspace_id root_pane_id created worktree_path). root_pane_id
# is empty and created is false when an existing workspace was focused.
_worktree_create() {
  local branch="${1:-}"
  reply=()
  if [[ -z "$branch" ]]; then
    _worktree_usage
    return 1
  fi

  local dir_name="${branch//\//-}"
  local worktree_path="$_worktree_dir/$dir_name"

  if ! git worktree add "$worktree_path" "$branch" 2>/dev/null; then
    git worktree add -b "$branch" "$worktree_path"
  fi

  echo "Worktree created at $worktree_path"

  local root="$(git rev-parse --show-toplevel)"
  local abs_path="$(pwd)/$worktree_path"

  local ws_label
  ws_label=$(_worktree_label "$branch" "$(_worktree_branch_author "$worktree_path")" "$(git config user.name)")

  # Create (or focus, if it already exists) a herdr workspace for this worktree.
  # Matched by checkout path, not label: labels change (see relabel).
  local ws_id
  ws_id=$(herdr worktree list --cwd "$root" --json 2>/dev/null | \
    jq -r --arg p "$abs_path" \
      'first(.result.worktrees[] | select(.path == $p) | .open_workspace_id) // empty')

  if [[ -n "$ws_id" ]]; then
    echo "Focusing existing herdr workspace '$ws_label' ($ws_id)"
    herdr workspace focus "$ws_id" >/dev/null
    reply=("$ws_id" "" false "$abs_path")
  else
    echo "Creating herdr workspace '$ws_label'"
    # `worktree open` rather than `workspace create`: it tags the workspace
    # with its repo, which herdr needs to nest it. If no workspace for the
    # repo is open yet, herdr creates one to act as the parent.
    local opened
    opened=$(herdr worktree open --cwd "$root" --path "$abs_path" --label "$ws_label" --focus --json) || return 1
    ws_id="$(jq -r '.result.workspace.workspace_id' <<<"$opened")"
    reply=("$ws_id" "$(jq -r '.result.root_pane.pane_id' <<<"$opened")" true "$abs_path")
    _herdr_sort_workspaces
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

  # Map path -> herdr workspace ids before removing anything: once a worktree
  # is gone, herdr can no longer tell us which workspace was pointed at it.
  # herdr links only one workspace to a worktree, so also catch any other
  # workspace with a pane inside it.
  local herdr_worktrees herdr_panes
  herdr_worktrees=$(herdr worktree list --cwd "$root" --json 2>/dev/null)
  herdr_panes=$(herdr pane list 2>/dev/null)

  # Closing a workspace shifts herdr's focus elsewhere even when it wasn't
  # the focused one, so remember where we started and jump back at the end.
  local origin_ws_id
  origin_ws_id=$(herdr workspace list 2>/dev/null | \
    jq -r 'first(.result.workspaces[] | select(.focused) | .workspace_id) // empty')

  # NOTE: don't name this loop var "path" - it's a special zsh parameter
  # tied to $PATH, and reassigning it breaks command lookup mid-loop.
  local wt_path
  for wt_path in "${selected[@]}"; do
    local -a ws_ids
    ws_ids=(${(f)"$(
      jq -r --arg p "$wt_path" '.result.worktrees[] | select(.path == $p) | .open_workspace_id // empty' \
        <<<"$herdr_worktrees"
      jq -r --arg p "$wt_path" '.result.panes[] | select(.cwd == $p or (.cwd | startswith($p + "/"))) | .workspace_id' \
        <<<"$herdr_panes"
    )"})
    ws_ids=(${(u)ws_ids})

    # Double --force also removes locked worktrees and drops uncommitted changes.
    if git worktree remove --force --force "$wt_path"; then
      echo "Removed worktree: $wt_path"
      local ws_id
      for ws_id in "${ws_ids[@]}"; do
        herdr workspace close "$ws_id" >/dev/null 2>&1 \
          && echo "Closed herdr workspace $ws_id" \
          || echo "Failed to close herdr workspace $ws_id" >&2
      done
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

_worktree_relabel() {
  local my_name="$(git config user.name 2>/dev/null)"
  # One line per workspace: id, then the cwd of each of its panes. A pane may
  # have cd'd elsewhere, so use the first one that is inside a linked worktree.
  local line ws_id dir top branch label
  local -a fields
  herdr pane list 2>/dev/null | jq -r '
    .result.panes | group_by(.workspace_id)[]
    | [.[0].workspace_id] + map(.cwd) | @tsv' | \
  while IFS=$'\t' read -r line; do
    fields=("${(@ps:\t:)line}")
    ws_id="${fields[1]}" top=""
    for dir in "${fields[@]:1}"; do
      # A linked worktree's git dir is <repo>/.git/worktrees/<name>.
      [[ "$(git -C "$dir" rev-parse --git-dir 2>/dev/null)" == */.git/worktrees/* ]] || continue
      top=$(git -C "$dir" rev-parse --show-toplevel) && break
    done
    [[ -z "$top" ]] && continue

    branch=$(git -C "$top" branch --show-current)
    [[ -z "$branch" ]] && continue
    label=$(_worktree_label "$branch" "$(_worktree_branch_author "$top")" "$my_name")
    herdr workspace rename "$ws_id" "$label" >/dev/null && echo "$ws_id -> $label"
  done
}

worktree() {
  case "${1:-}" in
    create) shift; _worktree_create "$@" ;;
    cd)     _worktree_cd ;;
    delete) _worktree_delete ;;
    ls)     shift; _worktree_ls "$@" ;;
    relabel) _worktree_relabel ;;
    sort)    _herdr_sort_workspaces ;;
    *)      _worktree_usage ;;
  esac
}
