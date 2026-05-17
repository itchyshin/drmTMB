# After Task: Slice 152 random-effect scale newdata container boundaries

## Goal

Pin direct-SD `newdata` container boundaries for non-data-frame inputs and
zero-row prediction grids.

## Implemented

`predict(fit, dpar = "sd(id)", newdata = ...)` now has explicit regression
coverage for two container boundaries. Non-data-frame `newdata` inputs error
before model-matrix construction. Zero-row data frames are accepted as empty
prediction grids and return named length-zero numeric vectors on both link and
response scales.

NEWS, the Phase 17 roadmap, and
`docs/design/18-random-effect-scale-models.md` now describe the same boundary
contract.

## Mathematical Contract

This slice does not change the direct-SD model:

```text
log(sd_id,g) = W_g alpha,
sd_id,g = exp(W_g alpha).
```

It records the container contract for building `W(newdata)`: `newdata` must be
a data frame, and a zero-row data frame yields a zero-row design matrix and a
length-zero prediction vector.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/design/18-random-effect-scale-models.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-17-slice-152-random-scale-newdata-boundaries.md`
- `tests/testthat/test-gaussian-random-effect-scale.R`

## Checks Run

- No-edit scout before the slice:
  - `newdata = list(w = 0)` errored with `` `newdata` must be a data frame.``;
  - `newdata = data.frame(w = numeric())` returned `named numeric(0)` on both
    link and response scales.
- `air format NEWS.md ROADMAP.md docs/design/18-random-effect-scale-models.md tests/testthat/test-gaussian-random-effect-scale.R`:
  passed.
- `Rscript -e "devtools::test(filter = 'gaussian-random-effect-scale', reporter = 'summary')"`:
  passed.
- `Rscript -e "devtools::test(filter = 'fixed-effect-basis|gaussian-random-effect-scale', reporter = 'summary')"`:
  passed.
- `git diff --check`: passed.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed.
- Positive source/rendered scan for Slice 152 container-boundary wording found
  the expected entries in source files, tests, and rendered pkgdown NEWS/ROADMAP
  pages.
- Stale-claim scan for accidental random-effect scale `emmeans`, bivariate
  random-effect scale prediction, `sd_sigma*()` syntax, transformed-response
  support, or bivariate empty-grid claims found no new false support claims;
  matches were existing profile-interval, Family B, or `sd_sigma1()` /
  `sd_sigma2()` guardrails.
- Recovery checkpoint:
  `docs/dev-log/recovery-checkpoints/2026-05-17-024851-codex-checkpoint.md`.

## Tests Of The Tests

The test checks one malformed container and one valid empty container. The
malformed branch asserts the data-frame error. The empty-grid branch checks
length, names, numeric payload, and link/response parity so a future change
cannot accidentally create rows or drop the scale contract.

## Consistency Audit

The behavior was already present in `predict_random_scale_dpar()`: non-data
frames error before `model.matrix()`, and zero-row data frames flow through a
zero-row model matrix. This slice makes that boundary visible in tests and
public/design notes without changing formula grammar, likelihood
parameterization, fitted coefficients, or object structure.

## What Did Not Go Smoothly

Nothing material. The scout confirmed both boundaries before edits, so the work
stayed in the evidence-and-documentation lane.

## Team Learning

Pat should keep empty-grid behavior explicit because it is a valid but easy to
misread prediction result. Curie should keep non-data-frame and zero-row tests
beside the positive multi-row tests so container boundaries stay visible. Rose
should keep separating direct-SD empty-grid behavior from bivariate profile
interval empty-grid wording.

## Known Limitations

- This slice pins non-data-frame and zero-row direct-SD `newdata` boundaries for
  ordinary univariate random-effect scale prediction.
- It does not add random-effect scale `emmeans`, bivariate random-effect scale
  prediction surfaces, empirical marginalisation, `sd_sigma*()` syntax,
  transformed-response support, or new random-effect scale model families.

## Next Actions

Continue the direct-SD prediction audit toward multiple random-effect scale
formulas, keeping each target such as `sd(id)` and `sd(site)` explicit.
