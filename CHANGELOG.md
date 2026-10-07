# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [v0.1.0] - 2026-10-07

### Added

- `Hanami/SliceExports`, which flags a slice that never calls `export`, an `export` that takes anything but a
  literal array of strings, and a key that matches `ForbiddenExports` or misses every `AllowedExports` pattern.
  `ParentClasses` names the superclasses that mark a class as a slice, `Hanami::Slice` by default.
  `RequireExport: false` lets a slice leave out `export`.

[Unreleased]: https://github.com/aaronmallen/rubocop-hanami/compare/0.1.0...HEAD
[v0.1.0]: https://github.com/aaronmallen/rubocop-hanami/releases/tag/0.1.0
