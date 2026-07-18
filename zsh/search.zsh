# fzf history (ctrl+r) — recency-aware fuzzy search.
# history -r feeds entries most-recent-first; awk drops duplicates keeping the
# newest; --scheme=history makes fzf score for command history (recency-aware,
# tiebreak=index) instead of the default filename-oriented scoring, so recent
# matches rank above old ones. Esc keeps whatever you had typed.
function fzf-select-history() {
    local selected
    selected=$(history -n -r 1 | awk '!seen[$0]++' \
        | fzf --scheme=history --query "$LBUFFER" --reverse)
    if [ -n "$selected" ]; then
        BUFFER="$selected"
        CURSOR=$#BUFFER
    fi
    zle reset-prompt
}
zle -N fzf-select-history
bindkey '^r' fzf-select-history

# fzf cdr
function fzf-cdr() {
    local selected_dir=$(cdr -l | awk '{ print $2 }' | fzf --reverse)
    if [ -n "$selected_dir" ]; then
      BUFFER="cd ${selected_dir}"
      zle accept-line
    fi
    zle clear-screen
}
zle -N fzf-cdr
setopt noflowcontrol
bindkey '^q' fzf-cdr