# After Task: Mu/Sigma Profile-Target Rows

## Goal

Lock down the `profile_targets()` inventory for the implemented univariate
Gaussian `mu`/`sigma` random-intercept covariance slice.

## Implemented

Added a focused regression test for:

```r
drmTMB(
  bf(y ~ x + (1 | p | id), sigma ~ z + (1 | p | id)),
  family = gaussian(),
  data = dat
)
```

The test checks that `profile_targets(fit)` lists:

- `sd:mu:(1 | p | id)` mapped to `log_sd_mu`;
- `sd:sigma:(1 | p | id)` mapped to `log_sd_sigma`;
- `cor:mu_sigma:cor(mu:(Intercept),sigma:(Intercept) | p | id)` mapped to
  `eta_cor_mu_sigma`.

It also checks that all three targets are direct, profile-ready, and absent
from any residual `rho12` namespace.

## Mathematical Contract

This task did not change profiling code. It records the current direct target
mapping for already fitted `sdpars$mu`, `sdpars$sigma`, and
`corpars$mu_sigma` quantities.

## Files Changed

- `tests/testthat/test-profile-targets.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-12-mu-sigma-profile-target-rows.md`

## Checks Run

- `air format tests/testthat/test-profile-targets.R`: passed.
- `Rscript -e "devtools::test(filter = 'profile-targets')"`: passed with 191
  expectations, 0 failures, 0 warnings, and 0 skips.

## Tests Of The Tests

The test verifies exact parameter names, target classes, distributional
parameter namespaces, internal TMB parameter names, target indices,
transformations, target type, profile readiness, and `ready_only` inclusion.
It also asserts that the one-response `mu`/`sigma` covariance model has no
`rho12` targets.

## Consistency Audit

No documentation changed because `profile_targets()` already exposed this
surface. The added test keeps the implemented target inventory aligned with
the likelihood, summary, and `corpairs()` slices.

## What Did Not Go Smoothly

Nothing unusual. The existing target builder already handled `mu_sigma`; this
task only added coverage.

## Team Learning

- Ada kept this as a small test-only follow-up.
- Noether kept `mu_sigma` target names separate from residual `rho12`.
- Curie pinned internal TMB parameter names and target indices before profile
  intervals are broadened.

## Known Limitations

- This test covers target inventory, not actual profile confidence interval
  computation for `corpars$mu_sigma`.
- Larger covariance blocks will need their own profile-target tests when they
  are implemented.

## Next Actions

1. If the next slice profiles `corpars$mu_sigma`, add a small interval test or
   diagnostic grid rather than relying only on target inventory.
2. Keep the bivariate and structured covariance target namespaces separate from
   this univariate `mu_sigma` namespace.
