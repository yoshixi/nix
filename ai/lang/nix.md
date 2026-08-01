# Nix

nix-darwin + home-manager flake at `/etc/nix-darwin`.
Hosts: `Yoshikis-MacBook-Pro`, `Yoshikis-Mac-mini`.

## Apply changes

```sh
sudo darwin-rebuild switch
```

`git add` new files first — flake evaluation only sees tracked files, so an
unstaged file fails with `error: path '...' does not exist`.

## Check without switching

```sh
nix build ".#darwinConfigurations.Yoshikis-MacBook-Pro.system" --no-link --impure
```

`--impure` is required: `flake.nix` calls `builtins.getEnv`.

## Layout

- `flake.nix` — inputs, both hosts, overlays
- `darwin.nix` — system scope: homebrew casks, jankyborders, sketchybar
- `home.nix` — home-manager: packages, zsh, git, tmux, neovim
- `ai.nix` — agent context, mirrored to `~/.ai`
- `nvim/`, `zsh/`, `pkgs/` — files sourced by the above

## Conventions

Config an app rewrites at runtime must not be a `home.file` symlink — it would
be read-only. Known cases: `~/.claude/settings.json`, `~/.claude.json`,
`~/.claude/hooks/` (herdr regenerates its own hooks).

Generate structured config with `(pkgs.formats.toml {}).generate` rather than
hand-writing TOML.

Some casks are Homebrew deliberately: macOS Accessibility grants key to a stable
app path, which `/nix/store` breaks on every version bump. AeroSpace is the case.
