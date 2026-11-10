# Check log — 2026-11-10 — fix #1707 predict.drmTMB Rd example

## Goal

Replace the pathological six-row `sigma ~ x` example in `?predict.drmTMB` with a
simulated Gaussian location-scale fit that converges without warnings.

## Changes

- `R/methods.R`: `set.seed(20261110)`, `n = 120`, heteroscedastic DGP, same
  `predict()` calls.
- `tests/testthat/test-fix-1707-predict-example.R`: convergence and finite `sigma`
  guard.

## Verification (local)

- `devtools::document()` — updated `man/predict.drmTMB.Rd` only (reverted unrelated
  roxygen 8.1.1 churn in `NAMESPACE`/other `.Rd` files).
- `devtools::test(filter = "fix-1707-predict-example")` — PASS 8, WARN 0.
- `R CMD INSTALL` + `example(predict.drmTMB)` — 0 warnings; `sigma` in `[0.44, 1.17]`.
