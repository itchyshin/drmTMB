# End-to-end Gaussian location-scale power-grid runner.
#
# Thin wrapper around the generic engine `phase18_run_power_grid()`
# (sim/run/sim_run_power_grid.R): it pins the Gaussian location-scale DGP/fit
# adapters and the `mu` slope as the effect of interest, then returns a per-cell
# power table, a power curve, and the interpolated target sample size. The design
# contract is docs/design/154-phase-18-power-simulation-plan.md.
#
# Requires the following to be sourced first (same set the recovery smoke runner
# uses, plus the power helpers and the generic engine):
#   sim/R/sim_registry.R, sim/R/sim_utils.R, sim/R/sim_runner.R,
#   sim/R/sim_uncertainty.R, sim/R/sim_power.R,
#   sim/dgp/sim_dgp_gaussian_ls.R, sim/fit/sim_summarise_gaussian_ls.R,
#   sim/run/sim_run_gaussian_ls_smoke.R  (for the DGP/fit cell adapters),
#   sim/run/sim_run_power_grid.R

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
  phase18_run_power_grid(
    surface = "gaussian_ls_power",
    base_conditions = base_conditions,
    dgp_fun = phase18_dgp_gaussian_ls_cell,
    fit_fun = phase18_fit_gaussian_ls,
    summarise_fun = phase18_summarise_gaussian_ls_fit,
    effect_name = effect_name,
    target_parameter = target_parameter,
    effect_values = effect_values,
    null_value = null_value,
    n_rep = n_rep,
    master_seed = master_seed,
    conf.level = conf.level,
    target_power = target_power,
    result_dir = result_dir,
    overwrite = overwrite,
    cores = cores,
    backend = backend
  )
}
