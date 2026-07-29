# AOI-1 — full fixed-effect Bernoulli × ordinary-NB2 association

## 1. Goal

Implement the AOI-1 point-estimate and prediction surface after the green F4R
closeout: an intercept-bearing fixed-effect association formula and point-only
`newdata` predictions for frozen-margin Bernoulli × ordinary-NB2 pairs.

## 2. Scope

This is an Association-lane change only. It excludes Lane B `sd()` clamps and
interval work, all foreign association branches, recovery/coverage compute,
public uncertainty, random or structured association effects, missingness,
weights, offsets, REML, and new family pairs.

## 3. Delivered behaviour

- The Bernoulli × ordinary-NB2 route accepts fixed-effect model-matrix RHSs
  with multiple numeric predictors, factors, interactions, and explicit
  transformations.
- It stores the training terms (including transform metadata), contrasts,
  factor levels, column order, and a design fingerprint.
- `predict(..., type = "link")` returns `X_A alpha`; `type = "response"`
  returns `0.999999 * tanh(X_A alpha)`. `newdata` defaults to the response
  scale. The historical no-argument `predict()` remains `fitted()` output.

## 4. Fail-closed boundary

Only literal Bernoulli × ordinary-NB2 pairs receive this grammar and newdata
surface. Dot expansion, offsets, random-effect bars, `mi()`, missing/non-finite
values, rank-deficient designs, external formula-environment variables, unseen
levels, and design-column mismatch abort. Nonempty prediction `...` aborts, so
`se.fit`, `interval`, and similar uncertainty requests cannot be ignored.

## 5. Private-sandwich provenance

The private Bernoulli × ordinary-NB2 sandwich provenance check now also verifies
contrasts, factor levels, column names, and the design fingerprint. This is
provenance hardening only: it does not expose `vcov()`, `confint()`, profiles,
or standard errors.

## 6. Tests added or changed

The B×NB tests cover multiple predictors, factors, interactions, `I()`,
`scale()`, orthogonal `poly()`, transformed training/newdata design identity,
unseen levels, non-data variables, malformed formula constructs, rank failure,
and rejected uncertainty arguments. The cross-pair integration test retains the
old newdata error for every non-B×NB class.

## 7. Checks run

- `devtools::document(roclets = c("rd", "namespace"))` completed.
- `devtools::test(filter = "associate-pairs-bernoulli-nb2", stop_on_failure = TRUE)`:
  87 pass, 0 fail, 0 warn, 0 skip.
- `devtools::test(filter = "associate-pairs", stop_on_failure = TRUE)`:
  485 pass, 0 fail, 0 warn, 0 skip.
- `devtools::check(document = FALSE, manual = FALSE, vignettes = FALSE, ...)`
  passed build, installation, documentation, examples, and static code gates.
  Its quiet package-wide test phase was intentionally interrupted after the
  proportional Association gate had passed; this is not a full-check pass claim.

## 8. Review

Fisher and Rose independently found transform-replay and silently ignored
uncertainty-option defects in the first implementation. Both were repaired and
the reviewers cleared the updated point-only boundary. No Lane-B or foreign
association files were changed.

## 9. Claim boundary

AOI-1 supports point estimates and point predictions only for the specified
Bernoulli × ordinary-NB2 frozen-margin route. It makes no recovery, interval,
coverage, covariance, standard-error, capability, or general association
inference claim.

## 10. Residual risks and deferred work

AOI-2 must preregister and run a local smoke plus explicitly approved DRAC
point-recovery ladder before any recovery claim. AOI-3 requires its separate
grounded methods review, frozen multi-column sandwich contract, and full-refit
uncertainty calibration. A failed later calibration leaves AOI-1 intact and
uncertainty unavailable.

## 11. Continuation

Start from the AOI-1 handover. The next action is a planning decision for AOI-2,
not a compute launch. Do not widen this code path to other pair classes.
