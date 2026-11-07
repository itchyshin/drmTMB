# After Task: Gaussian phylo_interaction slope-only SD regression

## 1. Goal

Admit the Gaussian route `y ~ x + phylo_interaction(0 + x | plant:pollinator, tree1, tree2)` with `sd(pair, level = "phylogenetic_interaction") ~ predictors`, so the pair-level SD of the interaction slope field can depend on a predictor that is constant within each observed species pair.

## 2. Implemented

The only source change is in the Gaussian formula builder in `R/drmTMB.R`. The Gaussian `mu` extraction of `phylo_interaction()` now passes `allow_slope = TRUE`, so a single slope-only block is no longer refused with "Only intercept-only phylo_interaction". The slope value column, the pair-field precision and the per-pair SD path already existed in the native Gaussian engine (the shared `phylo_mu` field with per-group SD), so no C++ change was needed. The engine named here is native TMB. No Julia route is involved.

## 3. What is covered

New file `tests/testthat/test-gaussian-phylo-interaction-slope-sd.R` checks, on a native TMB fit:

- The fitted log-likelihood against the exact Gaussian marginal, computed in plain R from `ape::vcv()` trees (standardised to correlation matrices, as the engine does), the fitted fixed effects, residual SD and the fitted SD coefficients applied to the data-generating predictor. Agreement is 1e-6 relative.
- Slope-only and, with the same oracle, the intercept-only form, which was already admitted but had no test.
- Slope-only with an ordinary `(1 | plant)` intercept beside the interaction field, which the engine already accepted, checked against an exact marginal that includes the plant variance block.
- Constant-SD equivalence with the formula-free fit (2e-5 relative on logLik, 1e-4 on mu coefficients), nesting, row-order invariance, name-aligned prediction, and an error when the SD predictor varies within a pair.
- Emulated bugs: reversed, shuffled and swapped SD vectors, a constant SD, and an unstandardised K each move the oracle by more than 1e-2 log-likelihood units.
- Fixture: two ultrametric trees with random internal edges and heights 3.2 and 2.6, shuffled pair and row order. Because the engine standardises each tree to a correlation matrix, the effective K has unit diagonal; the raw covariances have diagonals 3.2 and 2.6, and the test confirms that skipping the standardisation would be detected.
- Refusals that stay closed, with message patterns: intercept plus slope in one block, two slopes in one block, `phylo_interaction` in `sigma`, a second structured provider, a mismatched SD level, and a pair label that does not identify observed pairs one-to-one.

## 4. What is not covered

No calibration, coverage or parity claim is made. Recovery of the SD slope is only checked to within 0.5 of the truth on one fixture. Not admitted and not tested beyond the refusals above: intercept plus slope blocks, several slopes, `sigma` endpoint interaction fields, REML, aggregation, missing-data routes, and any Julia route.

## 5. Checks run (Totoro, 1 process, OPENBLAS and OMP threads 1)

- `test-gaussian-phylo-interaction-slope-sd.R`: 52 passed, 0 failed, 0 errors.
- Neighbours: `test-phylo-interaction.R` 148/0/0; `test-binomial-phylo-interaction-slope-sd.R` 23/0/0; `test-poisson-batch5-sd-regression.R` 45/0/0; `test-phylo-gaussian.R` 385/0/0; `test-gaussian-batch5-sd-regression.R` 102 passed, 1 failed (see open items).

## 6. Open items

`test-gaussian-batch5-sd-regression.R` has one failure, in "Gaussian relmat K numeric slope supports a coefficient SD formula" (line 460). It is the test's own independent L-BFGS-B dense optimiser returning convergence code 52 (`gb5_expect_dense_max`), on a `relmat()` fixture. The change here touches only `phylo_interaction()` extraction, so this is not expected to be related, but a run of that file on the unchanged base was not made, so that is an inference and not a measurement.

The intercept-only Gaussian `phylo_interaction` SD route and the `(1 | plant)` beside slope route were found already working and are now tested here. Whether they should be listed in the formula-grammar docs and the evidence ledger has not been decided in this slice, and no ledger or documentation file was edited.
