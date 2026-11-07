# Parity crosswalk evidence, 2026-11-07: ZIP plain slope and Gamma structured SD

Reader: whoever owns the `unreconciled` rows in `tools/write-parity-matrix.R`.
Purpose: give route-specific evidence for 3 of the 22 unreconciled names, and
correct one test-to-row mapping. Nothing here flips a verdict.

Source pair: R drmTMB `1a23f2b00` (origin/main), Julia DRModels.jl `ba502d9d7`
(origin/main, package version 0.8.0), Julia 1.10.12, one thread, Apple silicon Mac.

## Results

| Row (exact name in the generator) | Evidence | Result |
| --- | --- | --- |
| Zero-inflated Poisson plain independent slope without `sd()` (native only) | R: `tests/testthat/test-zi-poisson-plain-slope.R`, log `r-zip-plain-slope.log`. Julia: `zip_probe.jl` on the same 480 rows (`zip_slope.csv`, from the R fixture seed 20261101), log `zip_probe.log` | R: 12 pass, 0 fail. Julia: plain `(0 + x | g)` with `zi ~ 1` REFUSES with "Poisson() random effects cannot be combined with `zi`/`hu` yet". Julia fits only with an `sd(g, coef(x)) ~ 1` formula (converged, logLik -698.62). So the Julia route for this row is NO, with a refusal. |
| Gamma slope-only phylo, spatial and relmat predictor-dependent SDs (native only) | `test_gamma_structured_slope_sd_regression.jl` | 11 + 7 + 8 pass (relmat, spatial, phylo; dense oracles) |
| Gamma ordinary + animal/phylo/spatial intercept predictor-dependent SDs (native only) | `test_gamma_phylo_sd_regression.jl` (29), `test_gamma_animal_sd_regression.jl` (15), `test_gamma_spatial_sd_regression.jl` (10) | all pass |

## Correction to the earlier scout

The scout proposed `test_gamma_relmat_sd_regression.jl` and
`test_gamma_spatial_sd_regression.jl` as slope-only evidence. They fit
`relmat(1 | g)` and `spatial(1 | g)`, which are intercept models. The slope-only
tests are in `test_gamma_structured_slope_sd_regression.jl`. Both intercept
tests pass (`gamma.log`) and support the intercept row, not the slope-only row.
`test_gamma_animal_slope_sd_regression.jl` (16 pass) is a Gamma animal
slope-only SD test, relevant to the Gamma animal rows.

## What this does not show

These are Julia-native tests and one R test on synthetic fixtures. They do not
show R-Julia numerical agreement for any row, and no bridge fit was run. The ZIP
refusal comes from one fixture and `nAGQ = 9`. A row flips only by editing the
hard-coded list in `tools/write-parity-matrix.R` and `test-parity-matrix.R` and
regenerating; I did not do that, because the generator Julia pin (`da8b3f87`) is
older than `ba502d9d7` and the release drafts #1683 and #1259 are open.
