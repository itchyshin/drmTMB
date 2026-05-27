phase18_dgp_zero_one_beta_fe_cell <- function(cell, seed, cell_id, replicate) {
  phase18_assert_one_row_data_frame(cell, "cell")
  required <- c(
    "n",
    "beta_mu_intercept",
    "beta_mu_x",
    "beta_sigma_intercept",
    "beta_sigma_z",
    "beta_zoi_intercept",
    "beta_zoi_w",
    "beta_coi_intercept",
    "beta_coi_v",
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

  phase18_dgp_zero_one_beta_fe(
    n = cell$n[[1L]],
    beta_mu = c(
      "(Intercept)" = cell$beta_mu_intercept[[1L]],
      x = cell$beta_mu_x[[1L]]
    ),
    beta_sigma = c(
      "(Intercept)" = cell$beta_sigma_intercept[[1L]],
      z = cell$beta_sigma_z[[1L]]
    ),
    beta_zoi = c(
      "(Intercept)" = cell$beta_zoi_intercept[[1L]],
      w = cell$beta_zoi_w[[1L]]
    ),
    beta_coi = c(
      "(Intercept)" = cell$beta_coi_intercept[[1L]],
      v = cell$beta_coi_v[[1L]]
    ),
    rho_xz = cell$rho_xz[[1L]],
    seed = seed,
    cell_id = cell_id,
    replicate = replicate
  )
}

phase18_fit_zero_one_beta_fe <- function(data, cell) {
  phase18_assert_one_row_data_frame(cell, "cell")
  drmTMB(
    bf(prop ~ x, sigma ~ z, zoi ~ w, coi ~ v),
    family = zero_one_beta(),
    data = data
  )
}

phase18_run_zero_one_beta_fe_smoke <- function(
  conditions = phase18_zero_one_beta_fe_conditions(
    n = 360L,
    beta_sigma_intercept = -0.80,
    beta_sigma_z = 0.15,
    beta_zoi_intercept = -1.20,
    beta_zoi_w = 0.30,
    beta_coi_intercept = 0.10,
    beta_coi_v = -0.30,
    rho_xz = 0.20
  ),
  n_rep = 1L,
  master_seed = 20260536L,
  result_dir = NULL,
  overwrite = FALSE,
  cores = 1L,
  backend = "none"
) {
  assert_positive_whole_number(n_rep, "n_rep")
  registry <- phase18_cell_registry(
    surface = "zero_one_beta_fixed_effect",
    conditions = conditions,
    n_rep = n_rep,
    master_seed = master_seed
  )

  results <- phase18_run_replicates(
    cells = registry$cells,
    seeds = registry$seeds,
    dgp_fun = phase18_dgp_zero_one_beta_fe_cell,
    fit_fun = phase18_fit_zero_one_beta_fe,
    summarise_fun = phase18_summarise_zero_one_beta_fe_fit,
    result_dir = result_dir,
    overwrite = overwrite,
    cores = cores,
    backend = backend
  )

  summary <- phase18_result_summaries(results)

  list(
    surface = "zero_one_beta_fixed_effect",
    registry = registry,
    parallel = attr(results, "phase18_parallel", exact = TRUE),
    results = results,
    summary = summary
  )
}
