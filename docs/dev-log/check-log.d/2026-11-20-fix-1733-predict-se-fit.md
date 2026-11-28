# 2026-11-20 — fix #1733 predict se.fit message

## Scope

`predict.drmTMB()` still rejects `se.fit`. When that argument is supplied, the
abort now names `se.fit` and says standard errors are not computed. Any other
unknown argument still aborts with "`...` is reserved for future options."

## Evidence

`tests/testthat/test-fix-1733-predict-se-fit.R` and
`tests/testthat/test-simulate-predict-unused-args.R` on this branch.

No exported default, estimand, or convergence rule changed.