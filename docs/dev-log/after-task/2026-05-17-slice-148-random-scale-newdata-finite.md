# After Task: Slice 148 random-effect scale transformed newdata guard

## Goal

Reject random-effect scale prediction `newdata` rows that evaluate to
non-finite design-matrix values after transformed predictor terms are
processed.

## Implemented

`predict_random_scale_dpar()` now calls the shared finite design-matrix
validator after evaluating the right-hand side of direct random-effect scale
formulas such as `sd(id) ~ log(w_pos)`.

`predict(fit, dpar = "sd(id)", newdata = ...)` now rejects invalid transformed
prediction rows with the affected model column named. A request with
`w_pos = 0` for a fitted `sd(id) ~ log(w_pos)` model now errors on
`log(w_pos)` instead of returning an infinite link- or response-scale fitted
random-effect SD.

## Mathematical Contract

This slice does not change the direct-SD model. It tightens prediction input
validation for

```text
log(sd_id,g) = W_g alpha,
sd_id,g = exp(W_g alpha).
```

When users supply `newdata`, every evaluated entry of `W(newdata)` must be
finite before `W alpha` is computed. The fitted coefficients, likelihood,
group-level constant-predictor rule, and formula grammar are unchanged.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `R/methods.R`
- `docs/design/18-random-effect-scale-models.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-17-slice-148-random-scale-newdata-finite.md`
- `tests/testthat/test-gaussian-random-effect-scale.R`

## Checks Run

- No-edit scout before the fix:
  `predict()` on a Gaussian `sd(id) ~ log(w_pos)` fit with `w_pos = 0` returned
  `Inf` on the link scale.
- `Rscript -e "devtools::test(filter = 'gaussian-random-effect-scale', reporter = 'summary')"`:
  passed.
- Post-fix scout of the same `predict()` call: errored with
  `non-finite design-matrix value` and named `log(w_pos)`.
- `air format NEWS.md ROADMAP.md R/methods.R docs/design/18-random-effect-scale-models.md tests/testthat/test-gaussian-random-effect-scale.R`:
  passed.
- `Rscript -e "devtools::test(filter = 'fixed-effect-basis|gaussian-random-effect-scale', reporter = 'summary')"`:
  passed.
- `git diff --check`: passed.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed.
- Positive source/rendered scan for Slice 148 random-effect scale
  transformed-newdata wording: found the expected entries in source files,
  tests, and rendered pkgdown NEWS/ROADMAP pages.
- Stale-claim scan for accidental random-effect scale `emmeans`, bivariate
  random-effect scale implementation, `sd_sigma*()` syntax, residual-`sigma`
  target drift, or transformed-response support: no new false support claims;
  matches were existing direct-SD boundary text or unrelated implemented
  residual-scale random-effect internals.
- Recovery checkpoint:
  `docs/dev-log/recovery-checkpoints/2026-05-17-014325-codex-checkpoint.md`.

## Tests Of The Tests

The new regression test uses a fitted Gaussian direct-SD model with
`sd(id) ~ log(w_pos)` and predicts `dpar = "sd(id)"` from `newdata` containing
`w_pos = 0`. Before the fix, the scout returned `Inf` on the link scale. After
the fix, the public prediction path rejects the request and names
`log(w_pos)`.

## Consistency Audit

The implementation changes prediction validation after formula evaluation only.
It does not alter random-effect scale parsing, group-level predictor checks,
likelihood parameterization, fitted coefficients, `coef()`, `sdpars`,
`summary()`, `profile_targets()`, or `check_drm()`.

NEWS, the Phase 17 roadmap, and
`docs/design/18-random-effect-scale-models.md` now describe the same rule:
direct random-effect scale prediction `newdata` must produce finite transformed
predictor columns.

## What Did Not Go Smoothly

The shared helper's advice originally mentioned `emmeans`, which fit the
fixed-effect `mu` path but was noisy for `sd(id)` predictions. The message was
generalized to prediction and post-fit grid helpers before closing the slice.

## Team Learning

Pat should keep transformed-predictor errors tied to the model column a user can
repair. Curie should keep pairing each new prediction validation guard with a
scout that demonstrates the previous non-finite output. Rose should keep
checking that direct-SD wording does not drift into residual `sigma` or
unsupported bivariate direct-SD claims.

## Known Limitations

- The guard applies to random-effect scale prediction design matrices when
  `newdata` is supplied.
- It does not add random-effect scale `emmeans`, bivariate random-effect scale
  prediction surfaces, `sd_sigma*()` syntax, transformed-response support,
  empirical marginalisation, or new random-effect scale model families.

## Next Actions

Continue auditing direct-SD prediction for adjacent `newdata` failures, such as
missing required variables or factor-level mismatches, while keeping each fix
separate from this finite transformed-predictor guard.
