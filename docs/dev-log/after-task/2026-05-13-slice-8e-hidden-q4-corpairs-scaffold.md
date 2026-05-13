# After Task: Slice 8E Hidden q=4 Corpairs Scaffold

## Goal

Add the first internal reporting contract for the hidden q=4 endpoint path
without exposing q4 formula syntax or claiming ordinary fitted-model support.

## Implemented

`R/methods.R` now lets registry-backed `corpairs()` ignore dormant covariance
registry pair rows whose `tmb_parameter` or `tmb_index` fields are missing. This
keeps guarded q > 2 registries inspectable without making unfitted rows appear
in extractor output.

`tests/testthat/test-covariance-block-registry.R` now includes a fitted-like
q=4 endpoint scaffold. The test attaches registry metadata and `corpars` values
to a bivariate Gaussian fit object, then checks that `corpairs(level = "group")`
formats all six endpoint rows: one `mu1`/`mu2` `mean-mean` correlation, four
`mu`/`sigma` `mean-scale` correlations, and one `sigma1`/`sigma2` `scale-scale`
correlation. It also checks class filtering, group filtering, response-scale
estimates, guarded link-scale estimates, and the dormant-registry no-row path.

## Team Roles

Ada integrated the slice. Emmy checked the extractor contract and object shape.
Curie kept the coverage focused on row formatting and filters. Rose checked
that this remains described as a hidden scaffold, not public q4 support.

## Scope Boundary

This is not ordinary q4 fitted-model support. The fitted likelihood path still
needs to populate the q4 registry pair metadata and `corpars` entries itself.
There is no public q > 2 formula syntax, no reader-facing example, and no q6/q8
random-slope endpoint claim.

## Files Changed

- `R/methods.R`
- `tests/testthat/test-covariance-block-registry.R`
- `ROADMAP.md`
- `docs/design/28-double-hierarchical-endpoint.md`
- `docs/design/30-labelled-covariance-block-assembler.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-13-slice-8e-hidden-q4-corpairs-scaffold.md`

## Checks Run

- `Rscript -e 'devtools::test(filter = "covariance-block-registry")'`: passed
  with 153 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e 'devtools::test(filter =
  "covariance-block-registry|corpairs|biv-gaussian")'`: passed with 685
  expectations, 0 failures, 0 warnings, and 0 skips.
- `air format R/methods.R tests/testthat/test-covariance-block-registry.R
  ROADMAP.md docs/design/28-double-hierarchical-endpoint.md
  docs/design/30-labelled-covariance-block-assembler.md
  docs/dev-log/check-log.md
  docs/dev-log/after-task/2026-05-13-slice-8e-hidden-q4-corpairs-scaffold.md`:
  passed.
- `git diff --check`: passed.

## Next Actions

1. Decide whether Slice 8 is complete enough to push the current stack for
   GitHub Actions, or add one more internal reporting step for
   `profile_targets()` before the push.
