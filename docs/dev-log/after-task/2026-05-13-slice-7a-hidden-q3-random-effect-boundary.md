# After Task: Slice 7A Hidden q=3 Random-Effect Boundary

## Goal

Start slice 7 by proving that the hidden q=3 probe parameter can cross TMB's
random-effect boundary without changing ordinary `drmTMB()` fits or exposing
q > 2 covariance syntax.

## Implemented

`tests/testthat/test-covariance-block-registry.R` now builds the hidden
`model_type == 97` q=3 registry probe with `u_re_cov_probe` passed through
TMB's `random` argument. The test verifies that `u_re_cov_probe` is absent from
the fixed optimizer parameter vector, appears as the random-effect block inside
the TMB object, optimizes to the zero mode under the hidden standard-normal
branch, and produces a zero contribution matrix at that mode.

This is still an internal boundary test. Ordinary fits continue to map
`u_re_cov_probe` off by default, and no fitted likelihood branch uses q=3
registry contributions.

## Files Changed

- `tests/testthat/test-covariance-block-registry.R`
- `ROADMAP.md`
- `docs/design/28-double-hierarchical-endpoint.md`
- `docs/design/30-labelled-covariance-block-assembler.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-13-slice-7a-hidden-q3-random-effect-boundary.md`

## Checks Run

- `air format tests/testthat/test-covariance-block-registry.R`: passed.
- `Rscript -e 'devtools::test(filter = "covariance-block-registry")'`: passed
  with 50 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e 'devtools::test(filter =
  "covariance-block-registry|biv-gaussian|gaussian-random-intercepts|phylo-utils|package-skeleton")'`:
  passed with 948 expectations, 0 failures, 0 warnings, and 0 skips.
- `git diff --check`: passed.

## Consistency Audit

The roadmap and labelled covariance-block design note now separate three hidden
milestones: positive-definite q=3 algebra, registry-shaped member/group
contribution mapping, and TMB random-effect registration. They still describe
q > 2 covariance support as planned because production likelihood wiring,
simulation recovery, `corpairs()` rows, and reader-facing examples do not exist
yet.

## Next Actions

1. Add the first hidden likelihood prototype that injects q=3 transformed member
   contributions into one ordinary Gaussian branch.
2. Follow that with simulation recovery before exposing syntax or extractor
   rows for q > 2 blocks.
