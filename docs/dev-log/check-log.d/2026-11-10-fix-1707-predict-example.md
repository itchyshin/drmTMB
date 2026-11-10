# Check log — 2026-11-10 — fix #1707 predict.drmTMB Rd example

## Goal

Replace the pathological six-row `sigma ~ x` example in `?predict.drmTMB` with a
simulated Gaussian location-scale fit that converges without warnings.

## Changes

- `R/methods.R`: well-posed `predict.drmTMB` and `sigma.drmTMB` examples
  (`set.seed(20261110)`, `n = 120`, heteroscedastic DGP).
- `man/predict.drmTMB.Rd`: example swap only; reverted unrelated `\code`/`\verb`
  Details churn from roxygen 8.1.1.
- `tests/testthat/test-fix-1707-predict-example.R`: extract and run examples via
  `tools::Rd2ex()` (no duplicated DGP).

## Rd2ex regression matrix (local, `Rscript /tmp/rd1707-negative-control.R`)

| Rd source | `is_converged` | `sigma` max/min |
| --- | --- | --- |
| `origin/main` `predict.drmTMB.Rd` | FALSE | 2.668e+09 |
| branch `predict.drmTMB.Rd` | TRUE | 2.665 |
| `origin/main` `sigma.drmTMB.Rd` | TRUE (4-row) | 1 |
| branch `sigma.drmTMB.Rd` | TRUE | 2.665 |

Branch guard: `devtools::test(filter = "fix-1707-predict-example")` — PASS 12, WARN 0.
Main `predict` example fails the guard on `is_converged` and `sigma` ratio; rerunning
`tools::Rd2ex` on `origin/main` also emits the scale-runoff `drmTMB()` warning in
interactive runs.
