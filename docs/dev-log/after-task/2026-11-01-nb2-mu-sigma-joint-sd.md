# After-task report: NB2 joint mu and sigma ordinary random-effect SD regression

Date: 2026-11-01. Base: branch codex/general-sd-regression at 175e87560.
Lane: predictor-dependent random-effect SD regression.

## Goal

Admit `family = nbinom2()` with one ordinary random intercept on `mu` and one
ordinary random intercept on `sigma` in the same model, each with its own
group-level SD formula:

```r
bf(y ~ x + (1 | id), sigma ~ 1 + (1 | g),
   sd(id) ~ w, sd(g, dpar = "sigma") ~ z)
```

## What changed

The native C++ NB2 block (`model_type == 7`, `src/drmTMB.cpp`) already
contains both the `mu` random-effect SD block and the `sigma` random-effect SD
block, so no C++ change and no new engine layer was needed. Two R gates in
`drm_build_nbinom2_spec()` and `validate_nbinom2_sigma_random_terms()`
in `R/drmTMB.R` refused the combination. Both now admit it through one narrow
condition: no zero inflation, complete data (no response or predictor
missingness), no structured provider on `mu` or `sigma`, exactly one
unlabelled intercept term on `mu` and one on `sigma`, and exactly one SD
formula for each. Everything else keeps the old refusals and messages.

## Covered

- Native fit of the joint model above with a dense Laplace oracle that uses
  base R only. The oracle finds the joint mode of all id and g effects (a dense
  problem, because id and g are crossed) and uses a finite-difference Hessian
  of an analytic gradient. At the fitted parameters it agrees with `logLik()`
  to about 8e-10 (tolerance 1e-3, fixed before the first run).
- The oracle surface is stationary in the seven fixed parameters at the fitted
  optimum (gradient tolerance 1e-2).
- Factor levels for both groups are shuffled relative to row order.
- Constant SD on both blocks (`~ 1`) against an independent cold-start
  maximisation of the oracle (logLik tolerance 1e-3, coefficient tolerance
  2e-2).
- Emulated-bug sensitivity: swapped SD formulas between blocks (gap about 1.65),
  mis-assigned SD predictor rows, and a dropped sigma random effect, each with a
  gap above 0.1, which is 100 times the tolerance.
- SD predictions, the `mu` and `sigma` linear predictors with their random
  effect contributions, and finite SD variance matrices.
- Refusals that stay closed, with message patterns: joint random effects with
  no SD formula, with only one of the two SD formulas, a `mu` random slope, a
  `sigma` random slope, zero inflation, missing-response integration, two `mu`
  random intercepts, and a within-group-varying SD predictor.

## Not covered

- No formula-free joint fit exists, because the joint route is refused without
  SD formulas. The constant-SD equivalence is therefore against an independent
  oracle maximisation, not a formula-free drmTMB fit.
- Structured providers (animal, phylogenetic, relmat, spatial): not applicable,
  so no non-unit-diagonal K test was needed.
- Slopes, correlated blocks, q greater than 1, several random-effect terms,
  zero inflation, missing data, and the Julia route.
- Recovery, coverage and calibration were not studied, and no parity claim with
  any other engine is made.

## Engine

Native (TMB) only. The Julia bridge is untouched.

## Checks run (Mac, one R process at a time, no Totoro)

New file `tests/testthat/test-nbinom2-mu-sigma-joint-sd.R`: 29 passed, 0
failed, 0 errors, 0 skipped. Neighbours, all with 0 failures and 0 errors:
sigma-sd-regression 14, sigma-slope-sd-regression 12,
phase18-sigma-random-effect 65, nbinom2-sd-regression 22, nbinom2-sd-integration
54, zi-nbinom2-sigma-sd-regression 24, nbinom2-location-scale 159,
nbinom2-gamma-same-group-sd-regression 38, nbinom2-ordinary-correlated-q2 25,
nbinom2-correlated-q2-sd 12, and nbinom2-batch3-sd-regression 3 skipped. No
existing refusal pin needed changing.

## Open items

- `R CMD check`, the full native sweep and documentation text were not run for
  this slice.
- The parser may refuse a joint model with the same group used in both blocks;
  not probed.
