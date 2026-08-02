# Lane C Z6a — zero-one-beta zoi slope

## 1. Goal

Validate only `mc-0577`: ML `zero_one_beta()` with `zoi ~ x + (0 + x | id)`.

## 2. Implemented

One exact ordinary zoi slope is admitted, with fixed and random predictors
required to be the same raw symbol.

## 3a. Decisions and Rejected Alternatives

Mismatched/transformed slopes, labels, covariance, other random dpars,
structured terms, profiles, intervals, and coverage remain excluded.

## 4. Files Touched

`R/drmTMB.R`, `tests/testthat/test-zero-one-beta.R`, and the retained Z6a
runner/receipt carry this work.

## 5. Checks Run

Focused zero-one-beta tests pass. The four-seed source-bound local fixture
passes, with separate zero, one, and interior support recorded per group.

## 6. Tests of the Tests

The independent full-mixture-plus-normal-prior oracle agrees with the TMB
objective and AD gradient; nonzero-SD dependency and endpoint no-refit fences
are tested.

## 7a. Issue Ledger

`mc-0577` is unchanged pending fresh review.

## 8. Consistency Audit

No Future-extension, Lane A/B, interval, profile, or ledger change occurred.

## 9. What Did Not Go Smoothly

The first receipt combined atom support by group. The repaired runner records
zero and one support separately and reruns every seed.

## 10. Known Residuals

The zero-true-SD result is diagnostic only; no broader atom-effect claim exists.

## 11. Team Learning

An atom-mixture fixture must preserve zero and one support separately.

## 12. Cross-Product Coverage

This covers only complete univariate ML model type 15 with fixed sigma/coi and
one matching ordinary zoi slope. It does NOT cover REML, missingness,
aggregation, covariance, labels, other dpars, structured providers, profiles,
intervals, bootstrap, coverage, association, or bivariate/high-q routes.
