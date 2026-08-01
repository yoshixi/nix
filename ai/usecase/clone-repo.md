# Clone and locate repos

Repos live under ghq's layout, not an ad-hoc projects directory.

## Find first

The repo is usually already checked out.

```sh
ghq list -p | grep <name>
```

`g` fuzzy-cds to a repo; `ghqb` opens the selected one on GitHub.

## Clone

```sh
ghq get <owner>/<repo>     # -> ~/.ghq/github.com/<owner>/<repo>
```

## Notes

Use `gh` for GitHub API work (PRs, issues, checks) rather than the web UI.
