# After Task: staged eta candidate Godambe SE build

## 1. Goal

Build a developer-only stacked-score/Godambe candidate variance for the
fixed-effect Bernoulli × ordinary-NB2 frozen-margin association estimator,
then stop before any resampling, public interface, or inference claim.

## 2. Implemented

`drm_pair_staged_eta_sandwich()` is an unexported helper taking the original
two margin fits and the association object. It constructs analytic marginal
scores, numerical rectangle score/cross-derivative blocks, the lower
block-triangular bread, full empirical score meat, and a link-scale delta
method for fitted eta values.

## 3a. Decisions and Rejected Alternatives

The estimator and its row-average sandwich scaling are frozen in design 243.
Conditional stage-2 curvature, a public `vcov()` method, Wald/profile/CI
claims, bootstrap resampling, coverage, and any direct-`rho12` transfer are
rejected for this task. The finite association-link domain and its
unresolved-boundary rule remain in force.

## 4. Files Touched

- `R/associate-pairs-sandwich.R`
- `tests/testthat/test-associate-pairs-staged-sandwich.R`
- `docs/design/240-arc6-staged-eta-uncertainty-followup.md`
- `docs/design/243-arc6-staged-eta-godambe-se.md`

## 5. Checks Run

Focused staged-sandwich tests passed 32 expectations. The existing Bernoulli ×
NB2 contract tests passed 69 expectations. `git diff --check` passed.

## 6. Tests of the Tests

The tests compare analytic NB2 scores and bread with independent numerical
derivatives and compare the complete rectangle score/Hessian with an
independent `mvtnorm` oracle. They also assert sandwich scaling, all meat
cross-products, lower block-triangular bread, response-order invariance,
derivative-step stability, and every implemented unavailable path.

## 7a. Issue Ledger

No issue was opened or changed. This remains an internal developer lane.

## 8. Consistency Audit

Design 240 now explicitly says the former large bootstrap campaign remains
stopped. Design 243 prohibits public SE/Wald/profile/CI language. The direct
`biv_lognormal()` `rho12` route remains explicitly separate.

## 9. What Did Not Go Smoothly

Initial link-scale finite-difference steps were too small for the adaptive
quadrature kernel, so the half-step guard correctly withheld output. A larger
five-point stencil is now documented and still fails closed on disagreement.

## 10. Known Residuals

This is not a validated SE. No bootstrap comparison, recovery, calibration,
coverage, Totoro/DRAC job, or public `vcov()` / `confint()` method exists.

## 11. Team Learning

Adaptive quadrature makes machine-scale finite differences unreliable. A
checked, larger link-scale stencil is safer than accepting an apparently
precise but unstable derivative; the helper must withhold output when its
half-step check disagrees.

## 12. Cross-Product Coverage

The implementation covers only the stated fixed-effect, ML, complete-pair
Bernoulli × ordinary-NB2 staged estimator and its private developer helper.
It does NOT cover other pair classes, random effects, structured effects,
missingness, weights, offsets, REML, penalty/MAP fits, Julia or another engine,
aggregation, direct `rho12`, public `vcov()`/Wald/profile/CI interfaces,
bootstrap comparison, recovery, calibration, or coverage.

## Next action

Treat this source, fixture, numerical tolerances, and design record as frozen.
Obtain Fisher, Noether, and Rose sign-off, then request separate owner approval
for one small, costed full-refit comparison. The stopped 24 × 200 × 399 campaign
must not resume.
