{ config, pkgs, lib, ... }:
# Agent context from `ai/`, fanned out to each tool's expected location.
#
# The `~/.ai` mirror exists because the index links point there: an agent
# sandboxed to $HOME may refuse to read /etc/nix-darwin.
let
  agents = ./ai/AGENTS.md;
in
{
  home.file = {
    # `recursive` so ~/.ai stays a real directory and can hold unmanaged notes.
    ".ai" = {
      source = ./ai;
      recursive = true;
    };

    # No `@path` imports: they load eagerly at launch, defeating the index.
    ".claude/CLAUDE.md".source = agents;

    # Generated rather than symlinked only because Cursor requires frontmatter.
    # Kept a single file rather than a directory source, so Cursor can still
    # write its own rules into ~/.cursor/rules.
    ".cursor/rules/core.mdc".text = ''
      ---
      description: Personal global conventions and machine context
      alwaysApply: true
      ---

    '' + builtins.readFile agents;
  };
}
