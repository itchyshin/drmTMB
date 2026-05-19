# After Task: Slices 303-307 Simulation Artifact Grain And First Grid

## Goal

Finish the figure-audit deploy path, make Phase 18 simulation artifacts honest
about replicate-level versus aggregate-only grain, and run the first small
Gaussian location-scale grid before moving to the broader simulation sequence.

## Implemented

- Merged PR #256 and verified the post-merge `main` R-CMD-check and pkgdown
  deploy for commit `977d70a5`.
- Added `phase18_result_summaries()` so current smoke runners bind replicate
  summaries consistently and mark them with `artifact_grain = "replicate"`.
- Marked aggregate summaries with `artifact_grain = "aggregate"`.
- Exposed top-level `replicates` tables from the Gaussian, meta-analysis,
  count, random-slope, and spatial summary-smoke outputs.
- Extended the count-pilot plot-data and gallery writers with
  `count-mu-replicates.csv`.
- Updated the count-pilot gallery so replicate-error points appear only when
  the replicate-level CSV exists; aggregate-only inputs stay as mean-bias
  points plus MCSE bars.
- Added `phase18_write_gaussian_ls_grid_outputs()` and ran the first small
  Gaussian location-scale grid with 8 cells and 5 replicates per cell.

## Files Changed

- `inst/sim/R/sim_runner.R`
- `inst/sim/R/sim_aggregate.R`
- `inst/sim/R/sim_plot_data.R`
- `inst/sim/R/sim_gallery.R`
- `inst/sim/run/sim_*`
- `inst/sim/reports/phase18-count-mu-gallery.Rmd`
- `inst/sim/README.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/recovery-checkpoints/2026-05-19-114912-codex-checkpoint.md`
- `tests/testthat/test-phase18-*`

## Checks Run

```sh
air format inst/sim/R/sim_runner.R inst/sim/R/sim_aggregate.R inst/sim/R/sim_plot_data.R inst/sim/R/sim_gallery.R inst/sim/run/sim_run_gaussian_ls_smoke.R inst/sim/run/sim_run_gaussian_mu_random_slope_smoke.R inst/sim/run/sim_run_gaussian_sigma_random_slope_smoke.R inst/sim/run/sim_run_meta_v_smoke.R inst/sim/run/sim_run_nbinom2_mu_random_effect_smoke.R inst/sim/run/sim_run_poisson_mu_random_effect_smoke.R inst/sim/run/sim_run_spatial_mu_slope_smoke.R inst/sim/run/sim_summary_gaussian_ls_smoke.R inst/sim/run/sim_summary_gaussian_mu_random_slope_smoke.R inst/sim/run/sim_summary_gaussian_sigma_random_slope_smoke.R inst/sim/run/sim_summary_meta_v_smoke.R inst/sim/run/sim_summary_nbinom2_mu_random_effect_smoke.R inst/sim/run/sim_summary_poisson_mu_random_effect_smoke.R inst/sim/run/sim_summary_spatial_mu_slope_smoke.R inst/sim/run/sim_summary_count_mu_random_effect_pilot.R inst/sim/reports/phase18-count-mu-gallery.Rmd tests/testthat/test-phase18-sim-runner.R tests/testthat/test-phase18-sim-aggregate.R tests/testthat/test-phase18-sim-plot-data.R tests/testthat/test-phase18-count-gallery-render-helper.R tests/testthat/test-phase18-count-gallery-template.R tests/testthat/test-phase18-count-gallery-smoke-runner.R tests/testthat/test-phase18-count-mu-random-effect-pilot.R tests/testthat/test-phase18-gaussian-ls-runner.R tests/testthat/test-phase18-gaussian-ls-summary-smoke.R
air format inst/sim/R/sim_plot_data.R
air format inst/sim/run/sim_write_gaussian_ls_grid.R tests/testthat/test-phase18-gaussian-ls-grid-writer.R
Rscript -e "devtools::test(filter = '^phase18-sim-(runner|aggregate|plot-data|uncertainty)$')"
Rscript -e "devtools::test(filter = '^phase18-count-(gallery|mu-random-effect-pilot)')"
Rscript -e "devtools::test(filter = '^phase18-gaussian-ls')"
Rscript -e "pkgdown::check_pkgdown()"
```

The first simulation-helper test run exposed and then fixed a zero-row
coverage-table edge case in `phase18_count_mu_re_add_coverage_columns()`.

## Grid Evidence

The first small Gaussian location-scale grid wrote local ignored outputs under
`inst/sim/results/slice-307-gaussian-ls-small-grid/`.

- Cells: 8.
- Replicates per cell: 5.
- Replicate results: 40, all `status = "ok"`.
- Replicate-level parameter rows: 160.
- Aggregate rows: 32.
- Warning/error ledger rows: 0.

This is artifact-path evidence, not formal coverage evidence. The replicate
count is deliberately small while the schema, diagnostics, and figures are
still being hardened.

## Team Learning

Ada kept the branch focused on the Phase 18 artifact contract rather than
opening a new modelling feature. Curie forced empty-but-valid coverage tables
to be treated as first-class outputs. Fisher kept MCSE and coverage language
separate from formal evidence claims. Grace checked the post-merge CI and
pkgdown deploy before the branch moved on. Pat and Florence kept the count
gallery from drawing fake distributional clouds from aggregate rows. Rose
tracked the recurring drift risk: every new feature request needs a DGP,
deterministic smoke test, interval or diagnostic provenance where relevant,
and coverage evidence before it is called settled. No spawned subagents were
used.

## Known Limitations

- Formal Gaussian location-scale coverage still needs a larger grid, likely
  500 replicates per cell for about one percentage point coverage MCSE.
- The count-gallery replicate display is wired, but current count smoke
  artifacts remain too small for a publication-quality raincloud.
- Bootstrap and profile-based simulation evidence are still later slices, not
  part of this artifact-grain closeout.
