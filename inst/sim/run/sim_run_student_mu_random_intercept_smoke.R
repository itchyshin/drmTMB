phase18_dgp_student_mu_ri_cell <- function(cell, seed, cell_id, replicate) {
  phase18_assert_one_row_data_frame(cell, "cell")
  required <- c(
    "n_group",
    "n_per_group",
    "beta_mu_intercept",
    "beta_mu_x",
    "beta_sigma_intercept",
    "beta_sigma_z",
    "beta_nu_intercept",
    "sd_intercept",
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

  phase18_dgp_student_mu_ri(
    n_group = cell$n_group[[1L]],
    n_per_group = cell$n_per_group[[1L]],
    beta_mu = c(
      "(Intercept)" = cell$beta_mu_intercept[[1L]],
      x = cell$beta_mu_x[[1L]]
    ),
    beta_sigma = c(
      "(Intercept)" = cell$beta_sigma_intercept[[1L]],
      z = cell$beta_sigma_z[[1L]]
    ),
    beta_nu = c("(Intercept)" = cell$beta_nu_intercept[[1L]]),
    sd = c("(1 | id)" = cell$sd_intercept[[1L]]),
    rho_xz = cell$rho_xz[[1L]],
    seed = seed,
    cell_id = cell_id,
    replicate = replicate
  )
}

phase18_fit_student_mu_ri <- function(data, cell) {
  phase18_assert_one_row_data_frame(cell, "cell")
  drmTMB(
    bf(y ~ x + (1 | id), sigma ~ z, nu ~ 1),
    family = student(),
    data = data
  )
}

phase18_run_student_mu_ri_smoke <- function(
  conditions = phase18_student_mu_ri_conditions(
    n_group = 28L,
    n_per_group = 8L,
    beta_sigma_intercept = -0.42,
    beta_sigma_z = 0.18,
    beta_nu_intercept = log(7),
    sd_intercept = 0.45,
    rho_xz = 0.20
  ),
  n_rep = 1L,
  master_seed = 20260540L,
  result_dir = NULL,
  overwrite = FALSE,
  cores = 1L,
  backend = "none"
) {
  assert_positive_whole_number(n_rep, "n_rep")
  registry <- phase18_cell_registry(
    surface = "student_mu_random_intercept",
    conditions = conditions,
    n_rep = n_rep,
    master_seed = master_seed
  )

  results <- phase18_run_replicates(
    cells = registry$cells,
    seeds = registry$seeds,
    dgp_fun = phase18_dgp_student_mu_ri_cell,
    fit_fun = phase18_fit_student_mu_ri,
    summarise_fun = phase18_summarise_student_mu_ri_fit,
    result_dir = result_dir,
    overwrite = overwrite,
    cores = cores,
    backend = backend
  )

  summary <- phase18_result_summaries(results)

  list(
    surface = "student_mu_random_intercept",
    registry = registry,
    parallel = attr(results, "phase18_parallel", exact = TRUE),
    results = results,
    summary = summary
  )
}
