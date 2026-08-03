# Agents

Guides for operating this local environment.

## Coding

**Read before writing or reviewing code, in any language.**

- [coding](~/.ai/coding.md): comments, test style, and separating business logic from I/O.

## Languages

**Read the matching doc before writing code in that language.** 

- [go](~/.ai/lang/go.md): Go test style and code review conventions.
- [nix](~/.ai/lang/nix.md): nix-darwin config layout and how to apply changes.
- [python](~/.ai/lang/python.md): venv, devenv, and project toolchain choice.
- [ruby](~/.ai/lang/ruby.md): Bundler, rubocop and rspec invocation.
- [typescript](~/.ai/lang/typescript.md): Node toolchain and package manager choice.

## Task playbooks

Read when the task matches.

- [clone-repo](~/.ai/usecase/clone-repo.md): cloning or locating a repo, anything under `~/.ghq`.
- [code-review](~/.ai/usecase/code-review.md): reviewing a diff or pull request.
- [pull-request](~/.ai/usecase/pull-request.md): writing a PR title/description, or opening one with `gh pr create`.

## Tool notes

- Claude Code: this file arrives as `~/.claude/CLAUDE.md`, a read-only symlink
  into `/nix/store`, so the `#` shortcut and `/memory` cannot write user-scope
  memory — edit `/etc/nix-darwin/ai/` and rebuild. Project memory is unaffected.
- Cursor: never modify `~/.cursor/skills-cursor/`, which Cursor manages itself.
  Rules created through Cursor's UI land in `~/.cursor/rules/` untracked — move
  any worth keeping into `/etc/nix-darwin/ai/`.
