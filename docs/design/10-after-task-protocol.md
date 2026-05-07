# After-Task Protocol

Every meaningful task or phase should leave a compact Markdown report. The
report is part of the project memory and should make later Codex, Claude Code,
and human review easier.

Use the project-local `after-task-audit` skill before closing the task. That
skill is the operational checklist; this document is the stable design note.

## Location

Task reports live in:

```text
docs/dev-log/after-task/
```

Phase reports live in:

```text
docs/dev-log/after-phase/
```

## Required Sections

Each report should include:

- task goal;
- files created or changed;
- checks run and exact outcomes;
- consistency audit;
- tests of the tests;
- what did not go smoothly;
- team learning and process improvements;
- design-doc updates;
- pkgdown/documentation updates;
- known limitations and next actions.

## Consistency Audit

Before closing a task, check for stale names and syntax across the repository.
Common checks include:

```sh
rg "meta_gaussian|tau ~|rho ~|meta_known_V\\([^V]" .
rg "rho12|sigma1|sigma2|sd\\(" README.md ROADMAP.md docs vignettes R tests
```

The goal is not only to make tests pass. It is to make sure code, docs,
examples, design notes, and site navigation describe the same package.

## Tests of the Tests

When adding tests, confirm that they actually exercise the intended behaviour.
Examples:

- inspect failure messages before relaxing expectations;
- check that parser tests assert parsed fields, not only object classes;
- use deterministic seeds for future simulation tests;
- add a negative test when a rule should reject unsupported syntax.

## Closing Rule

A task is not done until the after-task report says what was checked and what
remains uncertain.
