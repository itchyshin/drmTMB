# Generic Phase 18 power-grid runner.
#
# Surface-agnostic engine that drives any DGP / fit / summarise adapter set
# through an effect-size sweep and assembles a per-cell power table, a power
# curve, and the interpolated target sample size. The per-surface runners
# (sim_run_*_power_smoke.R) are thin wrappers around this engine.
#
# Requires these to be sourced first: sim/R/sim_registry.R, sim/R/sim_utils.R,
# sim/R/sim_runner.R, sim/R/sim_uncertainty.R, sim/R/sim_power.R, the surface
# DGP and fit summariser, and the recovery smoke runner that defines the cell
# adapters. Contract: docs/design/154-phase-18-power-simulation-plan.md.

phase18_run_power_grid <- function(
  surface,
  base_conditions,
  dgp_fun,
  fit_fun,
  summarise_fun,
  effect_name = "beta_mu_x",
  target_parameter = "mu:x",
  effect_values = c(0, 0.1, 0.2, 0.35, 0.5),
  null_value = 0,
  sample_size = "n",
  n_rep = 1L,
  master_seed = 20260602L,
  conf.level = 0.95,
  target_power = 0.8,
  result_dir = NULL,
  overwrite = FALSE,
  cores = 1L,
  backend = "none"
) {
  if (!is.character(surface) || length(surface) != 1L || !nzchar(surface)) {
    stop("`surface` must be one non-empty string.", call. = FALSE)
  }
  if (
    !is.character(target_parameter) ||
      length(target_parameter) != 1L ||
      !nzchar(target_parameter)
  ) {
    stop("`target_parameter` must be one non-empty string.", call. = FALSE)
  }
  if (
    !is.character(sample_size) ||
      length(sample_size) != 1L ||
      !nzchar(sample_size)
  ) {
    stop("`sample_size` must be one non-empty string.", call. = FALSE)
  }
  assert_positive_whole_number(n_rep, "n_rep")

  conditions <- phase18_power_grid_conditions(
    base_conditions,
    effect_name = effect_name,
    effect_values = effect_values,
    null_value = null_value
  )
  registry <- phase18_cell_registry(
    surface = surface,
    conditions = conditions,
    n_rep = n_rep,
    master_seed = master_seed
  )
  results <- phase18_run_replicates(
    cells = registry$cells,
    seeds = registry$seeds,
    dgp_fun = dgp_fun,
    fit_fun = fit_fun,
    summarise_fun = summarise_fun,
    result_dir = result_dir,
    overwrite = overwrite,
    cores = cores,
    backend = backend
  )
  summary <- phase18_result_summaries(results)

  null_target <- stats::setNames(null_value, target_parameter)
  power <- phase18_assemble_power_table(
    summary,
    conditions = registry$cells,
    null_value = null_target,
    conf.level = conf.level,
    by = c("surface", "cell_id", "parameter")
  )
  target_rows <- power[power$parameter == target_parameter, , drop = FALSE]
  curve <- phase18_power_curve_data(
    target_rows,
    sample_size = sample_size,
    conf.level = conf.level
  )
  target_sample_size <- phase18_power_target_sample_size(
    curve,
    target_power = target_power,
    sample_size = sample_size
  )

  list(
    surface = surface,
    effect_name = effect_name,
    target_parameter = target_parameter,
    sample_size_column = sample_size,
    registry = registry,
    parallel = attr(results, "phase18_parallel", exact = TRUE),
    results = results,
    summary = summary,
    power = power,
    curve = curve,
    sample_size = target_sample_size
  )
}
