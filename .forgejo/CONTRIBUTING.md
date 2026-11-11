# Contributing

Thanks for helping. This says how the project is built and what a change is expected to carry.

## Getting set up

[mise](https://mise.jdx.dev) manages the tools and the tasks. Run `mise tasks` to see them all.

```sh
mise run setup       # Install tools and dependencies
mise run test        # Run the test suite
mise run lint        # Lint every file
mise run format      # Fix what can be fixed
```

Run the work through a task rather than calling `bundle`, `rubocop` or `rspec` yourself. The tasks carry the flags
and config paths the project depends on: a bare `rubocop` reads no config, and a bare `rspec` runs with no spec
helper. If no task covers what you need, say so and suggest one.

## Cops

Each cop lives in `lib/rubocop/cop/hanami`, has an entry in `config/default.yml`, and has a spec in
`spec/rubocop/cop/hanami` that covers each offense it reports and the code it lets through. A new cop arrives with
all three, a README entry, and a line in the changelog.

## Commits

One change per commit. The subject names the code that landed, not what it does for a user, because that is what
people search the log for.

```text
lib: add the Hanami/SliceExports cop
```

The scope names the part of the project: `lib`, `config`, `spec`, `scripts`, `ci`, `docs`. The body is prose, and
it says why any decision that is not obvious went the way it did.
