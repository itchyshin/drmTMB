## 1. Goal

Admit, natively, predictor-dependent SD regression on a structured intercept that sits in the Gaussian residual scale: `sigma ~ 1 + phylo(1 | id, tree = tree)` (or `animal(1 | id, A = A)`, `relmat(1 | id, K = K)`, `spatial(1 | id, coords = coords)`) together with `sd(id, level = <provider level>, dpar = "sigma") ~ z`. The base route `sigma ~ phylo(...)` already existed for Gaussian, so no new public syntax is added.

## 2. Implemented

Edits to `R/drmTMB.R` only. No C++ change was needed: the structured-effect routing already sends a coefficient with a sigma endpoint into `log_sigma`, and the SD multiplier is endpoint-agnostic.

- `parse_sd_phylo_entry()` and `parse_sd_phylo_entries()` take a new argument `allow_sigma_endpoint`, default `FALSE`. Only the univariate Gaussian builder passes `TRUE`, so every other family keeps its previous behaviour.
- When the flag is on and the structured term is a single `(Intercept)` in `sigma` alone, the SD target must be `dpar = "sigma"` and the entry returns `target_dpar = "sigma"`. The existing builder `build_sd_phylo_structure()` already places the SD rows by endpoint.
- The old refusal "targets the `mu` endpoint only" is reworded to "currently targets the own endpoint of the structured term only", because a sigma structured term now has a legitimate sigma target. It still fires for a mu term with `dpar = "sigma"`, for a sigma term with `dpar = "mu"`, and for non-Gaussian families.
- A sigma structured term with `dpar` omitted is refused with "must name its endpoint", since the default would silently point at mu.
- A new Gaussian guard refuses the sigma structured SD route when it is combined with ordinary mu or sigma random effects, `meta_V()`, or missing-data models. While probing, the combination with an ordinary sigma `(1 | id)` was found to be accepted silently without evidence, so it is closed rather than claimed.

## 3. Decisions and Rejected Alternatives

- Pin swap: `test-sd-level-grammar.R:246` pinned a mu phylo term with `dpar = "sigma"`. That route is still refused, so the test was kept and only its message pattern updated to the reworded text. No assertion was removed or loosened.
- Sigma structured slopes (`relmat(0 + x | id)` in sigma) stay closed by an existing guard and are tested as refused.
- Mu plus sigma structured location-scale blocks with an SD formula stay closed (message "not implemented with residual-scale effects").
- Not attempted: q2 sigma blocks, NB2 or other-family sigma-endpoint structured SD (the flag is off for them), interval coverage.

## 4. Files Touched

- `R/drmTMB.R`
- `tests/testthat/test-gaussian-sigma-structured-sd.R` (new)
- `tests/testthat/test-sd-level-grammar.R` (one message pattern)
- `docs/dev-log/after-task/2026-11-01-gaussian-sigma-structured-q1.md` (this report)

## 5. Checks Run

All on Totoro (one process, single-threaded BLAS), `pkgload::load_all` then `testthat::test_file`.

New file `test-gaussian-sigma-structured-sd.R`: 92 passed, 0 failed, 0 errors, 0 skipped. It covers:
- For each of phylo, animal, relmat and spatial: convergence, agreement of `logLik` with a dense Laplace oracle over the structured sigma effects (absolute tolerance 1e-4; the observed differences were about 1e-9 to 1e-11), oracle mode gradient below 1e-8, positive definite Hessian, agreement of two oracle starts, finite-difference checks of the oracle gradient and Hessian, and predicted SDs equal to the SD formula by level name.
- The oracle uses only fixture quantities: `ape::vcv(tree, corr = TRUE)`, a supplied matrix, or the exponential kernel, plus its own derivatives. No drmTMB helper is called.
- Shuffled level order: factor levels, data rows and the dimnames order of the supplied K are all permuted. K for animal and relmat has a non-unit diagonal; spatial K is the exponential kernel plus a small ridge. The phylo kernel is a correlation matrix with unit diagonal by package construction, so the non-unit-diagonal requirement is not met for phylo.
- Constant-SD equivalence: `sd(...) ~ 1` against the formula-free `sigma ~ 1 + provider(1 | id)` fit, `logLik` within 1e-5 and mu and sigma coefficients within 1e-3, for all four providers.
- Emulated-bug sensitivity (relmat and phylo): flipping the SD slope sign, reversing the SD rows against the K order, and replacing the formula with a constant each moved the oracle `logLik` by between about 3 and 108 units, against a 1e-2 threshold fixed before the run (observed shifts: phylo 108, 67, 40; animal 34, 25, 6.5; relmat 33, 18, 7.0; spatial 14, 9.5, 3.3).
- Refusal checks with message patterns: mu term with sigma target, sigma term with mu target, omitted `dpar`, mu plus sigma block (with and without `dpar = "sigma"`), structured sigma slope, ordinary sigma random effect, ordinary mu random effect, `meta_V()`, Gaussian aggregation, wrong level, wrong group, within-group SD predictor, and Beta with a sigma-endpoint structured SD.

Neighbouring files re-run (passed, failed): `test-sd-level-grammar.R` 40/0; `test-gaussian-animal-sd-regression.R` 27/0; `test-gaussian-batch5-sd-regression.R` 102/1 (see below); `test-gaussian-correlated-q2-sd.R` 17/0; `test-gaussian-independent-pair-sd.R` 10/0; `test-gaussian-mu-sigma-joint-sd.R` 29/0; `test-gaussian-sd-slope-regression.R` 13/0; `test-gaussian-sigma-endpoint-mixes-sd.R` 26/0; `test-gaussian-sigma-sd-regression.R` 15/0; `test-gaussian-sigma-sd-slope-regression.R` 11/0; `test-gaussian-structured-direct-sd-providers.R` 60/0; `test-reml-direct-sd-phylo.R` 8/0; `test-structured-sd-asymmetric-alignment.R` 52/0; `test-structured-sd-clamp-report.R` 15/0; `test-structured-sd-nonunit-k-and-missing.R` 53/0; `test-structured-sd-targets.R` 16/0; `test-phase18-gaussian-sigma-random-slope.R` 28/0; `test-beta-phylo-direct-sd.R` 44/0; `test-beta-structured-intercept-q1-sd-regression.R` 56/0; `test-binomial-sd-integration.R` 366/0; `test-nbinom2-sigma-structured-recovery.R` 6/0.

Not run: Julia, `devtools::document()`, package check, vignettes, pkgdown, NEWS and capability-table entries.

## 5b. Failure not caused by these edits

`test-gaussian-batch5-sd-regression.R:460` (Gaussian relmat K numeric slope; the test-side dense optimiser returns convergence code 52). The same file gives the same 102 passed, 1 failed, 2 skipped with the unedited `R/drmTMB.R` on Totoro, so it predates this change. This route is a mu slope SD and is not touched by the edit.

## 6. What Is and Is Not Covered

Covered: native Gaussian fits of one structured sigma intercept with a predictor-dependent SD, for phylo, animal, relmat and spatial providers, with likelihood agreement to a dense Laplace oracle at the fitted parameters. The route is native TMB; Julia is not involved.

Not covered: recovery, interval coverage, calibration or parity claims; q2 or slope structured sigma effects; combinations with ordinary random effects, `meta_V()`, missing data or aggregation (all refused); other families; the `Q` or `Ainv` precision inputs for this route (only K, A, tree and coordinates were exercised); documentation, NEWS and capability-table updates.
