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

    # Orchestrator (ai/orch): `orch` starts Claude Code in ~/.ai/orch, so only
    # that session sees these skills. Kept out of ~/.claude/skills because
    # workers also run claude and must not start agents of their own.
    ".ai/orch/.claude/skills".source = ./ai/orch/skills;
    ".local/bin/orch".source = ./ai/orch/bin/orch;
    # Skills for any executor (plain `claude` or a worker). Linked one by one:
    # ~/.claude/skills also holds skills installed outside nix.
    ".claude/skills/presentation-design".source = ./ai/skills/presentation-design;
    # Worker roles for `hc run <template>`.
    ".config/herdr-core/templates".source = ./ai/orch/templates;

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
