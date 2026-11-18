# After-task: Poisson ordinary SD regression with missing responses

Date: 2026-11-01. Lane: codex/general-sd-regression.

## Gap

`bf(y ~ x + (1 | id), sd(id) ~ w)` with some `y` NA and
`miss_control(response = "include")` was refused with "requires complete
data". The refusal was a guard in `drm_build_poisson_spec`, not a likelihood
limit. The Poisson C++ branch (`model_type == 6`) already skips the density of
any row with `observed_y == 0`, and the R builder already keeps NA-response
rows, sets a placeholder count of 0 that never enters the likelihood, and
starts from the observed rows only. The same masking is used for Poisson
random effects without an SD formula.

## What changed

- `R/drmTMB.R`: the ordinary-SD gate no longer refuses `include_missing_response`
  on its own. It still refuses a missing-predictor `mi()` route, a structured
  term other than the admitted relmat, animal or phylo intercept, and, new and
  explicit, `include` combined with `zi`. Zero-inflated Poisson with SD and
  include was never validated, and removing the old guard would have admitted
  it silently, so that combination is fenced. The error text was updated.
- New `tests/testthat/test-poisson-sd-missing-include.R` with a dense Laplace
  oracle written in the test file and independent of drmTMB. It covers a
  random intercept, a slope-only term, and the same-group independent intercept
  and slope with separate coefficient SDs. Group levels are shuffled and
  the SD covariates are shuffled across groups. For each route it checks:
  include logLik equals the complete-case logLik on the observed rows to 1e-8;
  oracle logLik at the fitted coefficients to 1e-6; constant-SD equivalence
  (intercept and slope); emulated-bug sensitivity (NA scored as an observed
  zero, swapped or sign-flipped SD covariate, each moves the oracle by more
  than 0.05); predictions for NA rows and for every group SD. A fifth test
  covers a group whose responses are all NA, and refusal checks for
  zero-inflated include, correlated blocks with include, and relmat plus an
  ordinary random effect with include.
- Tolerances were fixed before the first run and none was loosened.

## Existing tests edited (stale refusal pins)

- `tests/testthat/test-poisson-sd-assembly.R`: the include plus ordinary SD
  pin, expecting "complete data", now uses the still-refused zero-inflated
  include route (`zi ~ 1`) and expects "complete predictors".
- `tests/testthat/test-poisson-slope-sd-assembly.R`: the include plus slope SD
  pin now uses the still-refused correlated `(1 + x | id)` block with include
  and expects "missing-response integration".
- No assertion was deleted. Neither file is listed in the `test_path` column of
  `direct-sd-evidence.tsv`. `candidate-source-manifest-20261023.json` mentions
  assembly files, so the coordinator should check whether a hash there needs a
  refresh.

## Results (Totoro, cores 4-7, NOT_CRAN=true)

- `test-poisson-sd-missing-include.R`: 37 passed, 0 failed, 0 errors, 0 skipped.
- `test-poisson-sd-assembly.R`: 45 passed. `test-poisson-slope-sd-assembly.R`:
  22 passed.
- `test-poisson-sd-integration.R` 43, `test-poisson-slope-sd-integration.R` 23,
  `test-poisson-iid-structured-sd-regression.R` 170,
  `test-zi-poisson-sd-regression.R` 25: all pass, no failures.

## Not covered

Synthetic data only, 40 groups of 8 rows with about 20 percent NA. No recovery
or coverage campaign, no Julia engine route, no structured (relmat, animal,
phylo, spatial) plus include, no zero-inflated include, no `mi()` plus include.
Missing responses here are treated as ignorable (missing at random given the
predictors); informative missingness is not modelled. Documentation text for
the `missing` argument says include is implemented only for Gaussian masks,
which is already out of date for Poisson random-effect models and was not
changed here. No receipt rows were added for the new test file.
