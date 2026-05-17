# After Task: Slice 151 random-effect scale newdata output contract

## Goal

Pin the positive multi-row output contract for direct-SD `newdata` prediction.

## Implemented

`predict(fit, dpar = "sd(id)", newdata = grid)` now has explicit regression
coverage for multi-row output. For a Gaussian direct-SD model with `sd(id) ~ w`,
the test checks that a two-row grid returns one value per row, preserves
`rownames(newdata)`, uses response scale by default, and agrees with
`exp(type = "link")`.

NEWS, the Phase 17 roadmap, and
`docs/design/18-random-effect-scale-models.md` now describe the same output
contract.

## Mathematical Contract

This slice does not change the direct-SD model:

```text
log(sd_id,g) = W_g alpha,
sd_id,g = exp(W_g alpha).
```

It records the prediction-scale contract: `type = "link"` returns `W(newdata)
alpha`, while `type = "response"` and the default return `exp(W(newdata)
alpha)`. Output names are the row names of the supplied grid.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/design/18-random-effect-scale-models.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-17-slice-151-random-scale-newdata-output.md`
- `tests/testthat/test-gaussian-random-effect-scale.R`

## Checks Run

- No-edit scout before the slice: a two-row `sd(id)` prediction grid preserved
  names `low_w` and `high_w`, and response predictions matched `exp(link)` with
  zero difference.
- `air format NEWS.md ROADMAP.md docs/design/18-random-effect-scale-models.md tests/testthat/test-gaussian-random-effect-scale.R`:
  passed.
- `Rscript -e "devtools::test(filter = 'gaussian-random-effect-scale', reporter = 'summary')"`:
  passed.
- `Rscript -e "devtools::test(filter = 'fixed-effect-basis|gaussian-random-effect-scale', reporter = 'summary')"`:
  passed.
- `git diff --check`: passed.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed.
- Positive source/rendered scan for Slice 151 direct-SD output wording found the
  expected entries in source files, tests, and rendered pkgdown NEWS/ROADMAP
  pages.
- Stale-claim scan for accidental random-effect scale `emmeans`, bivariate
  random-effect scale prediction, `sd_sigma*()` syntax, transformed-response
  support, or new bivariate multi-row claims found no new false support claims;
  matches were existing profile-interval, Family B, or `sd_sigma1()` /
  `sd_sigma2()` guardrails.
- Recovery checkpoint:
  `docs/dev-log/recovery-checkpoints/2026-05-17-023354-codex-checkpoint.md`.

## Tests Of The Tests

The test covers a positive two-row `newdata` grid with explicit row names. It
checks names, output length, default scale, response positivity, and exact
response/link parity through `response = exp(link)`.

## Consistency Audit

The behavior was already present in `predict_random_scale_dpar()`: row names are
taken from `rownames(newdata)`, link predictions are the linear predictor, and
response predictions are exponentiated. This slice makes that behavior visible
in tests and public/design notes without changing formula grammar, likelihood
parameterization, fitted coefficients, or object structure.

## What Did Not Go Smoothly

Nothing material. The no-edit scout matched the intended contract before edits,
so the work stayed in the evidence-and-documentation lane.

## Team Learning

Pat should keep direct-SD prediction examples interpretable by preserving grid
row names. Curie should pair malformed-input guards with at least one positive
multi-row output test. Rose should keep checking that direct-SD output wording
does not drift into unsupported bivariate surfaces, empirical marginalisation,
or random-effect scale `emmeans`.

## Known Limitations

- This slice pins the direct-SD `newdata` output contract for ordinary
  univariate random-effect scale predictions.
- It does not add random-effect scale `emmeans`, bivariate random-effect scale
  prediction surfaces, empirical marginalisation, `sd_sigma*()` syntax,
  transformed-response support, or new random-effect scale model families.

## Next Actions

Continue the direct-SD prediction audit toward non-data-frame and empty-grid
boundaries, keeping each unsupported or malformed path separate from positive
output contracts.
