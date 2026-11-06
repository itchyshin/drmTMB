# After Phase: Poisson independent-slope SD

Status: verified native implementation checkpoint. The programme remains active.

## 1. Goal

Make `sd(id, coef = "x") ~ w` work for one ordinary Poisson independent numeric
slope, with coefficient identity preserved through fitting and public outputs.

## 2. Implemented

The model has log mean `X beta + x tau_g u_g`, with standard-normal `u_g` and
`log(tau_g) = W_g alpha`. The returned SD is per unit of `x`; the contribution
variance is `x^2 tau_g^2`. The common scalar target resolver retains the binomial
intercept restriction while the Poisson adapter opts into this slope-only shape.
No C++ likelihood change was needed.

## 3a. Decisions and Rejected Alternatives

Require a unique independent slope-only term when a Poisson SD formula targets
a slope. Keep mixed/crossed slopes, correlated blocks, labelled slopes, structured
partners and missing-data combinations as later required work. Keep within-group
`x` variation separate from group-constant SD predictors.

## 4. Files Touched

Changes cover the shared scalar target module, Poisson R admission, focused source
and integration tests, independent numerical helpers, the native test runner and
bounded Totoro wrapper. Grammar, likelihoods, NEWS and status notes describe the
same scope. Exact evidence is in `general-sd-regression/evidence/poisson-slope-20261017/`.

## 5. Checks Run

Source checks passed 18 slope assertions, 39 Poisson intercept assertions, 24
binomial selector assertions and 56 target-descriptor assertions. The independent
scalar slope reference passed 24 expectations. Its Laplace and adaptive integrals
agree with model invariances and the intercept reduction.

Fresh Totoro capsule
`6adcfc2451dc79367c60d3383fea673617480b5a88c6147ae0dc90d2a1376794`
built the engine. After correcting one test assertion, the targeted suite passed
235 expectations, including 24 pure-reference checks. The new fitted checks cover
likelihood agreement, a wrong-slope-design control, one fixed-seed truth check,
constant-SD reduction, profile bounds, prediction, storage, simulation and bootstrap
refits. Existing binomial and Gaussian regressions passed. Two test files changed
after the capsule was frozen; R/C++ runtime hashes remained identical, and the
corrected test ran from a separate file against the same installed library.

## 6. Tests of the Tests

The initial source test failed at the intended slope-admission gate. The independent
reference detects wrong group and random-slope designs. Its zero-design and inverse
scaling controls test whether the coefficient is multiplied by `x` correctly.

## 7a. Issue Ledger

No issue, pull request, email, push, merge or release action occurred.

## 8. Consistency Audit

The contract pairs the equation, independent DGP, formula and extractor. Public
wording distinguishes the slope SD from its observation-level contribution. A second
documentation pass corrected another stale blanket Beta deferral while preserving
the existing `mc-0017` exception and its limited coverage evidence.

## 9. What Did Not Go Smoothly

The profile test initially called `is.finite()` on the returned table. Checking its
numeric `lower` and `upper` columns fixed the assertion; the engine was unchanged.
The original failure remains in the evidence. An older Poisson test still expected
all slope SDs to be rejected; it now tests the unsupported correlated block instead.

## 10. Known Residuals

One successful synthetic truth check does not establish repeated-sampling recovery
or calibrated intervals. The first Bernoulli production study remains separate.
Julia public integration still awaits shared-file ownership. All programme gates
G0 through G8 remain open.

## 11. Team Learning

Changing a coefficient's SD does not require changing its random-regression design.
Test those two maps independently. Match a public method's result structure before
writing assertions about its numerical contents.

## Design-Document Updates

The formula grammar, Poisson likelihood section and slope contract describe the
independent slope-only form and the remaining combined-layout boundaries.

## Pkgdown and Documentation Updates

The preceding synthetic guide remains an intercept example. It does not claim to
demonstrate this slope model or validate interval coverage.

## 12. Cross-Product Coverage

This checkpoint does NOT cover mixed/crossed slope SDs, correlated blocks, structured
providers, other-family slope admission, Julia fitting, calibrated uncertainty or
full package/platform readiness.
