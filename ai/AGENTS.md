# Agents

Guides for operating this local environment.

## Coding

**Read before writing or reviewing code, in any language.**

- [coding](~/.ai/coding.md): comments, test style, and separating business logic from I/O.

## Languages

**Read the matching doc before writing code in that language.** These are not
loaded automatically; open the file. They are read-only — to change one, edit
its source under `/etc/nix-darwin/ai/` and rebuild.

- [go](~/.ai/lang/go.md): Go test style and code review conventions.
- [nix](~/.ai/lang/nix.md): nix-darwin config layout and how to apply changes.
- [ruby](~/.ai/lang/ruby.md): Bundler, rubocop and rspec invocation.
- [typescript](~/.ai/lang/typescript.md): Node toolchain and package manager choice.

## Task playbooks

Read when the task matches.

- [clone-repo](~/.ai/usecase/clone-repo.md): cloning or locating a repo, anything under `~/.ghq`.
- [code-review](~/.ai/usecase/code-review.md): reviewing a diff or pull request.

## Tool notes

- Claude Code: this file arrives as `~/.claude/CLAUDE.md`, a read-only symlink
  into `/nix/store`, so the `#` shortcut and `/memory` cannot write user-scope
  memory — edit `/etc/nix-darwin/ai/` and rebuild. Project memory is unaffected.
- Cursor: never modify `~/.cursor/skills-cursor/`, which Cursor manages itself.
  Rules created through Cursor's UI land in `~/.cursor/rules/` untracked — move
  any worth keeping into `/etc/nix-darwin/ai/`.
