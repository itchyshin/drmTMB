phase18_dgp_tweedie_fe_cell <- function(cell, seed, cell_id, replicate) {
  phase18_assert_one_row_data_frame(cell, "cell")
  required <- c(
    "n",
    "zero_regime",
    "target_zero_fraction",
    "beta_mu_intercept",
    "beta_mu_x",
    "beta_sigma_intercept",
    "beta_sigma_z",
    "power",
    "rho_xz"
  )
  missing <- setdiff(required, names(cell))
  if (length(missing) > 0L) {
    stop(
      "`cell` must contain ",
      paste(missing, collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  phase18_dgp_tweedie_fe(
    n = cell$n[[1L]],
    beta_mu = c(
      "(Intercept)" = cell$beta_mu_intercept[[1L]],
      x = cell$beta_mu_x[[1L]]
    ),
    beta_sigma = c(
      "(Intercept)" = cell$beta_sigma_intercept[[1L]],
      z = cell$beta_sigma_z[[1L]]
    ),
    power = cell$power[[1L]],
    rho_xz = cell$rho_xz[[1L]],
    target_zero_fraction = cell$target_zero_fraction[[1L]],
    zero_regime = cell$zero_regime[[1L]],
    seed = seed,
    cell_id = cell_id,
    replicate = replicate
  )
}

phase18_fit_tweedie_fe <- function(data, cell) {
  phase18_assert_one_row_data_frame(cell, "cell")
  drmTMB(
    bf(y ~ x, sigma ~ z, nu ~ 1),
    family = tweedie(),
    data = data
  )
}

phase18_run_tweedie_fe_smoke <- function(
  conditions = phase18_tweedie_fe_conditions(
    n = 320L,
    zero_regime = c("low", "high"),
    rho_xz = 0.20
  ),
  n_rep = 1L,
  master_seed = 20260538L,
  result_dir = NULL,
  overwrite = FALSE,
  cores = 1L,
  backend = "none"
) {
  assert_positive_whole_number(n_rep, "n_rep")
  registry <- phase18_cell_registry(
    surface = "tweedie_fixed_effect",
    conditions = conditions,
    n_rep = n_rep,
    master_seed = master_seed
  )

  results <- phase18_run_replicates(
    cells = registry$cells,
    seeds = registry$seeds,
    dgp_fun = phase18_dgp_tweedie_fe_cell,
    fit_fun = phase18_fit_tweedie_fe,
    summarise_fun = phase18_summarise_tweedie_fe_fit,
    result_dir = result_dir,
    overwrite = overwrite,
    cores = cores,
    backend = backend
  )

  summary <- phase18_result_summaries(results)

  list(
    surface = "tweedie_fixed_effect",
    registry = registry,
    parallel = attr(results, "phase18_parallel", exact = TRUE),
    results = results,
    summary = summary
  )
}
