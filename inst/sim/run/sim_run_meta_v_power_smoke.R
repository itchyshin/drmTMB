# End-to-end meta-analysis (known-V) power-grid runner.
#
# Thin wrapper around the generic engine `phase18_run_power_grid()`: it pins the
# meta-analysis DGP/fit adapters and sweeps the moderator effect `beta_mu_x`
# (parameter `mu:x`), the quantity an ecology/evolution meta-analyst usually
# powers for. Contract: docs/design/154-phase-18-power-simulation-plan.md.
#
# Requires the same source set as the recovery meta-v smoke runner, plus the
# power helpers and the generic engine:
#   sim/R/sim_registry.R, sim/R/sim_utils.R, sim/R/sim_runner.R,
#   sim/R/sim_uncertainty.R, sim/R/sim_power.R,
#   sim/dgp/sim_dgp_meta_v.R, sim/fit/sim_summarise_meta_v.R,
#   sim/run/sim_run_meta_v_smoke.R  (for the DGP/fit cell adapters),
#   sim/run/sim_run_power_grid.R

phase18_run_meta_v_power <- function(
  base_conditions = phase18_meta_v_conditions(
    n_study = c(20L, 40L, 80L),
    known_v_type = "vector",
    sigma = 0.25,
    sampling_sd = 0.14,
    sampling_rho = 0
  ),
  effect_name = "beta_mu_x",
  target_parameter = "mu:x",
  effect_values = c(0, 0.1, 0.2, 0.35, 0.5),
  null_value = 0,
  sample_size = "n_study",
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
    surface = "meta_v_power",
    base_conditions = base_conditions,
    dgp_fun = phase18_dgp_meta_v_cell,
    fit_fun = phase18_fit_meta_v,
    summarise_fun = phase18_summarise_meta_v_fit,
    effect_name = effect_name,
    target_parameter = target_parameter,
    effect_values = effect_values,
    null_value = null_value,
    sample_size = sample_size,
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
