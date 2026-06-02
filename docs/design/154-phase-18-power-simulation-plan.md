# Phase 18 Power Simulation Plan

This sheet is for the `drmTMB` maintainer who wants to add **power and
false-positive-rate** evidence on top of the existing Phase 18 recovery harness.
It follows the ADEMP structure of Morris, White, and Crowther (2019) and the
transparent-reporting checklist of Williams et al. (2024). It records what the
new power helpers are allowed to estimate and how they reuse the harness, so a
larger grid can run later without re-litigating the design.

Purpose: turn the Phase 18 recovery engine into a power engine. The recovery
harness already measures bias, RMSE, and interval coverage per condition cell.
Power needs three things the harness did not yet have: a way to sweep an effect
from a null value upward, a way to count how often the interval excludes that
null, and a way to read a target sample size off the resulting curve. This plan
adds exactly those three pieces and pilots them on the Gaussian location-scale
surface, which is the first surface admitted in
`docs/design/41-phase-18-simulation-programme.md`.

## Scope and non-goals

In scope for this pass:

- A surface-agnostic effect-size **condition factory** that crosses any existing
  Phase 18 condition grid with a sweep of one effect, including a null cell.
- A surface-agnostic **power summary** that reports `mean(ci_excludes_null)` with
  binomial Monte Carlo standard error (MCSE), and tags each cell as a power
  estimate or a Type I error-rate estimate.
- A descriptive **sample-size reader** that interpolates the simulated power
  curve to the sample size that reaches a target power.
- Tests and a Gaussian location-scale pilot that compose these with the existing
  DGP, fit summariser, and Wald-interval helper.

Out of scope for this pass (deliberately, to avoid scope creep):

- No parametric or closed-form power formula. The sample-size reader interpolates
  the *simulated* curve; it does not solve an analytic equation.
- No large grids are run here. This sheet sets the contract; the grid runs later
  through `.github/workflows/phase18-simulation-grid.yaml`.
- No new families, no comparator zoo, and no power claims for surfaces that the
  pre-simulation readiness matrix (`docs/design/46-pre-simulation-readiness-matrix.md`)
  has not admitted.

## A - Aims

Primary aim: estimate the power to detect a fixed `mu` slope (`beta_mu_x`) in the
Gaussian location-scale model `mu ~ x`, `sigma ~ z`, as a function of sample size
`n` and effect size, using the 95% Wald interval excluding zero as the rejection
rule.

Secondary aims: estimate the Type I error rate at `beta_mu_x = 0` (the null cell)
and confirm it sits near the nominal 0.05; demonstrate that the same helpers
extend to power for effects on `sigma` and, later, `rho12` and random-effect SDs,
without re-writing the extraction logic.

## D - Data-Generating Mechanism

Reuse `phase18_dgp_gaussian_ls()` unchanged. The power grid varies the effect of
interest while holding the rest of the cell fixed:

```text
x_i ~ Normal(0, 1)
z_i = rho_xz * x_i + sqrt(1 - rho_xz^2) * epsilon_i, epsilon_i ~ Normal(0, 1)
mu_i = beta0 + delta * x_i              # delta is swept, including delta = 0
log(sigma_i) = gamma0 + gamma1 * z_i
y_i ~ Normal(mu_i, sigma_i^2)
```

`delta = 0` is the null cell used for the Type I error rate; `delta > 0` cells are
the power cells. `phase18_power_grid_conditions()` builds this sweep from any base
condition grid, so the same call shape works for `sigma` slopes or correlation
effects on other surfaces.

Initial pilot levels (small, CRAN-safe; widen before a formal grid):

| Factor | Initial levels | Reason |
| --- | --- | --- |
| `n` | {120, 240, 480} | Read a power curve across realistic ecology sample sizes |
| `delta` (`beta_mu_x`) | {0, 0.1, 0.2, 0.35, 0.5} | Include the null and span low-to-clear power |
| `rho_xz` (collinearity) | {0, 0.6} | Test whether `x`-`z` collinearity erodes power |
| `gamma1` (sigma slope) | {0, 0.35} | Hold or perturb the residual-scale signal |

## E - Estimands

The target is the rejection probability `P(0 is outside the 95% interval for
beta_mu_x | n, delta)`. At `delta = 0` this estimand is the Type I error rate; at
`delta > 0` it is the power. The secondary estimand is the sample size `n*` at
which power first reaches a target (default 0.8) for a given `delta`.

## M - Methods

Fit the intended `drmTMB` model with `phase18_dgp_gaussian_ls()` truth and the
existing `phase18_summarise_gaussian_ls_fit()` summariser, which already returns
per-parameter `estimate`, `std.error`, and convergence flags. Form 95% Wald
intervals with the existing `phase18_add_wald_intervals()`. The rejection rule is
the interval excluding the null, which matches the public `confint()` contract a
user would apply, so the power estimate reflects what a user would actually
conclude. A nested-model likelihood-ratio comparator is allowed later where it is
honest, per `docs/design/41-phase-18-simulation-programme.md`; it is not required
for this interval-based pass.

## P - Performance Measures

| Measure | Formula | Report with |
| --- | --- | --- |
| Power / Type I error | `mean(ci_excludes_null)` over usable intervals | binomial MCSE `sqrt(p(1-p)/n_sim)` |
| Target sample size | interpolated `n` where the simulated power curve crosses the target | grid min/max and a status flag |

