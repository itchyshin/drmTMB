# After Task: Beta Bernoulli x ordinary-NB2 association gradient

## 1. Goal

Implement and explain the narrowly scoped request to let the frozen-margin
Bernoulli x ordinary-NB2 association vary along one covariate, while retaining
the Arc 6 boundaries and giving readers a clear comparison with `rho12`.

## 2. Implemented

`associate_pairs()` and `biv_associate()` now accept `association = ~ x` only
for literal-Bernoulli x ordinary-NB2 fits, where `x` is one finite numeric
column. The existing `association = ~ 1` behaviour remains unchanged for every
reviewed pair class. The new extractor returns association-link coefficients by
default and frozen-row `eta_i` values with `type = "fitted"`.

## 3. Mathematical Contract

Stage 1 freezes the fitted Bernoulli and NB2 margins. Stage 2 maximizes the
same established rowwise latent-normal rectangle likelihood with
`eta_i = tanh(beta_0 + beta_1 x_i)`. The code applies a `0.999999` numerical
guard internally so exact correlation endpoints never enter the rectangle
calculation; it is not part of the scientific formula. This is not a joint
maximum-likelihood `rho12` model and it has no two-stage uncertainty claim.

## 3a. Decisions and Rejected Alternatives

The feature is restricted to one named numeric covariate for literal-Bernoulli
x ordinary-NB2. Factor, interaction, transformed, multi-predictor, random,
and generic pair-association formulas remain rejected.

## 4. Files Touched

- `R/associate-pairs.R`, generated `NAMESPACE`, and Rd files.
- `tests/testthat/test-associate-pairs-bernoulli-nb2.R`,
  `tests/testthat/test-biv-associate.R`, the ten-scenario matrix, and the
  Gaussian×Bernoulli expected-error snapshot.
- Design 239; formula grammar, limitations, NEWS, and check-log updates.
- The two reader articles, `cross-family.Rmd` and `bivariate-nongaussian.Rmd`.

## 5. Checks Run

- `devtools::document()` passed.
- Focused Bernoulli x NB2, one-call, and ten-scenario tests passed.
- The broader `associate-pairs|biv-associate` test selection passed with
  `NOT_CRAN=true`, after synchronizing one expected error whose old text said
  every association slope was unsupported.
- Selected pkgdown article/reference builds and `pkgdown::check_pkgdown()`
  passed. `git diff --check` passed.
- A full package test/check and a full site build were not used as a completion
  claim in this local, unuploaded beta slice.

## 6. Tests of the Tests

The slope test simulates a known two-coefficient latent-normal Bernoulli x NB2
fixture and recovers the association-link signal within a predeclared tolerant
envelope. It checks fitted `eta_i` extraction, both finite-difference beta
scores, and both diagonal curvature diagnostics. A second test sums an
independent `mvtnorm` oracle across rows with different `eta_i` values and
matches the production likelihood. Formula tests reject a factor, two-term
formula, and a slope applied to a different pair class. The ten-case matrix
evaluates finite objectives at zero and nonzero association for all five
admitted pair classes under ordinary and edge-like data configurations.

## 8. Consistency Audit

Symbolic `eta_i = tanh(a_i)`, the R syntax `association = ~ habitat_score`,
and the rowwise rectangle implementation agree. The article says that the
near-one numerical guard is implementation-only. Searches for association
grammar, frozen-margin terminology, and the numerical constant were recorded
in the check log and updated where current documentation was stale.

## 7a. Issue Ledger

PR #826 contains the beta API and reader-first documentation. Its merge remains
gated on review and green package CI. No issue was opened.

## 9. What Did Not Go Smoothly

The initial multi-start logic treated an invalid extreme two-coefficient start
as disagreement even when the valid starts converged to the same optimum. The
bounded slope route now uses conservative starts near zero and compares valid
starts only, while retaining fail-closed outcomes when fewer than two valid
starts remain.

## 11. Team Learning

For a reader-facing statistical beta, show the scientific transform and state
the numerical guard in prose. Putting a machine-safety constant into the main
equation made the model harder to read without improving its interpretation.

## 10. Known Residuals

This beta supports one named numeric association slope only for literal
Bernoulli x ordinary-NB2, on the frozen analysis rows. It does not support
factors, transformations, multiple predictors, interactions, random effects,
new-data association prediction, inference, profiles, intervals, coverage,
generic discrete-pair regression, Julia, CRAN, or a change to the retained
Arc 6.5 recovery HOLD.

## 12. Cross-Product Coverage

The ten-scenario matrix spans ordinary and edge-like data configurations across
all five admitted pair classes. The new association-gradient test covers only
literal-Bernoulli x ordinary-NB2; it does NOT cover other association slopes,
families, inference, random effects, missingness, REML, or Julia.

## Next Actions

Follow the separately recorded Arc 6 clean-close ultra-plan. Before any wider
public or capability claim, obtain explicit approval for the frozen,
compute-backed Arc 6.5 recovery-repair campaign on Totoro or DRAC and
separately review its all-attempt evidence.
