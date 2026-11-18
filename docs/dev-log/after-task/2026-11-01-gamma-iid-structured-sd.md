# After-task note: Gamma ordinary plus structured intercept SD regression

Date: 2026-11-01. Branch: codex/general-sd-regression.

## What changed

Gamma(link = "log") now admits one unlabelled ordinary intercept `(1 | g)` beside one unlabelled q1 structured intercept on `mu` for the providers `animal()`, `phylo()` and `spatial()`, each with its own predictor-dependent SD, for example
`bf(y ~ x + (1 | g) + animal(1 | p, A = A), sigma ~ 1, sd(g) ~ zg, sd(p, level = "animal") ~ zp)`.
Related-matrix (`relmat()`) was already admitted by the earlier batch and is unchanged.

The only source edit is in `validate_positive_continuous_structured_combinations()` in `R/drmTMB.R`: a Gamma-only early return, next to the existing relmat one, for an intercept-only unlabelled structured term with exactly one unlabelled ordinary intercept and no sigma random terms. No C++ change was needed, because the Gamma model_type 5 branch already adds the ordinary random effects and the structured field (Q_phylo, with a per-row SD) to the same linear predictor. The NB2 and Poisson predicates were not touched.

## Evidence (tests/testthat/test-gamma-iid-structured-sd-regression.R)

Tolerances were fixed before the first run: oracle logLik 1e-5 absolute; A versus Ainv and term-order invariance 1e-5; constant-SD limit 1e-4 on logLik and 1e-3 on mu and sigma coefficients; predict() identity 1e-7 relative; SD-slope recovery 0.6 absolute. The sensitivity checks (reversing either SD design, or aligning K by position, must move the oracle by more than 0.1) were tightened by raising the true SD slopes to 0.9 in magnitude, after the first run showed the 0.4 slope was too weak to detect a reversed ordinary design. No agreement tolerance was changed.

For each of animal (A and Ainv), phylo and spatial: convergence; a dense independent Laplace oracle with a non-unit-diagonal K stored in shuffled order and factor levels in reversed order; name-aligned predict() of both SDs; constant-SD equivalence with the formula-free additive fit; the structured SD modelled alone with the ordinary SD scalar; term-order invariance.

Closed neighbours checked: two ordinary intercepts, an ordinary correlated `(1 + x | g)`, an ordinary sigma random effect, missing-response integration, a mismatched SD level kind, and a structured intercept-slope term beside an ordinary intercept. The ordinary `sd(g)` alone beside a structured term also stays refused ("one endpoint at a time"), as it already does for relmat.

## Not covered

No calibration, coverage or cross-engine parity claim. No simulation campaign. Only one fixture seed per provider. Spatial uses the package coordinate precision as K in the oracle. Structured slopes, q2 blocks, labelled covariance, Julia engine, Gamma sigma-side SD, and REML with this combination were not examined. Plain (no SD formula) Gamma ordinary plus animal/phylo/spatial fits are now also admitted as a side effect of the shared guard, and are only exercised through the constant-SD comparison.
