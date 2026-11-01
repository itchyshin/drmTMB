# After-task: zero-inflated Poisson independent slope without sd()

Date: 2026-11-01. Lane: codex/general-sd-regression (PR 1663).

## Inconsistency

`bf(y ~ x + (0 + x | id), zi ~ 1)` with `family = poisson()` is refused by
`drm_build_poisson_spec`, because `allow_zero_inflated_independent_slope`
requires `length(sd_mu_entries) > 0L`. The same model with
`sd(id, coef = "x") ~ 1` builds, and zero-inflated NB2 admits the plain form.

## What was done

- Added `tests/testthat/test-zi-poisson-plain-slope.R`. Test 1 fits the
  constant-SD formula (builds today) and compares its logLik with a dense
  per-cluster quadrature oracle. Test 2 fits the plain form, skips with
  "awaiting guard patch batch6-zip-plain-slope" while the build is refused, and
  otherwise checks logLik equality with the constant-SD fit, equal fixed
  effects and SD, and the same oracle.
- Tolerances fixed before the first run: per-group logLik gap to the oracle
  below 0.1; plain versus constant-SD logLik relative 1e-5, coefficients 1e-3,
  SD 1e-4; doubling the oracle SD must move it by more than 1.
- `R/drmTMB.R` was not edited. The guard change is in
  `batch6-zip-plain-slope.patch` (scratchpad): drop `&& length(sd_mu_entries) > 0L`
  so the ZIP line matches NB2.
- Two existing tests pin the old refusal (`test-zi-poisson.R`,
  `test-zi-poisson-sd-regression.R`). `batch6-zip-plain-slope-tests.patch`
  replaces them with a still-refused route of the same kind, the correlated
  `(1 + x | id)` block with `zi`. No assertion was deleted or loosened.

## Results

Before the guard patch: 4 expectations pass, 1 test skipped. With the patched
`drm_build_poisson_spec` injected by `assignInNamespace`: 12 expectations pass,
no skips, plain and constant-SD logLik agree. The two patched refusal test
files pass under the injection (58 and 25 expectations).

## Not covered

One synthetic dataset (40 groups of 12). No calibration, recovery or coverage
claim, no parity with another engine, no missing-data route (the patch keeps
`!include_missing_response`), no simulate, predict, profile or bootstrap checks
for the plain form. Docs and vignettes that describe the ZIP slope as requiring
sd() were not searched or changed. The patches are not applied.

## Update after landing (2026-11-01)

Both patches are now applied in this branch: the guard in `drm_build_poisson_spec`
no longer requires an `sd()` formula, and the two old refusal tests now pin the
correlated `(1 + x | id)` block with `zi`, which stays refused. The temporary
skip in `test-zi-poisson-plain-slope.R` was replaced by a direct fit, so a
regression in the plain route now fails instead of skipping. Result: 12
expectations, 0 failures, 0 skips.
