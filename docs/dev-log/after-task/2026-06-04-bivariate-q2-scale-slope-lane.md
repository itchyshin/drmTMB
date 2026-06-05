# After Task: Bivariate Gaussian q2 Scale-Slope Lane

## Goal

Implement the first bivariate Gaussian residual-scale random-slope covariance
slice: matching labelled slope-only terms in `sigma1` and `sigma2`, with smoke
and recovery routing for Phase 18. The route should fit this q=2 scale-slope
block without opening same-response location-scale slope covariance, all-four
p8/q8 endpoint covariance, or random effects in residual `rho12`.

## Implemented

The fitted syntax is:

```r
bf(
  mu1 = y1 ~ x,
  mu2 = y2 ~ x,
  sigma1 = ~ x + (0 + x | p | id),
  sigma2 = ~ x + (0 + x | p | id),
  rho12 = ~ 1
)
```

The parser and bivariate covariance builder now admit the matching
`sigma1`/`sigma2` slope-only pair when the label, group, and slope term match.
The fitted object reports two scale-slope SDs in `sdpars$sigma` and one
group-level scale-scale correlation in `corpars$sigma` and
`corpairs(class = "scale-scale")`. `summary()`, `profile_targets()`, and
`check_drm()` expose the same row. Residual `rho12` stays a separate row-level
correlation.

Phase 18 now has `biv_gaussian_q2_scale_slope` and
`biv_gaussian_q2_scale_slope_recovery` tasks, plus an opt-in Actions entry and
CSV grid writers.

## Mathematical Contract

For group `j` and observation `i`, the fitted scale predictors are

```text
log(sigma1_ij) = eta_sigma1_ij + x_ij a_1j
log(sigma2_ij) = eta_sigma2_ij + x_ij a_2j
[a_1j, a_2j]^T ~ Normal(0, Sigma_p)
```

where `Sigma_p` has two scale-slope SDs and one latent group-level
scale-scale correlation. This is not residual `rho12`; `rho12` remains the
within-observation bivariate Gaussian residual correlation.

## Files Changed

- `R/drmTMB.R` and `R/methods.R`
- `tests/testthat/test-biv-gaussian.R`
- `inst/sim/dgp/sim_dgp_biv_gaussian_q2_scale_slope.R`
- `inst/sim/fit/sim_summarise_biv_gaussian_q2_scale_slope.R`
- `inst/sim/run/sim_run_biv_gaussian_q2_scale_slope_smoke.R`
- `inst/sim/run/sim_summary_biv_gaussian_q2_scale_slope_smoke.R`
- `inst/sim/run/sim_summary_biv_gaussian_q2_scale_slope_recovery.R`
- `inst/sim/run/sim_write_biv_gaussian_q2_scale_slope_grid.R`
- `inst/sim/run/sim_write_biv_gaussian_q2_scale_slope_recovery_grid.R`
- `tests/testthat/test-phase18-biv-gaussian-q2-scale-slope.R`
- `tests/testthat/test-phase18-biv-gaussian-q2-scale-slope-recovery.R`
- Phase 18 registry, Actions runner, and workflow files
- README, NEWS, ROADMAP, known limitations, design docs, simulation README, and
  edited vignettes that state the support boundary

## Checks Run

- `air format` on touched R, simulation, runner, and test files completed.
- Focused Phase 18/registry tests: 616 passes, no failures, warnings, or skips.
- Focused bivariate Gaussian tests: 1,272 passes, no failures, warnings, or
  skips.
- Full `devtools::test()`: 9,827 passes, no failures, warnings, or skips in
  722.3s.
- `devtools::document()` completed with no extra generated-file drift.
- `pkgdown::check_pkgdown()` returned no problems found.
- `pkgdown::build_site()` completed; the only warning was the local
  `glmmTMB`/TMB version mismatch.
- `devtools::check(error_on = "never")`: 0 errors, 0 warnings, 0 notes in
  8m 29s.
- `git diff --check` passed.
- Targeted stale-source and rendered-site scans found no current wording that
  still treats the q2 `sigma1`/`sigma2` scale-slope route as planned.

## Tests Of The Tests

The new tests check a fitted route and failure boundaries. The initial full
suite found two stale expectations: one unsupported bivariate scale-slope
message and one Phase 18 correlation-block row count. Updating those tests made
the suite assert the new fitted q2 route and the unchanged unsupported
neighbours.

The recovery test reuses the Phase 18 interval-evidence pattern: fixed-effect
Wald coverage is reported where standard errors exist, while random-effect SDs
and the derived scale-scale correlation keep explicit unavailable interval
status.

## Consistency Audit

The status language was synchronized across README, ROADMAP, NEWS, known
limitations, formula grammar, cross-dpar gates, endpoint maps, readiness
matrices, and rendered pkgdown pages. The main stale pattern was broad wording
such as "residual-scale bivariate slope covariance remains planned"; current
docs now reserve that language for same-response, p8/q8, structured, or
broader endpoint routes beyond the fitted q2 scale-slope slice.

## GitHub Issue Maintenance

Issue #483 was inspected before closure work. The final implementation and
verification comment was posted at
<https://github.com/itchyshin/drmTMB/issues/483#issuecomment-4627127721>. The
issue remains open until review decides whether to close it from this branch or
from a PR.

## What Did Not Go Smoothly

The first full suite pass exposed stale tests rather than implementation
failures. The final prose audit also found several current inventory documents
that used overly broad residual-scale slope wording. Those were useful catches:
without them, the package would fit the route while some docs still told users
it was planned.

## Team Learning

For bivariate covariance work, source tests are not enough. Rose's stale-scan
step needs both narrow negative patterns and positive rendered-page handles so
the fitted/planned boundary is visible in the site, not just in source docs.

## Known Limitations

This is a q=2 ordinary group-level scale-slope slice. It does not fit
same-response `mu`/`sigma` slope covariance, all-four p8/q8 endpoint slope
covariance, predictor-dependent slope `corpair()` regressions, structured
residual-scale slopes, random effects in `rho12`, or mixed-response bivariate
families. Random-effect SDs and scale-scale correlations still need profile,
derived-profile, or bootstrap interval methods before interval coverage can be
claimed for those rows.

## Next Actions

- Open or update a PR with the q2 scale-slope branch.
- Decide whether issue #483 closes from that PR or after a separate review
  comment.
- Keep the next endpoint work focused on same-response location-scale slope
  covariance or p8/q8 only after a separate design gate and recovery plan.
