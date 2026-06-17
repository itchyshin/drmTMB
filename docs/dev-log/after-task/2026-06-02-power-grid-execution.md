# After-Task Report: Power-grid execution layer (engine, surfaces, artifacts, dispatch)

## Task goal

Keep preparing for the big power-simulation work. The first power PR (#472) added
the per-cell power primitives and a Gaussian pilot. This task makes the layer
*runnable at scale*: a generic engine, two more admitted surfaces, an artifact
writer, and CI dispatch, so a maintainer can launch a sharded power grid and get
auditable CSV outputs.

## Files created or changed

New:
- `inst/sim/run/sim_run_power_grid.R` — `phase18_run_power_grid()`, the
  surface-agnostic engine (effect sweep -> registry -> replicate runner ->
  power table + curve + target sample size).
- `inst/sim/run/sim_run_meta_v_power_smoke.R` — `phase18_run_meta_v_power()`
  (moderator `mu:x`).
- `inst/sim/run/sim_run_poisson_mu_re_power_smoke.R` —
  `phase18_run_poisson_mu_re_power()` (population slope `mu:x`).
- `inst/sim/run/sim_write_power_grid.R` — `phase18_write_power_grid_tables()`
  (CSV artifacts + manifest), `phase18_run_and_write_power_grid()`, and the
  per-surface `phase18_write_*_power_grid_outputs()` wrappers.
- `tests/testthat/test-phase18-power-grid-engine.R` — mock-driven engine,
  writer, and run-and-write tests (offline), plus `skip_on_cran` real-fit smokes
  for meta-analysis and Poisson.

Changed:
- `inst/sim/run/sim_run_gaussian_ls_power_smoke.R` — refactored
  `phase18_run_gaussian_ls_power()` to delegate to the generic engine (behaviour
  preserved).
- `tests/testthat/test-phase18-gaussian-ls-power-runner.R` — source the engine.
- `inst/sim/run/sim_run_actions_cell.R` — add `gaussian_ls_power`,
  `meta_v_power`, `poisson_mu_re_power` to the task choices, dispatch branches,
  and dependency paths.
- `.github/workflows/phase18-simulation-grid.yaml` — add the three power tasks to
  the dropdown and the matrix (`include_in_all: false`).
- `tests/testthat/test-phase18-actions-runner.R` — dry-run and task-path tests
  for the three power tasks.
- `docs/design/154-phase-18-power-simulation-plan.md` — "Executing a power grid"
  section.

## Design decisions

- **One engine, thin wrappers.** Only the DGP, fit summariser, and swept effect
  differ between surfaces, so the engine takes them as arguments and each surface
  runner is ~15 lines. The merged Gaussian runner now delegates to it.
- **Runner computes, writer persists.** `phase18_write_power_grid_tables()` takes
  an in-memory result and writes CSV + a manifest, so persistence is pure and
  testable without fitting.
- **Additive, conservative dispatch.** The three Actions tasks mirror existing
  simple grid writers and are excluded from the `all` batch, so the team's
  default dispatch is unchanged.
- **Scope discipline.** Surfaces are limited to ones already admitted (Gaussian
  location-scale, meta-analysis known-V, Poisson mu random effect). No new
  families, no comparator zoo, no headline power claims.

## Verification

- All new/changed R files and the workflow YAML parse cleanly.
- Offline (the container blocks CRAN/P3M, so model fits run only in CI): the
  generic engine wired against the real `phase18_run_replicates()` and
  `phase18_result_summaries()` with stubbed fits produced a correct 4-cell power
  table (Type I vs power labels, `n_interval == n_rep`); the writer produced all
  CSVs + a manifest and refused to clobber without `overwrite`; run-and-write
  composed; all three Actions tasks pass dry-run; and every power task-path
  resolves to a real file.
- Real `drmTMB` fits for Gaussian, meta-analysis, and Poisson run under
  `skip_on_cran` in CI.

## What to try next

1. Dispatch `gaussian_ls_power` with a real `n_reps` (sized from the MCSE budget
   in doc 154) and inspect the artifacts under
   `inst/sim/results/actions/gaussian_ls_power/tables/`.
2. Add a power-curve gallery/figure once a real grid has run.
3. Extend to `sigma`, bivariate `rho12`, and random-effect SD targets — the
   engine already accepts a `target_parameter`, so only a wrapper is needed.
