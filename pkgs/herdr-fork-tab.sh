#!/usr/bin/env bash
# Bound to prefix+shift+c (see home.nix's herdr config.toml) as a `type =
# "pane"` command: herdr runs this in a temporary pane within the current
# tab, which closes once this script exits — the real new tab it opens
# below is what's left behind.
set -euo pipefail

tab="${HERDR_TAB_ID:-}"
workspace="${HERDR_WORKSPACE_ID:-}"

if [[ -z "$tab" || -z "$workspace" ]]; then
  echo "herdr-fork-tab: no HERDR_TAB_ID/HERDR_WORKSPACE_ID in environment" >&2
  exit 1
fi

# Agents whose CLI supports resuming a session into a *new, independent*
# session id (`--resume <id> --fork-session`), so a second tab doesn't fight
# the original over the same session state. Cursor's `agent --resume` only
# has an undocumented/hidden fork flag, so it's deliberately left out here.
_fork_capable_agents='["claude","grok"]'

# The fork-capable agent running in this tab, preferring the focused pane
# when a tab has more than one (e.g. a split).
agent_json=$(herdr agent list 2>/dev/null | jq -c --argjson agents "$_fork_capable_agents" --arg tab "$tab" '
  [.result.agents[] | select(.tab_id == $tab and (.agent as $a | $agents | index($a)))]
  | (map(select(.focused)) + .)[0] // empty
')

if [[ -z "$agent_json" ]]; then
  echo "herdr-fork-tab: no fork-capable agent session in this tab, opening a plain tab" >&2
  local_label="${PWD##*/}"
  herdr tab create --workspace "$workspace" --label "${local_label:0:10}" --focus >/dev/null
  exit 0
fi

agent=$(jq -r '.agent' <<<"$agent_json")
session_id=$(jq -r '.agent_session.value' <<<"$agent_json")
cwd=$(jq -r '.cwd' <<<"$agent_json")
label="${cwd##*/}"
label="${label:0:10}"

created=$(herdr tab create --workspace "$workspace" --cwd "$cwd" --label "$label" --focus)
pane_id=$(jq -r '.result.root_pane.pane_id' <<<"$created")

herdr pane run "$pane_id" "$agent --resume $session_id --fork-session" >/dev/null
