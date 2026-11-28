# After task: unused sd() placeholders are not fixed-effect designs

Reader: a reviewer of PR #1623 after coverage shards 2/9, 5/9, and 8/9, and
the source-tree test job, aborted ordinary Student, skew-normal, and
beta-binomial fits.

## Goal

The pre-fit rank check should refuse an exact fixed-effect alias. It should
leave a model with no `sd()` formula able to fit.

## Implemented

Student, skew-normal, and beta-binomial specs always put `sd_mu$X` into
`spec$X`. Beta-binomial also puts `sd_sigma$X` there. With no `sd()` formula
that object is the 1 by 1 zero from `empty_sd_mu_structure()`, whose QR rank
is 0. `drm_validate_fixed_design_rank()` treated the name `sd_mu` as a
distributional parameter and aborted before `nlminb`.

The validator now skips that placeholder only. A duplicated `sigma` column
still aborts, including when the placeholders sit beside it. A real `sd()`
design remains the job of `check_sd_design_rank()`.

## Files changed

- `R/drmTMB.R`: `drm_is_unused_sd_placeholder()` and the skip.
- `tests/testthat/test-fixed-design-rank.R`: placeholder passes; duplicated
  `sigma` still aborts.
- this note and `docs/dev-log/check-log.d/2026-11-18-pr1623-sd-placeholder-rank.md`.

`origin/main` was merged before the edit. No rebase.

## Checks run

Listed with results in the check-log shard. Every previously failing file
from runs `44318787930` and `44318787883` passed locally under `NOT_CRAN=true`.
Full shards and `R CMD check` were not rerun.

## Consistency audit

```sh
rg "every named block|rank-deficient" docs/dev-log/known-limitations.md docs/design NEWS.md
```

`NEWS.md` still says collinear fixed-effect designs abort at spec-build time.
That claim stays true. `docs/dev-log/known-limitations.md` has no
rank-deficient claim to update. The 2026-10-25 after-task note still says the
validator walks every named block in `spec$X`. That was the note for the
first implementation; this note supersedes it. The historical file was left
as written.

No formula, likelihood, tolerance, default, or estimand changed.

## Tests of the tests

`qr(matrix(0, 1, 1), tol = 1e-12)$rank` is 0, so the new
`expect_true(drm_validate_fixed_design_rank(spec))` fails if the skip is
removed. The same spec with `sigma` columns `1:4` and `1:4` still matches
`rank-deficient.*sigma`.

## What did not go smoothly

`gh run view --log-failed` refused logs because the workflow runs were still
open. Job logs were downloaded from the Actions job API instead. Shard 8/9
was red as well as the shards named in the task, for the same placeholder.

## Team learning

A block in `spec$X` is not always a fixed-effect design. `sd_mu` and
`sd_sigma` are also the unused random-effect scale placeholder.

## Design docs, pkgdown, and issues

No design-doc, vignette, or pkgdown change. The public abort is unchanged.
Issue #1478 stays the existing PR target. No issue was opened, closed, or
commented on.

## Known limitations and next actions

Sparse-fixed `mu` is still skipped. Near-collinear columns between `1e-12`
and `1e-8` still fit and remain a `check_drm()` note. CI on the pushed head
is the remaining check.
