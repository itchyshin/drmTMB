# After Task: Animal and Relmat Labelled-Slope Rejection Tests

## Goal

Finish direct source-test coverage for the generic labelled structured-slope
guard by adding `animal()` and `relmat()` examples beside their positive
one-slope Gaussian `mu` tests.

## Implemented

`test-animal-relmat-gaussian.R` now checks that
`relmat(1 + x | p | id, Q = Q)` and
`animal(1 + x | p | id, pedigree = pedigree)` fail with the intercept-only
covariance-block label message. The supported unlabelled one-slope paths remain
tested immediately above those negative cases.

## Mathematical Contract

The supported `animal(1 + x | id, ...)` and `relmat(1 + x | id, ...)` models
fit independent structured intercept and slope fields. Labelled non-intercept
blocks would imply structured slope correlations, which remain unsupported
until design, simulations, extractor rows, and docs are added.

## Files Changed

- `tests/testthat/test-animal-relmat-gaussian.R`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
Rscript --vanilla -e "invisible(parse('tests/testthat/test-animal-relmat-gaussian.R')); cat('animal relmat parse ok\n')"
Rscript --vanilla -e "devtools::test(filter = '^animal-relmat-gaussian$', reporter = 'summary')"
rg -n 'relmat\(1 \+ x \| p \| id|animal\(1 \+ x \| p \| id|covariance-block labels currently require intercept-only structured terms' tests/testthat/test-animal-relmat-gaussian.R docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd
git diff --check
```

## Tests Of The Tests

The new tests target the exact syntax users are likely to try after seeing the
supported unlabelled one-slope examples. They exercise the same parser guard as
the existing `phylo()` and `spatial()` negative tests.

## Consistency Audit

No user-facing wording changed because the formula grammar design note and
tutorial already state that labelled `animal()` and `relmat()` slope blocks are
rejected.

## GitHub Issue Maintenance

This is follow-up evidence for the structured one-slope audit and Phase 6c
random-slope boundary work. No new issue was opened.

## What Did Not Go Smoothly

The first parser-guard slice had direct negative tests for `phylo()` and
`spatial()`, but only documented `animal()` and `relmat()` examples. A read-only
agent scout identified the smallest neighbouring test location.

## Team Learning

When a generic parser guard covers several marker families, source tests should
include at least one direct example from each major marker class or explicitly
record why a marker is omitted.

## Known Limitations

This does not add structured slope correlations. It only makes unsupported
labelled slope syntax fail visibly.

## Next Actions

- Let CI confirm that the added negative tests remain portable with the rest of
  the animal/relmat Gaussian file.
