# RuboCop::Hanami

A RuboCop plugin with cops for Hanami apps and slices. The cops live in `lib/rubocop/cop/hanami`, their defaults in
`config/default.yml`, and their specs in `spec/rubocop/cop/hanami`.

## Start Here

Read @README.md before you touch anything. It lists the cops and how to configure them. @CHANGELOG.md tracks
releases.

## Adding a cop

1. Write the cop in `lib/rubocop/cop/hanami/<name>.rb`, with `@example` blocks for bad and good code.
2. Require it from `lib/rubocop-hanami.rb`.
3. Give it an entry in `config/default.yml` with `Description`, `Enabled`, `VersionAdded` and any `Include`.
4. Spec it in `spec/rubocop/cop/hanami/<name>_spec.rb` with `expect_offense` and `expect_no_offenses`.
5. List it in the README.

## Tooling

- Ruby 4 for development. The gem supports Ruby 3.3 and up, so RuboCop targets 3.3.
- RuboCop 1.72 and up, loaded as a plugin through lint_roller.
- RSpec for tests, RuboCop for style.
- [mise] manages tools and tasks (@.config/mise.toml). Run `mise tasks` to see them.
- The repository uses [jj]. Git still works, but `jj` is the tool of record.

Always run the work through a mise task rather than calling `bundle`, `rubocop`, `rspec` or **any** other tool
yourself. The tasks in `scripts/` carry the flags and config paths this project depends on, and they are what I run,
so a bare `rubocop` reads no config at all and `rspec` runs with no spec helper.

If no existing task covers what you need, say so and suggest a new script rather than working around it with a one
off command.

`mise run setup` installs the tools and the gems. `mise run test` runs the suite, `mise run lint` runs every linter,
`mise run format` fixes what it can, and `mise run console` opens irb with the gem loaded.

## Writing Rules

Review every prose output (READMEs, changelogs, docs, commit messages) against these rules before delivering:

1. Never use a metaphor, simile or other figure of speech which you are used to seeing in print.
2. Never use a long word where a short one will do.
3. If it is possible to cut a word out, always cut it out.
4. Never use the passive where you can use the active.
5. Never use a foreign phrase, a scientific word or a jargon word if you can think of an everyday English equivalent.
6. Never use emdash
7. Break any of these rules sooner than say anything outright barbarous.

[jj]: https://jj-vcs.github.io/jj
[mise]: https://mise.jdx.dev
