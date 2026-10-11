# Depends on worktree.zsh (_worktree_create).

# Where local clones of <owner>/<repo> may live, checked in order before
# falling back to `ghq get`.
_pr_review_roots=("$HOME/mode/src" "$HOME/mode/src/github.com" "$HOME/.ghq/github.com")

_pr_review_prompt() {
  local url="$1" base="$2"
  # Kept on one line: `herdr pane run` types it into the shell, and a newline
  # would submit the command early.
  echo "Review the GitHub PR $url. Its head branch is checked out in this worktree. Read the description with \`gh pr view $url\` and the diff with \`git diff origin/$base...HEAD\`. Follow ~/.ai/usecase/code-review.md, including its report format."
}

_pr_review_repo_dir() {
  local repo="$1" root
  for root in "${_pr_review_roots[@]}"; do
    [[ -d "$root/$repo/.git" ]] && { echo "$root/$repo"; return 0; }
  done
  ghq get "$repo" >&2 || return 1
  echo "$(ghq root)/github.com/$repo"
}

_pr_review_open() {
  local url="$1"
  local repo="${${url#https://github.com/}%/pull/*}"

  local info
  info=$(gh pr view "$url" --json number,headRefName,baseRefName,isCrossRepository) || return 1
  local number="$(jq -r .number <<<"$info")"
  local base="$(jq -r .baseRefName <<<"$info")"

  local repo_dir
  repo_dir=$(_pr_review_repo_dir "$repo") || return 1

  # A fork's branch is not on origin, so fetch it through the PR ref into a
  # local pr/<n> branch. Same-repo PRs keep their real branch name.
  local branch
  if [[ "$(jq -r .isCrossRepository <<<"$info")" == true ]]; then
    branch="pr/$number"
    git -C "$repo_dir" fetch origin "pull/$number/head:$branch" 2>/dev/null
  else
    branch="$(jq -r .headRefName <<<"$info")"
    # Fast-forward the local branch when we can; this fails if it is checked
    # out somewhere or has diverged, and then only origin/<branch> updates.
    git -C "$repo_dir" fetch origin "$branch:$branch" 2>/dev/null || \
      git -C "$repo_dir" fetch origin "$branch"
  fi
  git -C "$repo_dir" fetch origin "$base" 2>/dev/null

  pushd -q "$repo_dir" || return 1
  _worktree_create "$branch"
  local rc=$?
  popd -q
  (( rc == 0 )) || return $rc

  local root_pane="${reply[2]}" created="${reply[3]}" wt_path="${reply[4]}"
  # An existing workspace was only focused; don't start a second review in it.
  [[ "$created" == true ]] || return 0

  local nvim_pane
  nvim_pane=$(herdr pane split "$root_pane" --direction right --cwd "$wt_path" --no-focus | \
    jq -r '.result.pane.pane_id')
  herdr pane run "$nvim_pane" nvim >/dev/null
  herdr pane run "$root_pane" "claude ${(q)$(_pr_review_prompt "$url" "$base")}" >/dev/null
}

pr_review() {
  local -a urls
  urls=("${(@f)$(gh search prs --review-requested=@me --state=open --limit 100 \
      --json url,repository,number,author,title,isDraft \
      --jq '.[] | "\(.url)\t\(.repository.nameWithOwner)#\(.number)  @\(.author.login)  \(if .isDraft then "[draft] " else "" end)\(.title)"' | \
    fzf --prompt="review PR(s) > " --height=40% --reverse --multi \
      --bind 'space:toggle+down' \
      --delimiter='\t' --with-nth=2 | cut -f1)}")
  [[ -z "${urls[1]:-}" ]] && return 0

  local url
  for url in "${urls[@]}"; do
    echo "==> $url"
    _pr_review_open "$url" || echo "Failed to open review for $url" >&2
  done
}
