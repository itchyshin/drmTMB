# After Task: Q8 Diagnostic Summaries And Skew-Normal Smoke Artifacts

## Goal

Complete the next capability slices after the diagnostic-preset and
deterministic skew-normal source-test work: make q8 diagnostic runs easier to
audit by preset, and open a first fixed-effect univariate `skew_normal()` smoke
artifact lane without claiming formal recovery.

## Implemented

The q8 endpoint lane now carries optional diagnostic metadata from
`phase18_biv_gaussian_q8_endpoint_diagnostic_conditions()` through the DGP truth
object and replicate summary rows. The new
`phase18_summarise_biv_gaussian_q8_endpoint_diagnostic_presets()` wrapper runs
the existing q8 smoke path with diagnostic grouping, then adds
`phase18_summarise_biv_gaussian_q8_endpoint_fit_diagnostics()` output for
convergence, positive-Hessian, warning, optimizer, q>4 block, SD-boundary,
high-correlation, and correlation-conditioning rates by preset.

The skew-normal lane now has a Phase 18 fixed-effect simulation stack:
`sim_dgp_skew_normal_fixed_effect.R`,
`sim_summarise_skew_normal_fixed_effect.R`,
`sim_run_skew_normal_fixed_effect_smoke.R`,
`sim_summary_skew_normal_fixed_effect_smoke.R`, and
`sim_write_skew_normal_fixed_effect_grid.R`. The DGP covers left, symmetric,
and right residual slant regimes for `bf(y ~ x, sigma ~ z, nu ~ 1)`. The writer
emits aggregate, replicate, manifest, failure, and diagnostic CSV artifacts.

`tests/testthat/test-phase18-skew-normal-fixed-effect.R` covers seeded DGP
behaviour, one smoke summary, one grid-writer output, diagnostic artifacts, and
malformed-input rejection. `tests/testthat/test-skew-normal-location-scale.R`
now also checks that `check_drm()` reports a `note` when the fitted
skew-normal slant is large.

## Mathematical Contract

No likelihood parameterization changed. Skew-normal remains public
`mu = E[y]`, public `sigma = SD[y]`, and `nu` as residual slant. The new
simulation lane fits fixed effects only and does not add random effects,
structured effects, bivariate skew-normal, residual `rho12`, or latent
`skew(id)` syntax.

The q8 work does not change the ordinary Gaussian all-endpoint likelihood or
formula grammar. It only carries diagnostic metadata and summarises the fitted
q8 block behaviour by diagnostic preset.

## Files Changed

- `inst/sim/dgp/sim_dgp_skew_normal_fixed_effect.R`
- `inst/sim/fit/sim_summarise_skew_normal_fixed_effect.R`
- `inst/sim/run/sim_run_skew_normal_fixed_effect_smoke.R`
- `inst/sim/run/sim_summary_skew_normal_fixed_effect_smoke.R`
- `inst/sim/run/sim_write_skew_normal_fixed_effect_grid.R`
- `inst/sim/fit/sim_summarise_biv_gaussian_q8_endpoint.R`
- `inst/sim/run/sim_run_biv_gaussian_q8_endpoint_smoke.R`
- `inst/sim/run/sim_summary_biv_gaussian_q8_endpoint_smoke.R`
- `tests/testthat/test-phase18-skew-normal-fixed-effect.R`
- `tests/testthat/test-phase18-biv-gaussian-q8-endpoint.R`
- `tests/testthat/test-skew-normal-location-scale.R`
- `inst/sim/README.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
Rscript --vanilla -e 'devtools::test(filter = "phase18-skew-normal-fixed-effect|skew-normal-location-scale|phase18-biv-gaussian-q8-endpoint", reporter = "summary")'
air format inst/sim/dgp/sim_dgp_skew_normal_fixed_effect.R inst/sim/fit/sim_summarise_skew_normal_fixed_effect.R inst/sim/run/sim_run_skew_normal_fixed_effect_smoke.R inst/sim/run/sim_summary_skew_normal_fixed_effect_smoke.R inst/sim/run/sim_write_skew_normal_fixed_effect_grid.R inst/sim/fit/sim_summarise_biv_gaussian_q8_endpoint.R inst/sim/run/sim_run_biv_gaussian_q8_endpoint_smoke.R inst/sim/run/sim_summary_biv_gaussian_q8_endpoint_smoke.R tests/testthat/test-phase18-skew-normal-fixed-effect.R tests/testthat/test-phase18-biv-gaussian-q8-endpoint.R tests/testthat/test-skew-normal-location-scale.R inst/sim/README.md docs/design/41-phase-18-simulation-programme.md
git diff --check
rg -n 'q8.*(coverage|power).*(ready|passed|complete)|skew_normal.*(random effects|structured effects|bivariate|rho12).*(implemented|supported|ready)|skew-normal.*formal recovery.*(ready|complete|passed)' NEWS.md ROADMAP.md README.md docs/design inst/sim vignettes R tests --glob '!docs/dev-log/**' --glob '!docs/design/archive/**'
```

The final focused test run passed after formatting. One earlier run failed
because the positive residual-`rho12` diagnostic row is `q8_diag_009`, not
`q8_diag_008`; the expectation was corrected before the final green run.
`git diff --check` passed. The stale-claim scan returned intended boundary rows
only.

## Consistency Audit

`inst/sim/README.md` now documents the q8 diagnostic preset summariser and the
skew-normal fixed-effect artifact lane. `docs/design/41-phase-18-simulation-programme.md`
now lists fixed-effect univariate `skew_normal()` as source-test plus
smoke-artifact evidence, while keeping skew-normal random effects, structured
effects, bivariate support, residual `rho12`, and latent `skew(id)` outside
admitted support.

## Known Limitations

Q8 remains diagnostic-only. The new summary helpers make weak fits easier to
classify by preset, but they do not change the 2026-06-07 q8 audit result and
do not create coverage, power, or interval-readiness evidence.

The skew-normal lane is a first smoke artifact lane. It is not a formal
recovery grid, comparator study, false-positive programme, predictor-varying
`nu` grid, random-effect route, structured-effect route, bivariate route, or
latent-skewness route.

## Next Actions

The next q8 slice should run a deliberately small diagnostic-preset stress
audit and report convergence/Hessian/boundary/conditioning rates by preset.
The next skew-normal slice should decide whether to add a formal fixed-effect
recovery design, an external comparator lane, or a broader false-positive
diagnostic grid before advertising more than smoke/artifact readiness.
