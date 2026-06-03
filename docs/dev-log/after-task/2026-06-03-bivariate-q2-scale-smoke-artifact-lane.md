# After Task: Bivariate q2 Scale Smoke Artifact Lane

## Goal

Add the Phase 18 smoke/artifact lane for the matching bivariate Gaussian
residual-scale random-intercept covariance block:

```r
bf(
  mu1 = y1 ~ x,
  mu2 = y2 ~ x,
  sigma1 = ~ 1 + (1 | p | id),
  sigma2 = ~ 1 + (1 | p | id),
  rho12 = ~1
)
```

This is the fittable scale-covariance prerequisite the q8 endpoint pre-code
gate names ("no status promotion before q2 scale ... evidence"). The lane
should be artifact-routed without claiming formal recovery, coverage, power,
residual-scale random *slopes*, same-response location-scale slope covariance,
random `rho12`, or p8/q8 endpoint covariance.

## Why a Scale-Intercept Lane (Not a Scale-Slope Lane)

The original handover pointed at a "q2 scale slope" lane. Investigation of the
package source and tests showed that bivariate residual-scale random *slopes*
are not implemented: `drmTMB()` rejects any `sigma1`/`sigma2` random-slope term
with "Residual-scale random slopes in bivariate models remain planned"
(`R/drmTMB.R`; boundary tests at `tests/testthat/test-biv-gaussian.R:2837`).
A fitted bivariate scale-slope lane is therefore impossible today; it needs new
TMB likelihood work behind a design gate.

What *is* implemented and unit-tested is the matching residual-scale q=2
random-*intercept* covariance block
(`tests/testthat/test-biv-gaussian.R:1567`). That block is the scale-side
analogue of the q4/q6 location lanes and the nearest fittable evidence for the
scale endpoints of the q8 gate, so this lane targets it. The scale-slope step
stays planned.

## Implemented

The new `biv_gaussian_q2_scale` lane has a seeded DGP, fit summariser, smoke
runner, smoke-summary helper, and repeatable grid writer under `inst/sim/`. The
lane is wired into the manual Phase 18 Actions dispatcher and into the
structured workflow registry as a `correlation_blocks` (scale-scale) row with
its own Actions task and seed `20260625`, excluded from `task = "all"`.

Focused tests cover the seeded DGP, the one-replicate smoke summary, grid
artifact writing, malformed inputs, Actions dry-run/sourcing/dispatch plumbing,
the correlation-block workflow plan dispatch row, and the updated registry and
correlation-block-status counts.

## Mathematical Contract

The latent ordinary group vector is the pair of log-`sigma` intercepts:

```text
(b_sigma1_intercept, b_sigma2_intercept) ~ N(0, D),
D = diag(sd_sigma) %*% R %*% diag(sd_sigma),
R = [[1, rho_scale], [rho_scale, 1]]
```

Per observation, `log sigma1 = log(sigma1) + b_sigma1[id]` and
`log sigma2 = log(sigma2) + b_sigma2[id]`, with residuals correlated through
`rho12`. The two scale SDs are direct `log_sd_sigma` targets exposed through
`sdpars$sigma`; the single scale-scale correlation
`cor(sigma1:(Intercept),sigma2:(Intercept) | p | id)` is the derived
`corpars$sigma` row. Residual `rho12` stays a separate residual coscale row,
not a group-level scale correlation.

## Files Changed

- `inst/sim/dgp/sim_dgp_biv_gaussian_q2_scale.R`
- `inst/sim/fit/sim_summarise_biv_gaussian_q2_scale.R`
- `inst/sim/run/sim_run_biv_gaussian_q2_scale_smoke.R`
- `inst/sim/run/sim_summary_biv_gaussian_q2_scale_smoke.R`
- `inst/sim/run/sim_write_biv_gaussian_q2_scale_grid.R`
- `inst/sim/run/sim_run_actions_cell.R`
- `inst/sim/run/sim_phase18_structured_workflow_registry.R`
- `inst/sim/registry/phase18_structured_workflow_registry.csv`
- `tests/testthat/test-phase18-biv-gaussian-q2-scale.R`
- `tests/testthat/test-phase18-actions-runner.R`
- `tests/testthat/test-phase18-structured-workflow-registry.R`
- `tests/testthat/test-phase18-correlation-block-status.R`
- `.github/workflows/phase18-simulation-grid.yaml`
- `NEWS.md`, `inst/sim/README.md`, `docs/dev-log/known-limitations.md`

## Checks Run

Local R checks could not be run in this container: the session-start hook
reported that the environment network policy blocked the R package
repositories, so `remotes::install_deps()` failed and no package dependencies
(TMB, glmmTMB, testthat, the package itself) are installed. `air`,
`devtools::test()`, and `devtools::check()` were therefore not run locally.

Validation for this lane rests on GitHub Actions R-CMD-check, which installs
dependencies and runs the full test suite on Ubuntu, macOS, and Windows. The
new and edited tests are the gate:

- `tests/testthat/test-phase18-biv-gaussian-q2-scale.R` (DGP seeding, smoke
  summary row counts and classes, grid artifacts, malformed inputs).
- `tests/testthat/test-phase18-actions-runner.R` (dry-run, sourcing, dispatch,
  and workflow-exposure for `biv_gaussian_q2_scale`).
- `tests/testthat/test-phase18-structured-workflow-registry.R` and
  `tests/testthat/test-phase18-correlation-block-status.R` (registry row count
  37 -> 38, `ready_grid` 20 -> 21, correlation-block plan 6 -> 7 with
  `ready_grid` 3 -> 4, and the new scale-q2 dispatch row).

If CI surfaces a non-convergent smoke cell or a miscount, the fix is to retune
`n_id`/`n_each` or the magnitudes and correct the asserted counts; the lane
configuration mirrors the proven-convergent unit-test cell (`n_id = 48`,
`n_each = 8`, `sd_sigma = (0.28, 0.34)`, `rho_scale = 0.45`,
`residual_rho = 0.20`).

`devtools::document()` was not run because no roxygen comments changed.

## Known Limitations

This is a smoke/artifact lane only. It does not establish recovery, coverage,
power, timing, formal Monte Carlo operating characteristics, or direct
intervals for the derived scale-scale correlation. Bivariate residual-scale
random *slopes*, same-response location-scale slope covariance, random `rho12`,
and all-four p8/q8 endpoint covariance remain planned behind design gates. This
lane does not satisfy the scale-*slope* half of the q8 prerequisite; it
provides the scale-*intercept* covariance evidence only.

## Next Actions

Let GitHub CI validate the PR. If CI passes, merge the q2 scale-intercept
smoke/artifact lane. The remaining q8 prerequisite — bivariate residual-scale
random-slope evidence — still needs a likelihood design gate before any fitted
lane can exist.
