# After-task report: NB2 same-group joint mu and sigma SD regression

Date: 2026-11-01. Lane: general-sd-regression.

## What was asked

The NB2 joint mu plus sigma ordinary random-intercept route was admitted for
two different grouping factors. The same-group case, `(1 | id)` in mu and
`sigma ~ 1 + (1 | id)` with `sd(id) ~ w` and `sd(id, dpar = "sigma") ~ z`,
fitted but had no oracle. This slice adds one, or refuses the route if the fit
disagrees.

## What was found

The fit agrees with the oracle, so the route stays admitted and no engine or
gate change was made. The two effects of a group are independent draws, each
scaled by its own SD formula.

## What was added

Only a new test file, tests/testthat/test-nbinom2-mu-sigma-same-group-sd.R.

- Oracle: a dense Laplace marginal over the 2G independent effects (base R,
  analytic gradient, finite-difference Hessian), independent of drmTMB and TMB.
  Levels of id are shuffled and the SD predictors differ per group.
- Tolerances fixed before the first run: logLik 1e-3, oracle gradient at the
  fitted optimum 1e-2, constant-SD coefficients 2e-2, bug gap above 0.1.
- Constant-SD equivalence: an independent cold-start maximisation of the oracle
  matches the fit.
- Bug sensitivity: swapped mu and sigma SD formulas, predictor rows assigned to
  wrong groups, sigma effect dropped, and sigma effect tied to the mu effect
  (one shared draw per group) all move the oracle by more than the gap.
- Refusals with message patterns: either or both SD formulas missing, and a
  group-varying SD predictor.

## Result

22 expectations passed, 0 failed, 0 errors, 0 skipped across the four tests.

## Not covered

No mu-sigma correlation within a group (they are independent by design), no
slopes, no structured fields, no zero inflation, no missing-data integration.
