# Ruby

## Toolchain

Run through Bundler — `be` is aliased to `bundle exec`. Never use a globally
installed rubocop or rspec.

## Lint and test

Prefer the changed/staged scoping these aliases use over running the whole suite.

- `rubo` / `ruboa` — rubocop on changed `.rb` files, `-a` to autocorrect
- `rails-ruboa` — staged `.rb`, excludes `db/schema.rb`
- `grspec` — rspec on staged `_spec.rb`

`db/schema.rb` is generated — never lint or hand-edit it.
