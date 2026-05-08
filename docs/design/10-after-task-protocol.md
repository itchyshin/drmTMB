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
rg "simple.*mu random|sigma.*Later|currently.*only.*mu|optional simple.*location|log_sd_mu|Current TMB-side objects" README.md ROADMAP.md docs vignettes R tests
```

The goal is not only to make tests pass. It is to make sure code, docs,
examples, design notes, and site navigation describe the same package.

## Prose Audit

If the task changes README text, vignettes, pkgdown pages, after-task notes,
release notes, paper drafts, or long design docs, run a prose-style pass before
closing. Use the project-local `prose-style-review` skill.

For very small prose-only tasks, keep the report compact: record the goal,
files changed, checks, consistency audit, and any remaining limitation. Do not
inflate a one-line documentation correction into a full phase report.

Check that:

- the intended reader is clear;
- the first paragraph states the purpose before implementation details;
- model explanations pair symbolic equations, R syntax, and interpretation;
- claims are concrete and supported by citations, local files, checks, or
  explicit design assumptions;
- terms such as `sigma`, `rho12`, `sd(group)`, and `meta_known_V(V = V)` stay
  consistent;
- `tau` appears only when explaining a second shape parameter or when
  contrasting drmTMB's `sigma` with meta-analysis notation;
- users can see what to do next when a model or syntax is unsupported;
- bullets are genuine lists, not chopped prose;
- stale wording from earlier phases is either removed or superseded.

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
