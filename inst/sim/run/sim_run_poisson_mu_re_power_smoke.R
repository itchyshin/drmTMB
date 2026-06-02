# End-to-end Poisson mu random-effect power-grid runner.
#
# Thin wrapper around the generic engine `phase18_run_power_grid()`: it pins the
# Poisson mu random-effect DGP/fit adapters and sweeps the population fixed slope
# `beta_mu_x` (parameter `mu:x`) while random intercepts and slopes remain in the
# model. Contract: docs/design/154-phase-18-power-simulation-plan.md.
#
# Requires the same source set as the recovery Poisson mu random-effect smoke
# runner, plus the power helpers and the generic engine:
#   sim/R/sim_registry.R, sim/R/sim_utils.R, sim/R/sim_runner.R,
#   sim/R/sim_uncertainty.R, sim/R/sim_power.R,
#   sim/dgp/sim_dgp_poisson_mu_random_effect.R,
#   sim/fit/sim_summarise_poisson_mu_random_effect.R,
#   sim/run/sim_run_poisson_mu_random_effect_smoke.R  (for the cell adapters),
#   sim/run/sim_run_power_grid.R

phase18_run_poisson_mu_re_power <- function(
  base_conditions = phase18_poisson_mu_re_conditions(
    n_group = c(24L, 48L, 96L),
    n_per_group = 8L
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
    surface = "poisson_mu_re_power",
    base_conditions = base_conditions,
    dgp_fun = phase18_dgp_poisson_mu_re_cell,
    fit_fun = phase18_fit_poisson_mu_re,
    summarise_fun = phase18_summarise_poisson_mu_re_fit,
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
