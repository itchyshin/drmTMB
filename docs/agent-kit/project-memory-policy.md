# Project Memory Policy

Agent memory is useful for continuity, but the repository must remain
authoritative. A new contributor should be able to understand the project by
reading checked-in files, not by inheriting one private conversation.

## Durable Memory

Use repository files for decisions that should survive across agents:

- `AGENTS.md` for operating rules and standing review roles;
- `docs/design/` for architecture, statistical contracts, and syntax rules;
- `docs/dev-log/check-log.md` for validation evidence and handoff notes;
- `docs/dev-log/after-task/` for closure reports;
- `docs/dev-log/after-phase/` for milestone closures;
- `docs/dev-log/decisions.md` for durable architectural decisions;
- issues or pull requests for discussions that need review.

## Private Or External Memory

Use private memory only as a routing layer. It can remember that a project uses
Ada and Rose, or that a repo has a strict after-task ritual. It should not be
the only place where a parameter convention, test result, or release decision
exists.

When private memory says something important, verify it against repo state if
the fact may have changed. Git status, branch state, open pull requests, CI
status, and validation output are always drift-prone.

## What To Record After Work

After a meaningful task, record:

- the goal;
- files changed;
- commands run and exact outcomes;
- searches used to detect stale claims;
- checks that were skipped;
- uncertainty and next actions;
- role-specific learning, especially what Ada, Rose, Grace, Pat, Curie, or
  Fisher should do differently next time.

## Recovery Rule

After a crash, stream failure, or context compaction, do not trust memory alone.
Start from:

```sh
git status --short --branch
git diff --stat
git diff
```

Then read the latest check-log and after-task notes. Only then continue.
