---
description: Review the changes on top of a base revision against the project's rules.
name: code-review
---

# Code review

Does the code follow the project's written rules?

Run the review in a sub-agent so the whole diff stays out of the main context.

## 1. Read the changes

This repository uses `jj`. The base revision is `main` unless the user named another one.

```sh
jj diff --from '<base>' --to @
jj log -r '<base>..@' --no-graph
```

Do not ask which revisions to review. `main..@` covers the work in flight, whether it sits in the working copy or in
commits below it. Take a different base only when the user names one.

Use the same `jj diff` command in the review. Keep the log as the list of changes.

Stop if the base does not exist or the diff is empty. Say what failed.

## 2. Find the project rules

Read the files that state how to write code here, such as `.claude/CLAUDE.md`, `CODING_STANDARDS.md` and
`CONTRIBUTING.md`.

Also check every change against the smell list below. The project's written rules take precedence over this list. Treat
each smell as a judgement call, never as a firm breach. Skip checks that tools enforce: `mise run lint` covers RuboCop,
markdownlint, shellcheck, yamlfmt, and editorconfig, so do not report layout, naming style, or method ordering that
those tools already catch.

- **Mysterious Name**: A name does not say what a method, variable, or class does or holds. Rename it. If no clear name
  fits, the design may need work.
- **Duplicated Code**: More than one changed place has the same logic. Extract the shared code and call it from each
  place.
- **Feature Envy**: A method uses another object's data more than its own. Move the method to the object whose data it
  uses.
- **Data Clumps**: The same fields or arguments often travel together. Put them in one type.
- **Primitive Obsession**: A primitive or string stands for a domain idea. Give that idea its own small type.
- **Repeated Conditionals**: The same `case` or `if` chain on the same type appears in several changed places. Use
  polymorphism or one shared map.
- **Shotgun Surgery**: One change needs edits across many files. Put the code that changes together in one module.
- **Divergent Change**: One file or module changes for several unrelated reasons. Split it by reason.
- **Speculative Generality**: The code adds abstractions, arguments, or hooks that nothing needs yet. Remove them until
  a real need appears.
- **Message Chains**: A caller depends on a long chain such as `a.b.c.d`. Hide the chain behind a method on the first
  object.
- **Middle Man**: A class or method does little but pass calls on. Remove it and call the real target.
- **Refused Bequest**: A subclass or included module ignores most of what it inherits. Use composition instead.

## 3. Run the review

Give the sub-agent:

- The full diff command and the change list.
- The full text of each project rule file from step 2.
- The full smell list from step 2.
- This brief: "Report each place where the diff breaks a written project rule. Name the rule and cite its file. Also
  report each smell you find, name it, and quote the relevant change. Mark written rule breaches as firm findings and
  smells as judgement calls. A written project rule takes precedence over the smell list. Skip checks that tools
  enforce. Read the tests before you call any behaviour a bug. Match the depth of the review to the change: scaffolding
  earns one or two findings, not a seven point audit. Say so when the code is fine rather than padding. Stay under 400
  words."

## 4. Report the findings

Keep the sub-agent's words as written apart from small edits for clarity.

End with one line that gives the finding count and the worst issue.
