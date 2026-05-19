# After-Task Report: Slices 308-314 Correlation Inference And Bivariate Rho12 Simulation

## Goal

Start the post-artifact-grain inference block by making correlation interval
routes explicit, adding the first bivariate residual `rho12` simulation surface,
and introducing private bootstrap plumbing for later simulation studies.

## Standing Roles

Ada coordinated the slice order, merged the previous artifact-grain PR after CI
passed, and rebased the new branch onto current `main`.

Curie owned the DGP, runner, grid writer, and focused tests.

Fisher kept interval routes separate: direct profile-ready targets, response-
scale `newdata` targets, formula-coefficient Wald coverage, and private
bootstrap refits are different evidence types.

Grace watched branch state, CI inheritance, and artifact reproducibility.

Pat checked that simulation outputs remain inspectable through CSVs, manifests,
and failure ledgers.

Rose checked for claim drift: the small grids are artifact validation and smoke
recovery checks, not formal operating-characteristic evidence.

Florence was not active in this slice because no new figure grammar or rendered
plot was changed.

No spawned subagents were running.

## Implementation

`inst/sim/R/sim_correlation_targets.R` adds a simulation-only inventory helper
that reads `corpairs()` rows and attaches profile targets, profile readiness,
interval routes, and interval statuses without running profiles.

`inst/sim/dgp/sim_dgp_biv_rho12.R`,
`inst/sim/fit/sim_summarise_biv_rho12.R`, and
`inst/sim/run/sim_run_biv_rho12_smoke.R` add the bivariate Gaussian residual
`rho12` surface: response-specific `mu`, response-specific `sigma`, and
`rho12 ~ w` on the fitted link scale.

`inst/sim/run/sim_summary_biv_rho12_smoke.R` and
`inst/sim/run/sim_write_biv_rho12_grid.R` add aggregate, replicate, manifest,
failure, Wald-interval, and Wald-coverage artifacts for this surface.

`inst/sim/R/sim_uncertainty.R` now includes
`phase18_interval_failures()` so non-usable interval rows remain visible.

`inst/sim/R/sim_bootstrap.R` adds private simulation-study bootstrap helpers:
`phase18_parametric_bootstrap()` and
`phase18_bootstrap_percentile_intervals()`. These helpers do not implement a
public bootstrap interval method.

## Evidence

Focused new simulation tests passed:

```sh
Rscript -e "devtools::test(filter = '^phase18-(correlation-targets|biv-rho12|sim-(bootstrap|uncertainty))')"
```

Result: 137 tests, 0 failures, 0 warnings, 0 skips.

The small bivariate residual `rho12` grid was written to
`inst/sim/results/slice-314-biv-rho12-small-grid/`. Its concise artifact check
reported:

```text
manifest status: ok = 12
replicate rows: 120
aggregate rows: 40
failure rows: 0
```

## Limitations

The small `rho12` grid has only 3 replicates per cell. It validates the runner,
artifact contract, and gross recovery path; it is not formal bias, RMSE, or
coverage evidence.

Response-scale profile coverage for predictor-dependent `rho12` and profile
coverage for latent `corpair()` targets are still follow-up slices.

The bootstrap helpers are private Phase 18 simulation plumbing. Public
`confint(method = "bootstrap")`, `summary(method = "bootstrap")`, and
`corpairs(method = "bootstrap")` remain intentionally unsupported.

## Next Step

Move from this infrastructure block into the next simulation surfaces: response-
scale `rho12` profile pilots first, then shape-model smoke surfaces once their
likelihood and interval targets have the same artifact, failure-ledger, and
coverage discipline.
