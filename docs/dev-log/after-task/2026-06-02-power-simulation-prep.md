# After-Task Report: Power simulation preparation (Gaussian location-scale pilot)

## Task goal

Check whether any preparation for large power simulations existed, and if not,
start preparing. The finding: the Phase 18 programme already builds a mature
recovery harness (seeded parallel runner, 26 DGPs, fit summarisers, MCSE and
interval-coverage helpers, a dispatch workflow), and `power` is a named estimand
in `docs/design/41-phase-18-simulation-programme.md`, but the power-specific
layer was never implemented: nothing swept an effect from a null upward, nothing
counted interval rejections, and nothing read a sample size off a power curve.
This task adds those three primitives and pilots them on the Gaussian
location-scale surface (the first surface admitted in doc 41).

## Files created or changed

- `docs/design/154-phase-18-power-simulation-plan.md` (new): ADEMP plan for the
  power layer — scope and non-goals, the effect-size sweep, the
  `mean(ci_excludes_null)` estimand with binomial MCSE, the replicate-budget
  note, and the contract for the three new helpers.
- `inst/sim/R/sim_power.R` (new): surface-agnostic helpers, reusing the
  uncertainty helpers in `sim_uncertainty.R`:
  - `phase18_power_grid_conditions()` — cross any base condition grid with an
    effect-size sweep, tagging `effect_size`, `null_value`, and `is_null`.
  - `phase18_summarise_power()` — per-cell `power`, `power_mcse`, `n_interval`,
    `n_reject`, and an `inference` label (`power` / `type_i_error` / `mixed`),
    honouring the `interval_status == "ok"` filter the coverage helper uses.
  - `phase18_power_target_sample_size()` — interpolate the simulated `(n, power)`
    curve to a target power, with a status flag.
  - `phase18_assemble_power_table()` — turn a recovery summary into a per-cell
    power table: add Wald intervals if absent, count rejections, join condition
    metadata (`effect_size`, `n`, `is_null`) on `cell_id`.
  - `phase18_join_power_conditions()` — the left join used above, exposed on its
    own.
  - `phase18_power_curve_data()` — add a Monte Carlo band (`power_low`,
    `power_high`) and order rows by sample size for a left-to-right power curve.
- `inst/sim/run/sim_run_gaussian_ls_power_smoke.R` (new): end-to-end runner
  `phase18_run_gaussian_ls_power()` that composes the effect-size sweep,
  registry, replicate runner (reusing the recovery smoke runner's DGP/fit
  adapters), and the power assembler/curve/target-sample-size helpers. Mirrors
  `phase18_run_gaussian_ls_smoke()`.
- `tests/testthat/test-phase18-gaussian-ls-power-runner.R` (new): `skip_on_cran`
  smoke test that runs the end-to-end runner on a tiny null-plus-signal grid.
- `tests/testthat/test-phase18-power.R` (new): factory, power counting, the
  failed/non-finite interval filter, named per-parameter nulls, curve
  interpolation, error paths, and a `skip_on_cran` end-to-end pilot that fits the
  Gaussian location-scale model and reads power from the Wald intervals.

No existing files were edited; no `R/`, `src/`, or family behaviour changed.

## Design decisions

- **Reuse, do not fork.** The power helpers consume the output of the existing
  `phase18_summarise_gaussian_ls_fit()` plus `phase18_add_wald_intervals()`, and
  reuse `phase18_mcse_proportion()` and the assertion helpers. The rejection rule
  is the public 95% interval excluding the null, so the simulated power matches
  what a user concludes from `confint()`.
- **Surface-agnostic extraction.** Only the DGP, the fit summariser, and the
  swept effect name change between surfaces; the three helpers do not. This keeps
  the path open to `sigma`, count, and meta-analysis power without rewriting
  logic.
- **No closed-form power.** `phase18_power_target_sample_size()` interpolates the
  *simulated* curve and flags `below_grid` / `achieved_at_min`; it does not solve
  an analytic equation. This is honest about where the number comes from.
- **Type I error is a first-class output.** The `delta = 0` cell is labelled
  `type_i_error` so the null cell is read as a false-positive rate, not as
  "power near zero".
- **Scope discipline.** No large grids were run, no new families, no comparator
  zoo — matching the evidence-gate culture and the readiness matrix
  (`docs/design/46-pre-simulation-readiness-matrix.md`).

## Verification

- `inst/sim/R/sim_power.R` and the test file both parse cleanly.
- All non-fitting logic was exercised standalone in base R (no package/TMB
  needed, since the environment's network policy blocks the R package repos):
  grid factory cell counts and null tagging; `power = 1` for an
  all-excluding-null cell with `power_mcse = 0`; `power = 0` and
  `type_i_error` tag for the null cell; failed/non-finite intervals dropped from
  `n_interval`; named per-parameter null targeting (unmatched parameters
  contribute no usable interval); curve interpolation
  (`n_target = 266.67` for the worked example), `below_grid`, and
  `achieved_at_min`; and every input-validation error path. The assembler
  (`phase18_assemble_power_table`), the condition join, the MCSE-band curve
  data, and the sigma-effect reuse path were also verified standalone: a
  synthetic recovery summary with `estimate`/`std.error` flows through Wald
  intervals to a per-cell power table joined to `effect_size`/`n`/`is_null`,
  giving power `c(0, 0.5, 1)` across the three effect cells with the null cell
  tagged `type_i_error`. The end-to-end runner orchestration was validated
  against the real `phase18_run_replicates()` and `phase18_result_summaries()`
  with the model fit stubbed: a four-cell sweep (two effect sizes, two sample
  sizes) with three replicates each flowed through to a correct power table,
  curve, and target-sample-size read (`below_grid` for the null, `achieved_at_min`
  for the signal cell).
- The `skip_on_cran` Gaussian pilot fits `drmTMB` and is left for CI, where the
  dependency tree is installed; it could not run in this container because the
  network policy blocks CRAN and Posit P3M.

## What to try next

1. Run `tests/testthat/test-phase18-power.R` under a full R install (or in CI) to
   exercise the fitting pilot.
2. Widen the pilot levels in doc 154 and dispatch a sharded run through
   `.github/workflows/phase18-simulation-grid.yaml`, joining the per-cell power
   table back to the condition grid on `cell_id` to draw power curves.
3. Once the Gaussian Type I error rate sits near 0.05, reuse the same helpers for
   `sigma`, then for the admitted count and meta-analysis surfaces.
