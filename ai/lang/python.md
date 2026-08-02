# Python

## Toolchain

Python 3 from nix (`python3` on PATH). Tools installed with `pip install --user`
or `uv tool install` land in `~/.local/bin`, which is on PATH.

Prefer the project's own environment and lockfile before touching the global
interpreter. Check for `pyproject.toml`, `uv.lock`, `poetry.lock`, `Pipfile.lock`,
or `requirements.txt` and use whatever the repo already standardizes on.

When `.envrc` or `devenv.nix` is present, run commands through `devenv shell`.

## Lint and test

Run through the project's venv or `devenv shell`. Typical invocations:

- `pytest` — tests
- `ruff check` / `ruff format` — when the project uses ruff

Do not `pip install` project dependencies into the nix-managed Python.
