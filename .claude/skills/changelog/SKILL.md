---
description: Update the changelog's Unreleased section from the commits since the last release.
name: changelog
---

# Changelog

`CHANGELOG.md` follows [Keep a Changelog]. The Unreleased section becomes the release notes when a tag is pushed, so
it is written for someone bundling the gem, not for whoever wrote the code.

## 1. Read the commits since the last release

This repository uses `jj`. Fall back to `git` only if there is no `.jj` directory.

```sh
git tag --sort=-creatordate | head -1
jj log -r '<tag>..@' --no-graph -T 'description ++ "\n"'
```

Under git, `git log <tag>..HEAD --reverse`.

Read the bodies, not just the subjects. A commit message here says what landed and why each decision that is not
obvious went the way it did, and that reasoning is what an entry is built from. Read the diff when a message leaves
you guessing.

## 2. Decide what a user would notice

This project does not use conventional commits. The scope names the part of the project that changed, which is a
starting point rather than a rule:

| Scope                   | Usually                                                                        |
|-------------------------|--------------------------------------------------------------------------------|
| `lib`                   | An entry. This is the gem.                                                     |
| `config`                | An entry when `config/default.yml` changes. None for the tooling in `.config`. |
| `docs`                  | An entry only for documentation a user would go looking for                    |
| `spec`, `scripts`, `ci` | No entry. Nothing a user installs changed.                                     |

A new cop, a new setting, or a change to what a cop flags or how it corrects earns an entry. A refactor that leaves
every offense where it was earns none.

When neither test helps, ask what breaks or improves for someone who writes `gem "rubocop-hanami"` and nothing else. If
the answer is nothing, leave it out.

## 3. Sort the entries into categories

Use the [Keep a Changelog] categories, in this order: Added, Changed, Deprecated, Removed, Fixed, Security. Only
categories with entries appear.

- **Added**: a class, module, method or convention that did not exist before.
- **Changed**: behaviour that now works differently. Say what a user upgrading has to do about it.
- **Fixed**: something that was broken. Name the breakage, not just the repair.
- **Removed**: something a user could reach that is gone.

Deprecated and Security stay empty most of the time. Before 1.0 a cop or setting can be renamed with no deprecation
cycle, so a rename lands under Changed with a plain sentence about what to write instead, not under Deprecated.

## 4. Write the entries

Match the entries already in the file:

- **Name the cop.** `Hanami/SliceExports`, `AllowedExports`. The cop and setting names are the interface, and a user
  searching for one should land here.
- **One entry per thing a user can use**, not one per commit. Three commits that built a cop and two settings are one
  entry for the cop and one for each setting.
- **Say what changed, then why it matters** when the why is not obvious. Two sentences beat one vague one.
- **Wrap at 120 columns**, with continuation lines indented two spaces.
- **Reference-style links at the bottom** for gems and documentation, the way `[Keep a Changelog]` is linked below.
- **No Linear issue references.** The tracker is private, and an entry that needs an issue to make sense is not
  written well enough.
- **Credit an outside contributor** with a reference-style link to their GitHub profile, the way the release lines
  already credit maintainers. Work by the maintainer needs no credit.

Every rule in the writing rules section of `.claude/CLAUDE.md` applies. It names changelogs.

Good:

```markdown
- `Hanami/SliceExports`, which flags a slice that never calls `export` and checks each exported key against
  `AllowedExports` and `ForbiddenExports`.
- `Hanami/SliceExports` reads a slice defined as `module Admin; class Slice < ::Hanami::Slice`. It used to skip
  any slice whose superclass started with `::`.
```

Bad:

```markdown
- lib: add the slice exports cop
- Fixed a bug in SliceExports
- Improved the developer experience around slices
```

The first is a commit subject. The second names no breakage. The third says nothing at all.

## 5. Update the file

Replace the contents of the `## [Unreleased]` section and nothing else. Leave released sections alone, even when they
read badly. They describe what shipped.

Check the link definitions at the bottom while you are there. `[Unreleased]` compares the latest tag to `HEAD`, and
every version heading needs a matching definition.

## 6. Check it

Run `mise run lint`, which holds the file to 120 columns. Then show the user the new Unreleased section.

## At release time

Rename `## [Unreleased]` to `## [vX.Y.Z] - YYYY-MM-DD`, add an empty Unreleased section above it, and add the link
definitions for both. The release workflow reads the section whose heading matches the tag, so
`.github/workflows/release.yml` publishes nothing for tag `0.2.0` without a `## [v0.2.0]` heading.

[Keep a Changelog]: https://keepachangelog.com/en/1.1.0/