This matches the Power row already specified in
`docs/design/41-phase-18-simulation-programme.md`. Plan the replicate budget from
the MCSE before any large run: a power near 0.8 has binomial MCSE about 1.8
percentage points at 500 replicates and about 1.3 at 1000; a Type I error rate
near 0.05 has MCSE about 1.0 percentage point at 500 replicates. A pilot may use
far fewer replicates to check the pipeline, but should not report a headline power
number until the MCSE is small enough to support it.

## New helpers (this sheet)

All three live in `inst/sim/R/sim_power.R` and reuse the uncertainty helpers in
`inst/sim/R/sim_uncertainty.R` (`phase18_mcse_proportion`,
`phase18_default_summary_groups`, the assertion helpers):

- `phase18_power_grid_conditions(base, effect_name, effect_values, null_value)`
  crosses a base condition grid with an effect-size sweep, tagging each cell with
  `effect_size`, `null_value`, and `is_null`.
- `phase18_summarise_power(summary, by, null_value, lower, upper)` reports
  `power`, `power_mcse`, `n_interval`, `n_reject`, and an `inference` label
  (`"power"`, `"type_i_error"`, or `"mixed"`) per cell, honouring the
  `interval_status == "ok"` filter the coverage helper already uses.
- `phase18_power_target_sample_size(power_table, target_power, ...)` interpolates
  the simulated `(n, power)` curve within each effect-size group and returns the
  crossing sample size with a status flag (`interpolated`, `achieved_at_min`,
  `below_grid`, or `no_data`).

Three more helpers in the same file assemble and shape the output so a report can
be drawn without bespoke code per surface:

- `phase18_assemble_power_table(summary, conditions, null_value, ...)` takes a
  recovery summary (the per-replicate output of a fit summariser), adds 95% Wald
  intervals when they are absent, counts rejections, and joins condition metadata
  (`effect_size`, `n`, `is_null`) on `cell_id`. Pass the `$cells` table from
  `phase18_cell_registry()` as `conditions`.
- `phase18_join_power_conditions(power, conditions, join_key)` is the left join
  used above, exposed on its own; it keeps every power row and adds only the
  condition columns the power table does not already carry.
- `phase18_power_curve_data(power_table, ...)` adds a Monte Carlo band
  (`power_low`, `power_high`) from `power_mcse`, clamped to `[0, 1]`, and orders
  rows within each effect-size group by sample size so a power curve reads left to
  right.

## End-to-end runner

`inst/sim/run/sim_run_gaussian_ls_power_smoke.R` defines
`phase18_run_gaussian_ls_power()`, which composes the whole pipeline in one
call: build the effect-size sweep, register cells and seeds, run replicates with
the Gaussian location-scale DGP and fit adapters (reused from the recovery smoke
runner), then assemble a per-cell power table, a power curve, and the
interpolated target sample size. It mirrors `phase18_run_gaussian_ls_smoke()` and
returns `$power`, `$curve`, and `$sample_size` alongside the registry and raw
results. The orchestration was validated end to end against the real
`phase18_run_replicates()` and `phase18_result_summaries()` with the model fit
stubbed; the real `drmTMB` fit runs under `skip_on_cran` in CI.

## Executing a power grid

The orchestration is now generic and wired for dispatch:

- `phase18_run_power_grid()` (in `inst/sim/run/sim_run_power_grid.R`) is the
  surface-agnostic engine. It takes any DGP / fit / summarise adapter set, an
  effect name, and a target parameter, then returns `$power`, `$curve`, and
  `$sample_size`. The per-surface runners are thin wrappers:
  `phase18_run_gaussian_ls_power()`, `phase18_run_meta_v_power()` (moderator
  `mu:x`), and `phase18_run_poisson_mu_re_power()` (population slope `mu:x` with
  random intercepts and slopes in the model).
- `phase18_write_power_grid_tables()` (in `inst/sim/run/sim_write_power_grid.R`)
  persists a runner result to CSV — power table, curve, target-sample-size,
  condition registry, and per-replicate summary — plus a manifest. The
  `phase18_write_*_power_grid_outputs()` wrappers run and persist in one call.
- Three Actions tasks dispatch these through
  `.github/workflows/phase18-simulation-grid.yaml`: `gaussian_ls_power`,
  `meta_v_power`, and `poisson_mu_re_power`. They are excluded from the `all`
  batch (`include_in_all: false`); select one explicitly and set `n_reps` from
  the MCSE budget above. A real grid run writes its artifacts under
  `inst/sim/results/actions/<task>/tables/`.

The engine, writer, and dispatch wiring were validated offline against the real
`phase18_run_replicates()`/`phase18_result_summaries()` with the model fit
stubbed; the real `drmTMB` fits for the Gaussian, meta-analysis, and Poisson
surfaces run under `skip_on_cran` in CI.

## What to try next

1. Run the Gaussian location-scale power pilots in
   `tests/testthat/test-phase18-power.R` and
   `tests/testthat/test-phase18-gaussian-ls-power-runner.R` to confirm the
   pipeline composes against real fits.
2. Widen the levels above and dispatch a sharded run through
   `.github/workflows/phase18-simulation-grid.yaml`, joining the per-cell power
   table back to the condition grid on `cell_id` to draw power curves.
3. Once the Gaussian surface reports a stable Type I error rate near 0.05, reuse
   the same three helpers for `sigma`, then for the admitted count and
   meta-analysis surfaces. The extraction logic does not change between surfaces;
   only the DGP, the fit summariser, and the swept effect name do.

## References

- Morris, T. P., White, I. R., & Crowther, M. J. (2019). Using simulation
  studies to evaluate statistical methods. *Statistics in Medicine*, 38(11),
  2074-2102.
- Williams, M. N., et al. (2024). Transparent reporting of simulation studies.
