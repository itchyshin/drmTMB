# 2026-11-18 — fix #1731 one-level fixed-effect factor

## Scope

`drm_droplevels_fixed_predictors()` aborts with class
`drmTMB_one_level_factor` when a fixed-effect factor or character predictor
has fewer than two non-missing values. The message names the column. Factors
with two or more levels still drop unused levels and fit. Grouping factors
inside random-effect bars stay protected.

A second level that exists only on a row later removed for a missing
response is unchanged: that fit still returns, with a zero column for the
absent level.

## Evidence

`tests/testthat/test-fix-1731-one-level-factor.R` before the abort: ERR 3.
Gaussian, the unused-level collapse, and a one-value character predictor
each died in `contrasts can be applied only to factors with 2 or more levels`.
The two-level fit passed.

After the abort: FAIL 0, ERR 0, PASS 14. A factor with levels a, b, and an
unused c still informs and fits.
