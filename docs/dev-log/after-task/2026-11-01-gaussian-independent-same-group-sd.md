## 1. Goal

Admit one bounded native Gaussian slice: an independent intercept and an independent numeric slope on the same group, `(1 | id) + (0 + x | id)`, each with its own predictor-dependent SD formula selected by `coef`. Interval coverage remains deferred.

## 2. Implemented

One adapter flag: `allow_independent_same_group = TRUE` at the Gaussian `mu` call of `drm_scalar_sd_mu_targets()` in `R/drmTMB.R`. The helper already supported the flag (Binomial and Poisson use it), and the C++ SD scaling is provider-generic, so no C++ change. The unselected form `sd(id) ~ w` on this model stays refused.

## 3a. Decisions

Flag at the Gaussian `mu` call only; the `sigma` call is unchanged. The helper default stays FALSE.

## 4. Files Touched

- `R/drmTMB.R` (one argument added)
- `tests/testthat/test-gaussian-independent-pair-sd.R` (new)

The worktree has extensive other in-flight changes in `R/drmTMB.R`; this report does not claim them.

## 5. Checks Run

- New test: 10 expectations pass (`NOT_CRAN=true`). It was red first, at the guard `R/random-effect-targets.R:353`.
- Exact oracle: `logLik(fit)` equals a per-group multivariate-normal marginal log likelihood computed in R from the fitted coefficients, tolerance 1e-4. Constant SDs match the existing two-term fit, tolerance 2e-5. Signs and `w0`/`w1` coefficients land within 0.5 and 0.6 of simulated values (one fixture, loose).
- Neighbours passing: `gaussian-random-effect-scale`, `gaussian-sigma-sd-regression`, `gaussian-sigma-sd-slope-regression`, `gaussian-random-intercepts`, `gaussian-animal-sd-regression`.
- One failure NOT caused by this change: `test-gaussian-sd-slope-regression.R:58` expects the message "correlated-block SD regression requires a separate likelihood check", which no longer exists in `R/`. The error comes from the shape check at `R/random-effect-targets.R:303`, before the same-group logic. Left for the Gaussian correlated-q2 slice.
- Not run: Julia parity, `devtools::document()`, package check, vignettes.

## 6. Not Claimed

No receipt, no ledger row promoted, no Julia parity, no calibration, nothing committed. One simulated design.
