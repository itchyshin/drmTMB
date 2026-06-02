# End-to-end Gaussian location-scale power-grid runner.
#
# Composes the existing Phase 18 machinery into one call: build an effect-size
# sweep, register cells and seeds, run replicates with the Gaussian
# location-scale DGP and fit adapters, then assemble a per-cell power table,
# a power curve, and the interpolated target sample size. The design contract is
# docs/design/154-phase-18-power-simulation-plan.md.
#
# Requires the following to be sourced first (same set the recovery smoke runner
# uses, plus the power helpers):
#   sim/R/sim_registry.R, sim/R/sim_utils.R, sim/R/sim_runner.R,
#   sim/R/sim_uncertainty.R, sim/R/sim_power.R,
#   sim/dgp/sim_dgp_gaussian_ls.R, sim/fit/sim_summarise_gaussian_ls.R,
#   sim/run/sim_run_gaussian_ls_smoke.R  (for the DGP/fit cell adapters)

phase18_run_gaussian_ls_power <- function(
  base_conditions = phase18_gaussian_ls_conditions(
    n = c(120L, 240L, 480L),
    sigma_slope = 0,
    collinearity = 0
  ),
  effect_name = "beta_mu_x",
  target_parameter = "mu:x",
  effect_values = c(0, 0.1, 0.2, 0.35, 0.5),
  null_value = 0,
  n_rep = 1L,
  master_seed = 20260602L,
  conf.level = 0.95,
  target_power = 0.8,
  result_dir = NULL,
  overwrite = FALSE,
  cores = 1L,
  backend = "none"
) {
  assert_positive_whole_number(n_rep, "n_rep")
  if (
    !is.character(target_parameter) ||
      length(target_parameter) != 1L ||
      !nzchar(target_parameter)
  ) {
    stop("`target_parameter` must be one non-empty string.", call. = FALSE)
  }

  conditions <- phase18_power_grid_conditions(
    base_conditions,
    effect_name = effect_name,
    effect_values = effect_values,
    null_value = null_value
  )
  registry <- phase18_cell_registry(
    surface = "gaussian_ls_power",
    conditions = conditions,
    n_rep = n_rep,
    master_seed = master_seed
  )

  results <- phase18_run_replicates(
    cells = registry$cells,
    seeds = registry$seeds,
    dgp_fun = phase18_dgp_gaussian_ls_cell,
    fit_fun = phase18_fit_gaussian_ls,
    summarise_fun = phase18_summarise_gaussian_ls_fit,
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
  curve <- phase18_power_curve_data(target_rows, conf.level = conf.level)
  sample_size <- phase18_power_target_sample_size(
    curve,
    target_power = target_power
  )

  list(
    surface = "gaussian_ls_power",
    effect_name = effect_name,
    target_parameter = target_parameter,
    registry = registry,
    parallel = attr(results, "phase18_parallel", exact = TRUE),
    results = results,
    summary = summary,
    power = power,
    curve = curve,
    sample_size = sample_size
  )
}
