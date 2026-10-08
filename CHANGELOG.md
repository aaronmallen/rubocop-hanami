# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [v0.2.0] - 2026-10-07

### Added

- `Hanami/ActionCallOverride`, which flags `def call` in an action, where `handle` belongs. A class counts as an
  action when its file sits under `actions` or it inherits from one of `ParentClasses`, `Hanami::Action` by
  default. A `call` that calls `super` passes.
- `Hanami/AppReferenceInSlice`, which flags `Hanami.app` in a slice, outside slice `config`. It leaves lookups such
  as `Hanami.app["logger"]` to `Hanami/ContainerLookup` while that cop is on. `AppNamespaces` names the host app's
  top-level modules, such as `MyApp`, to flag those too.
- `Hanami/ContainerLookup`, which flags a lookup by literal key on `Hanami.app`, on `Hanami.app.slices[...]` or on
  any constant that ends in `Slice`, where `include Deps[...]` would do. This also catches code that reaches into
  another slice's container without `import`. `AllowedReceivers` names constants to skip.
- `Hanami/EnvAccess`, which flags `ENV` outside settings, providers, `config/app.rb`, `config/puma.rb`, `bin`, `db`
  and `spec`, so values go through Hanami settings and fail at boot when missing.
- `Hanami/PersistenceInAction`, off by default, which flags a repo or relation in an action's `include Deps[...]`.
  `ForbiddenKeyPrefixes` match at the start of any segment, so an imported `search.repos.index` counts.
  `AllowedKeys` takes strings and regular expressions to let keys through.
- `Hanami/ProviderTopLevelRequire`, which flags `require` and `require_relative` in a provider outside `prepare`
  and `start`.
- `Hanami/RelationOutsideRepo`, which flags a relation, or the ROM container, in `include Deps[...]` outside
  `repos`, `relations` and `db`. `RelationKeyPrefixes` and `ROMKeys` name the keys to flag.
- `Hanami/SliceNamespace`, which flags a top-level `module` or `class` in `slices/<name>/` that doesn't open the
  slice's namespace, so a Zeitwerk load error shows up at lint time. `Inflections` names slices that don't
  camelize plainly, such as `api: API`.
- `Hanami/UnusedDeps`, which flags a key in `include Deps[...]` whose accessor the class never reads. It can't see
  reads in a subclass in another file, so disable it on keys meant for subclasses.
- `Hanami/UnvalidatedParams`, which flags `[]`, `fetch` and `dig` on `request.params` in an action that declares no
  `params` or `contract`. `AllowedParentClasses` skips subclasses of a validated base action.
- `Hanami/UnwrappedStep`, which flags a call in an operation's flow to a method that returns `Success` or `Failure`
  but isn't passed to `step`, since dry-operation drops the `Failure`. `FlowMethods` names the flow methods, `call`
  by default, and the cop reads `operate_on` too.

### Fixed

- `Hanami/SliceExports` no longer warns that it does not support `AllowedExports` when a config sets it.

## [v0.1.0] - 2026-10-07

### Added

- `Hanami/SliceExports`, which flags a slice that never calls `export`, an `export` that takes anything but a
  literal array of strings, and a key that matches `ForbiddenExports` or misses every `AllowedExports` pattern.
  `ParentClasses` names the superclasses that mark a class as a slice, `Hanami::Slice` by default.
  `RequireExport: false` lets a slice leave out `export`.

[Unreleased]: https://github.com/aaronmallen/rubocop-hanami/compare/0.2.0...HEAD
[v0.2.0]: https://github.com/aaronmallen/rubocop-hanami/releases/tag/0.2.0
[v0.1.0]: https://github.com/aaronmallen/rubocop-hanami/releases/tag/0.1.0
