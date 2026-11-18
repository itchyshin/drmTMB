# 2026-11-18 — fix #1733 predict se.fit message

## Scope

`predict.drmTMB()` still rejects `se.fit`. When that argument is supplied, the
abort now names `se.fit` and says standard errors are not computed. Any other
unknown argument still aborts with "`...` is reserved for future options."

## Evidence

`tests/testthat/test-fix-1733-predict-se-fit.R` on this branch before the
message change: the `se.fit = TRUE` test failed because the message was
"`...` is reserved for future options." After the change the file passes.

No exported default, estimand, or convergence rule changed.
