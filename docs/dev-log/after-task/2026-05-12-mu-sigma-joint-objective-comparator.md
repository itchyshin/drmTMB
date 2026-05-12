# After Task: Mu/Sigma Joint Objective Comparator

## Goal

Add an independent likelihood-style check for the first univariate
`mu`/`sigma` covariance block, so the branch has more than fitted-output and
transform-surface evidence.

## Implemented

Added `gaussian_mu_sigma_joint_nll()` inside
`tests/testthat/test-gaussian-random-intercepts.R`. The helper reconstructs
the joint negative log likelihood in R for a Gaussian model with:

```r
bf(y ~ x + (1 | p | id), sigma ~ z + (1 | site) + (1 | p | id))
```

The new test fits that model, extracts the full fixed-plus-random parameter
state from `fit$obj$env$last.par.best`, and compares:

- TMB's joint objective from `fit$obj$env$f(fit$obj$env$last.par.best)`;
- the hand-coded R objective using fixed effects, independent `u_mu` priors,
  independent `u_sigma` priors, the matched `mu`/`sigma` conditional transform,
  the independent unlabelled `sigma` block, and the Gaussian observation
  density.

## Files Changed

- `tests/testthat/test-gaussian-random-intercepts.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-12-mu-sigma-joint-objective-comparator.md`

## Checks Run

- First attempt with a tiny 5-group fixture did not converge reliably and used
  the wrong full-vector parameter extraction path; revised to a 12-group
  deterministic fixture and split `last.par.best` by TMB parameter names.
- `air format tests/testthat/test-gaussian-random-intercepts.R`: passed.
- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts')"`:
  passed with 212 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts|check-drm|profile-targets|summary|phylo-utils')"`:
  passed with 627 expectations, 0 failures, 0 warnings, and 0 skips.

## Consistency Audit

This is test-only hardening. It does not change formula grammar, likelihood
parameterization, roxygen topics, NEWS, README, roadmap, or pkgdown navigation.

## Tests Of The Tests

The comparator includes both the matched labelled `id` block and an independent
unlabelled `site` block. That means the hand-coded objective must reproduce the
cross-parameter conditional transform for only the matched rows while leaving
the extra `sigma` random effects independent.

## What Did Not Go Smoothly

The first tiny fixture was too small and produced optimizer convergence code 1.
It also tried to use `parList()` on the full fixed-plus-random vector, which is
not the right extraction path for this check. The final test uses a slightly
larger deterministic fixture and splits `last.par.best` by its TMB parameter
names.

## Team Learning

- Fisher got the independent objective check that was missing from the first
  covariance bridge.
- Curie kept the comparator small enough for the regular test file.
- Noether checked the exact equation rather than another reporting surface.

## Known Limitations

- This compares the joint fixed-plus-random objective at the fitted random-mode
  state. It is not a separate dense marginal likelihood integral.
- It covers the first intercept-only `mu`/`sigma` covariance slice, not random
  slopes or multiple labelled covariance blocks.

## Next Actions

1. Run the focused covariance branch validation surface again.
2. If that passes, stop adding adjacent tests and prepare the branch for PR
   review.
