# 2026-11-10 model.frame() row count and nobs()

Sibling PR #1712 (issue #1699) changes `nobs()` so it counts only rows with
weight greater than 0. The location model frame still keeps a zero-weight
row. `nrow(model.frame(fit))` therefore exceeds `nobs(fit)` when any weight
is zero.

The roxygen for `model.frame.drmTMB` in `R/methods.R`, the regenerated
`man/model.frame.drmTMB.Rd`, and the Mathematical Contract in
`docs/dev-log/after-task/2026-11-10-model-frame-1700.md` now say the two
counts match under the default complete-case policy for an unweighted fit,
or a fit whose weights are all positive. A zero-weight row stays in the
frame and is not counted by `nobs()`. Retained missing responses can still
make the frame longer than `nobs()` as well.

`devtools::document()` (devtools 2.5.2, roxygen2 8.0.0) regenerated the Rd.
The same run rewrote `man/drmTMB.Rd`, `man/predict.drmTMB.Rd`,
`man/predict_parameters.Rd`, and `man/simulate.drmTMB.Rd`; those unrelated
rewrites were reverted. No function body, test, or NAMESPACE entry changed.
`tests/testthat/test-fix-1700-model-frame.R` stays as written: its fits are
unweighted, so `nrow(model.frame(fit)) == nobs(fit)` remains the right
expectation there.
