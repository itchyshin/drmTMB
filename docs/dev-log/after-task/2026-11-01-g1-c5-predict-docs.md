# After-task report: G1 condition C5, predict() documentation and extractor audit

Date: 2026-11-01. Lane: general-sd-regression. Reviewer condition: C5 in
`docs/dev-log/general-sd-regression/g1-joint-contract-review-20261101.md`.

## What changed

- `R/methods.R` (roxygen `@details` of `predict.drmTMB`, lines 2993-3006) now
  states that SD parameters return the multiplier on the supplied kernel and
  never `tau * sqrt(C_gg)`, that `type = "link"` is the soft-clamped log SD
  (identity inside [-12, 12], saturating towards [-15, 15]), and that `newdata`
  rows are group-level rows, with no kernel node for a structured SD.
- `man/predict.drmTMB.Rd` was edited by hand with the same paragraph. The
  installed roxygen2 is 8.0.0 and DESCRIPTION carries no `RoxygenNote`, so a
  regeneration would rewrite many unrelated Rd files. The Rd uses the markdown
  conversions roxygen produces (`\code{}`, `\verb{[-12, 12]}`).
- `docs/design/18-random-effect-scale-models.md`: new section recording what
  `predict()`, `predict_parameters()`, `VarCorr()`, `fit$sdpars` and the
  `corpairs()` SD summary return for a predictor-dependent SD, with citations,
  plus the requirements for any later marginal-SD name.
- `tests/testthat/test-sd-predict-semantics.R` (new): one ordinary Gaussian
  `sd(id) ~ z` route and one structured Gaussian `relmat` route with a
  non-unit-diagonal, shuffled kernel.

## Audit findings

1. `predict_parameters()` returns the same per-group multiplier as `predict()`.
2. `VarCorr()` does not exist in drmTMB, so it neither returns nor refuses
   anything; it is absent.
3. The only group-average is the median in the bivariate phylo `corpairs()` SD
   columns.
4. Labelling gap, not fixed: `predict_parameters()` without `newdata` labels
   rows by group level only for the `mu` and `phylo` SD registries
   (`R/predict-parameters.R:684`); `sigma` and `phylo2` SD keys get `"1"..n`.

## Not done, and why

- The stale line citations in the code comment above the soft clamp in
  `predict_random_scale_dpar()` are left for C4, which owns that comment.
- No marginal-SD accessor was added. The audit is the precondition.

## Verification

Mac, one R process at a time, `NOT_CRAN=true`, `pkgload::load_all()`:

- `tests/testthat/test-sd-predict-semantics.R`: 21 passed, 0 failed, 0 errors, 0 skipped.
- Neighbours: `test-structured-sd-nonunit-k-and-missing.R` 53 passed;
  `test-binomial-animal-iid-sd-regression.R` 65 passed;
  `test-beta-sd-integration.R` 13 passed; none failed, errored or skipped.
- `tools::checkRd("man/predict.drmTMB.Rd")` printed no problems.

Tolerances were fixed before the first run (1e-10 for exact identities, strict
inequalities for the clamp checks). The test makes no recovery, calibration or
Julia claim.
