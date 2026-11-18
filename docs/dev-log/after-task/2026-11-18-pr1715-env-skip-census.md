# After task: census the #1706 glmmTMB skip site

Reader: a reviewer of PR #1715 after coverage shard 6/9 failed
`test-env-skip-census.R`.

## Goal

The committed env-skip census should list every skip call site in
`tests/testthat`, including the new foreign-family regression.

## Implemented

`test-fix-1706-foreign-family.R` calls `skip_if_not_installed("glmmTMB")`
once. The census scanner classifies that site as `suggests-package` /
`environment` / `runs`, because `glmmTMB` is a declared Suggests package and
the CI runner installs Suggests. The test file itself was not changed. The
comparison in `test-env-skip-census.R` stays byte-for-byte.

## Files changed

- `inst/extdata/env-skip-census.tsv`: one added row.
- this note and `docs/dev-log/check-log.d/2026-11-18-pr1715-env-skip-census.md`.

`origin/main` was merged before the census rewrite. No rebase.

## Checks run

`Rscript tools/write-env-skip-census.R --check` matched 2032 sites.
`test-env-skip-census.R` and `test-fix-1706-foreign-family.R` passed against
an install of this branch, with `glmmTMB` available so the guarded
expectations ran.

## Consistency audit

The new row is the line the shard 6/9 log printed under `NOT IN CENSUS`.
No likelihood, formula, tolerance, or family default changed.

## Tests of the tests

`--check` fails when the TSV differs from a fresh scan. Removing the new row
makes that check fail with the same message CI printed.

## What did not go smoothly

Nothing in the census rewrite. The shard log was available from
`gh run view --log-failed` because that workflow run had finished.

## Team learning

A new `skip_if_not_installed()` site has to be written into
`inst/extdata/env-skip-census.tsv` in the same change. The generator's
classification `runs` means the test is expected to execute on CI, not to
stay skipped.

## Design docs, pkgdown, and issues

No design-doc, vignette, or pkgdown change. Issue #1706 stays the existing
PR target. No issue was opened, closed, or commented on.

## Known limitations and next actions

CI on the pushed head is the remaining check. The other eight coverage
shards on this PR had already passed.
