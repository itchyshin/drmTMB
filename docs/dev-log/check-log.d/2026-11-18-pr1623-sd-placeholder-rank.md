# Check log: unused sd() placeholders in the #1623 rank check

**Date:** 2026-11-18
**Branch:** `cursor/fixed-design-rank-check-46f8`

## Goal

Keep the #1478 pre-fit abort for an exact fixed-effect alias such as
`sigma ~ x + xdup`, and stop that abort from firing on the unused 1x1 zero
matrix that Student, skew-normal, and beta-binomial specs store as `sd_mu`
(and beta-binomial also as `sd_sigma`) when the formula has no `sd()` term.

## Change

`drm_validate_fixed_design_rank()` skips a block only when its name is
`sd_mu` or `sd_sigma`, it is a base matrix, its dimension is 1 by 1, and its
single entry is 0. That is `empty_sd_mu_structure()$X`. A real `sd()` design
is still refused earlier by `check_sd_design_rank()`. An all-zero matrix named
`sigma` is still rank-deficient. Tolerances, expected numbers, and the public
abort message are unchanged.

## Why this is not a main failure

`origin/main` at `74007c485` does not define `drm_validate_fixed_design_rank`.
Coverage run `44318236120` on that commit completed with conclusion
`success`. The red jobs are on PR #1623 run `44318787930` (coverage shards
2/9, 5/9, and 8/9) and run `44318787883` (source-tree tests).

## Verification

R 4.3.3. Package installed with `R CMD INSTALL --library=$HOME/R/library`.
`NOT_CRAN=true`. `testthat::test_file(..., package = "drmTMB")`.

| File | Result |
| --- | --- |
| `test-fixed-design-rank.R` | pass (one existing NaN warning on the 1e-9 neighbour) |
| `test-beta-binomial.R` | pass |
| `test-beta-binomial-sd-integration.R` | pass |
| `test-beta-binomial-sd-slope-integration.R` | pass |
| `test-summary-nonconverged.R` | pass |
| `test-dinnage-audit-a3-curie.R` | pass |
| `test-clamp-extension.R` | pass |
| `test-offset-families.R` | pass |
| `test-family-dpq-batchB.R` | pass |
| `test-arc2b-mu-random-slope.R` | pass |
| `test-nongaussian-mu-random-slopes.R` | pass |
| `test-phase18-proportion-fixed-effect.R` | pass |
| `test-student-sd-integration.R` | pass |
| `test-missing-predictor-student-response.R` | pass |
| `test-nongaussian-structured-mu-slope.R` | pass |
| `test-phase18-interval-heavy-summary-smoke-runner.R` | pass |
| `test-phase18-skew-normal-fixed-effect.R` | pass |
| `test-phase18-student-shape-runner.R` | pass |
| `test-dinnage-audit-wave1.R` | pass |
| `test-reader-journeys.R` | pass |
| `test-emmeans-methods.R` | pass |
| `test-check-drm.R` | pass (existing `sd_phylo()` deprecation warnings) |
| `test-missing-response-g4g5-foundation.R` | pass |
| `test-nongaussian-structured-boundary.R` | pass |

A one-column matrix of 0 has `qr(..., tol = 1e-12)$rank` 0, so the new
placeholder expectation fails on the unfixed validator. A 1 by 1 intercept of
ones has rank 1 and is not skipped.

## Claim boundary

Full coverage shards and `R CMD check` were not rerun locally. This log covers
the files named in the red job logs.
