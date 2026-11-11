---
description: Commit changes to the repository.
name: commit
---

# Commit

## 1. Pick the tool

If the repository has a `.jj` directory, use `jj`. Otherwise use `git`.

## 2. Read the changes

Run `jj diff`, or `git diff HEAD` under git. Work out what landed and why. If a change does not explain
itself, ask before writing the message.

## 3. Write the message

```text
<scope>: <subject>

<body>
```

Wrap the whole message at 72 characters.

The scope names the part of the project that changed: `lib`, `spec`, `scripts`, `config`, `ci`, `docs`.

The subject names the code that landed, not what it does for a user. Write `lib: add the Hanami/SliceExports
cop`, not `lib: keep slices private`. Developers read the log to find where a change went in.

The body is prose in paragraphs. Say what the change does, then say why each decision that is not obvious
went the way it did. It is not a bulleted changelog. Leave the body out only when the subject tells the whole
story.

## 4. Commit

### With jj

```sh
jj desc --stdin <<'MSG'
lib: add the Hanami/SliceExports cop

The body goes here, already wrapped.
MSG
jj new
```

A heredoc into `--stdin` keeps the wrapping you wrote. `jj new` then starts the next change.

### With git

```sh
git add <paths>
git commit -F - <<'MSG'
lib: add the Hanami/SliceExports cop

The body goes here, already wrapped.
MSG
```

Stage the paths that belong in this commit. Do not reach for `git add -A`.

## 5. One change per commit

If the working copy holds unrelated work, split it before you describe anything.

Under jj, put the first commit's paths in their own change:

```sh
JJ_EDITOR=true jj split <paths>
```

Both halves come out with no description, so describe each one with `jj desc -r <revision> --stdin`. Set
`JJ_EDITOR`, or `jj split` opens an editor and waits forever.

Under git, stage one commit's files at a time and repeat step 4.
