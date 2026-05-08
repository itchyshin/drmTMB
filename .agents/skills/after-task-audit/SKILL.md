---
name: after-task-audit
description: Audit a completed drmTMB task or phase before closing it, checking implementation, equations, examples, tests, docs, pkgdown, roadmap, NEWS, known limitations, stale wording, and after-task reporting.
---

# After-Task Audit

Use this skill before treating a meaningful `drmTMB` task or phase as complete.
It is Rose's forest-and-trees checklist: make sure the repository tells one
coherent story after code changes.

## Required Audit

1. State the implemented claim in one sentence.
2. Check code paths that implement the claim.
3. Check symbolic equations and R syntax describe the same model.
4. Check examples and vignettes use supported syntax.
5. Check tests exercise the intended behaviour and at least one failure path.
6. Run targeted tests for touched behaviour.
7. Run broader package checks when practical:
   - `devtools::test()`
   - `devtools::document()` if roxygen changed
   - `pkgdown::check_pkgdown()`
   - `pkgdown::build_site()` if user-facing docs changed
   - `devtools::check()`
8. Search for stale wording across docs and generated site.
9. For prose-heavy tasks, apply the `prose-style-review` skill before closing.
   Check reader fit, concrete claims, stable terminology, citations or local
   evidence, error recoverability, and over-bulleted prose.
10. Update roadmap, NEWS, known limitations, and design docs when behaviour
   changed.
11. Add a compact after-task report under `docs/dev-log/after-task/`.

## Stale-Wording Searches

Use task-specific searches. Common `drmTMB` patterns:

```sh
rg "meta_gaussian|tau ~|rho ~|meta_known_V\\([^V]" .
rg "full.*rejected|block.*rejected|only diagonal|planned.*implemented" README.md ROADMAP.md NEWS.md docs vignettes
rg "rho12|sigma1|sigma2|sd\\(" README.md ROADMAP.md docs vignettes R tests
```

Generated pkgdown pages can also contain stale text after a site build:

```sh
rg "full.*rejected|only diagonal|planned.*implemented" pkgdown-site
```

Do not mechanically delete historical after-task notes. If an old note was true
when written, leave it; add the new after-task report to supersede it.

## Tests Of The Tests

For new tests, verify at least one of the following:

- the new test failed before the fix;
- the test compares the likelihood to an independent calculation;
- the test checks a boundary, malformed input, or missing-data path;
- the test combines the new feature with an already-supported neighbouring
  feature.

## After-Task Report Template

```md
# After Task: <Title>

## Goal

## Implemented

## Mathematical Contract

## Files Changed

## Checks Run

## Tests Of The Tests

## Consistency Audit

## What Did Not Go Smoothly

## Team Learning

## Known Limitations

## Next Actions
```

The task is not closed until the report records what passed, what remains
uncertain, which docs/examples were synchronized, what went wrong or felt
clumsy, and which team skill or process should improve next.
