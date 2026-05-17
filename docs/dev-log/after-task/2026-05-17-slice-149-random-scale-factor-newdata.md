# After Task: Slice 149 random-effect scale factor newdata guard

## Goal

Give random-effect scale prediction the same fitted factor-level validation
style as fixed-effect prediction.

## Implemented

The fixed-effect `newdata` preparation logic is now a shared
model-matrix-newdata helper. `predict_random_scale_dpar()` uses it with the
fitted random-effect scale model frame before constructing the direct-SD
prediction matrix.

For a model with a factor predictor on the direct-SD right-hand side, such as
`sd(id) ~ w`, matching character values in `newdata` are coerced through the
fitted factor levels. Unknown values now error with the offending predictor,
unknown level, and fitted levels named before base R contrast or matrix
conformability errors can appear.

## Mathematical Contract

This slice does not change the direct-SD model. It preserves

```text
log(sd_id,g) = W_g alpha,
sd_id,g = exp(W_g alpha),
```

and tightens how `W(newdata)` is built. Factor columns in `W(newdata)` must use
the fitted factor levels from the scale-model frame, so the prediction design
matrix has the same columns as the fitted coefficient vector.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `R/methods.R`
- `docs/design/18-random-effect-scale-models.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-17-slice-149-random-scale-factor-newdata.md`
- `tests/testthat/test-gaussian-random-effect-scale.R`

## Checks Run

- No-edit scouts before the fix:
  - `newdata = data.frame(w = factor("medium"))` failed with
    `contrasts can be applied only to factors with 2 or more levels`.
  - `newdata = data.frame(w = factor("medium", levels = c("low", "high", "medium")))`
    failed with `non-conformable arguments`.
- `Rscript -e "devtools::test(filter = 'fixed-effect-basis|gaussian-random-effect-scale', reporter = 'summary')"`:
  passed.
- Post-fix scout:
  - matching character value `w = "high"` predicted successfully;
  - unknown value `w = "medium"` errored with `unknown factor level` and listed
    fitted levels `"low"` and `"high"`.
- `air format NEWS.md ROADMAP.md R/methods.R docs/design/18-random-effect-scale-models.md tests/testthat/test-gaussian-random-effect-scale.R`:
  passed.
- `git diff --check`: passed.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed.
- Positive source/rendered scan for Slice 149 random-effect scale factor-level
  wording: found the expected entries in source files, tests, and rendered
  pkgdown NEWS/ROADMAP pages.
- Stale-claim scan for accidental random-effect scale `emmeans`, bivariate
  random-effect scale implementation, `sd_sigma*()` syntax, residual-`sigma`
  target drift, or transformed-response support: no new false support claims;
  matches were existing direct-SD boundary text or unrelated implemented
  residual-scale random-effect internals.
- Recovery checkpoint:
  `docs/dev-log/recovery-checkpoints/2026-05-17-015955-codex-checkpoint.md`.

## Tests Of The Tests

The regression test fits a Gaussian direct-SD model with `sd(id) ~ w`, where
`w` is a fitted factor. It checks both sides of the boundary: a matching
character value, `w = "high"`, must predict like an explicit fitted-level
factor, while `w = "medium"` must error before `model.matrix()` or matrix
multiplication can produce lower-level failures.

## Consistency Audit

The implementation generalizes input preparation for prediction model matrices
without changing the likelihood, formula grammar, fitted coefficients, direct
SD parameterization, or post-fit object structure.

NEWS, the Phase 17 roadmap, and
`docs/design/18-random-effect-scale-models.md` now describe the same rule:
direct random-effect scale prediction `newdata` must use fitted factor levels.

## What Did Not Go Smoothly

The no-edit scouts exposed two different low-level failures for the same user
mistake, depending on how the unknown factor was encoded. The shared validation
helper gives both cases one user-facing error.

## Team Learning

Pat should keep direct-SD prediction errors tied to a concrete repair: use one
of the fitted factor levels. Curie should keep adding paired positive and
negative tests when validation accepts matching character input and rejects
unknown levels. Rose should keep checking direct-SD wording against residual
`sigma`, `sd_sigma*()`, and unsupported `emmeans` claims.

## Known Limitations

- This slice validates fitted factor levels for random-effect scale prediction
  `newdata`.
- It does not add random-effect scale `emmeans`, bivariate random-effect scale
  prediction surfaces, `sd_sigma*()` syntax, transformed-response support,
  empirical marginalisation, or new random-effect scale model families.

## Next Actions

Continue auditing direct-SD prediction for missing required variables and other
malformed `newdata` cases, but keep those separate from factor-level
validation.
