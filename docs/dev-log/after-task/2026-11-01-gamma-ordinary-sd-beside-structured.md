# After task: Gamma ordinary SD formula alone beside a structured intercept

Date: 2026-11-01. Branch codex/general-sd-regression.

## What changed

For Gamma(link = "log"), a model of the form
`y ~ x + (1 | g) + animal(1 | p, A = A), sigma ~ 1, sd(g) ~ zg` (no structured SD formula) was refused with "one endpoint at a time", while NB2 and Poisson admitted it. The cause was a single clause in the Gamma SD-regression gate in `R/drmTMB.R`: any structured mu term without a structured `sd(..., level = ...)` formula was refused once an SD formula existed. The model_type 5 likelihood and the SD design builders already carry an ordinary SD design and a scalar structured SD together, so no change to `src/drmTMB.cpp` was needed.

The gate now admits this case only when there is an ordinary SD formula, no sigma-side SD formula, exactly one unlabelled ordinary intercept in mu, and one unlabelled intercept-only structured term (animal, phylo, spatial or relmat). The structured SD is then a single estimated scalar, reported in `fit$sdpars$mu`.

## Tests

New file `tests/testthat/test-gamma-ordinary-sd-beside-structured.R`: a dense Laplace oracle (non-unit-diagonal K, structured covariance stored in a different order from the data factor levels, shuffled factor levels) for animal (A and Ainv), phylo and spatial; sensitivity checks that reversing the SD design or aligning K by position moves the oracle by more than 0.1; constant-SD equivalence against the formula-free fit; term-order invariance; neighbouring refusals. Tolerances were fixed before the first run.

`test-gamma-iid-structured-sd-regression.R`: the assertion that pinned the now-admitted refusal was replaced by a convergence and nesting check on the ordinary-only fit, plus a still-refused neighbour (ordinary SD beside structured with a sigma-side SD formula, which still gives "one endpoint at a time"). No tolerance was loosened and no other assertion was removed.

## Covered

Native TMB, complete responses, one ordinary SD regression with a scalar structured SD, animal, phylo and spatial through the oracle. Relmat passes the same gate but is not covered by a new oracle here.

## Not covered

Calibration or coverage, Julia (DRModels.jl), structured slopes or intercept-slope terms with an ordinary SD alone, sigma-side SDs, missing-response integration, standard errors (fits used `se = FALSE`).
