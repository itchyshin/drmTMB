# After Task: Slice 150 random-effect scale raw newdata guard

## Goal

Pin the raw-predictor side of random-effect scale `newdata` validation with
explicit tests and public/design wording.

## Implemented

`predict(fit, dpar = "sd(id)", newdata = ...)` now has explicit regression
coverage for malformed raw predictors on the direct-SD right-hand side. For a
Gaussian fit with `sd(id) ~ w`, the tests check that prediction errors occur
before random-effect scale model-matrix construction when `w` is missing, `NA`,
or non-finite.

NEWS, the Phase 17 roadmap, and
`docs/design/18-random-effect-scale-models.md` now state the same rule:
required raw predictors in supplied `newdata` must be present, complete, and
finite when numeric.

## Mathematical Contract

This slice does not change the direct-SD model:

```text
log(sd_id,g) = W_g alpha,
sd_id,g = exp(W_g alpha).
```

It records an input contract for building `W(newdata)`: the raw variables used
by the `sd(id)` formula must be valid before transformed columns, contrasts, or
matrix multiplication are evaluated.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/design/18-random-effect-scale-models.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-17-slice-150-random-scale-raw-newdata.md`
- `tests/testthat/test-gaussian-random-effect-scale.R`

## Checks Run

- No-edit scout after Slice 149 showed that `newdata = data.frame(x = 1)`,
  `newdata = data.frame(w = NA_real_)`, and `newdata = data.frame(w = Inf)`
  already error with predictor-specific messages.
- `air format NEWS.md ROADMAP.md docs/design/18-random-effect-scale-models.md tests/testthat/test-gaussian-random-effect-scale.R`:
  passed.
- `Rscript -e "devtools::test(filter = 'gaussian-random-effect-scale', reporter = 'summary')"`:
  passed.
- `Rscript -e "devtools::test(filter = 'fixed-effect-basis|gaussian-random-effect-scale', reporter = 'summary')"`:
  passed.
- `git diff --check`: passed.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed.
- Positive source/rendered scan for Slice 150 random-effect scale raw-newdata
  wording found the expected entries in source files, tests, and rendered
  pkgdown NEWS/ROADMAP pages.
- Stale-claim scan for accidental random-effect scale `emmeans`, bivariate
  random-effect scale prediction, `sd_sigma*()` syntax, or transformed-response
  support found no new false support claims; matches were existing intentional
  `sd_sigma1()` / `sd_sigma2()` guardrails.
- Recovery checkpoint:
  `docs/dev-log/recovery-checkpoints/2026-05-17-021740-codex-checkpoint.md`.

## Tests Of The Tests

The test covers three malformed `newdata` boundaries for the same fitted
direct-SD model: missing required predictor, missing required value, and
non-finite required numeric value. Each assertion checks that the error is an
error object, that the message names the boundary, and that the message names
the predictor `w`.

## Consistency Audit

The implementation path was already present after Slice 149's shared
model-matrix-newdata helper. This slice makes that behavior visible in tests,
NEWS, the roadmap, and the design note without changing likelihood
parameterization, formula grammar, fitted coefficients, or object structure.

## What Did Not Go Smoothly

The first read-only scout used shell quoting that expanded `sim$data` too early.
The scout was rerun with single-quoted R code before any repository edits, and
the repo stayed clean.

## Team Learning

Pat should keep malformed `newdata` errors tied to a concrete repair: supply the
required predictor with complete finite values. Curie should keep separating
raw-predictor, transformed-predictor, and factor-level validation tests so each
failure path remains readable. Rose should keep checking direct-SD wording
against unsupported `emmeans`, bivariate direct-SD prediction, `sd_sigma*()`,
and transformed-response claims.

## Known Limitations

- This slice pins raw-predictor validation for random-effect scale prediction
  `newdata`.
- It does not add random-effect scale `emmeans`, bivariate random-effect scale
  prediction surfaces, `sd_sigma*()` syntax, transformed-response support,
  empirical marginalisation, or new random-effect scale model families.

## Next Actions

Continue the direct-SD prediction audit toward row naming, multi-row output, and
`type = "response"` parity, but keep those as separate slices.
