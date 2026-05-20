phase18_dgp_gaussian_mu_rs_cell <- function(cell, seed, cell_id, replicate) {
  phase18_assert_one_row_data_frame(cell, "cell")
  required <- c(
    "n_group",
    "n_per_group",
    "sd_intercept",
    "sd_x1",
    "sd_x2",
    "cor_intercept_x1",
    "cor_intercept_x2",
    "cor_x1_x2",
    "beta_mu_intercept",
    "beta_mu_x1",
    "beta_mu_x2",
    "sigma"
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
  phase18_dgp_gaussian_mu_rs(
    n_group = cell$n_group[[1L]],
    n_per_group = cell$n_per_group[[1L]],
    beta_mu = c(
      "(Intercept)" = cell$beta_mu_intercept[[1L]],
      x1 = cell$beta_mu_x1[[1L]],
      x2 = cell$beta_mu_x2[[1L]]
    ),
    sigma = cell$sigma[[1L]],
    sd = c(
      "(Intercept)" = cell$sd_intercept[[1L]],
      x1 = cell$sd_x1[[1L]],
      x2 = cell$sd_x2[[1L]]
    ),
    cor = c(
      "cor((Intercept),x1 | id)" = cell$cor_intercept_x1[[1L]],
      "cor((Intercept),x2 | id)" = cell$cor_intercept_x2[[1L]],
      "cor(x1,x2 | id)" = cell$cor_x1_x2[[1L]]
    ),
    seed = seed,
    cell_id = cell_id,
    replicate = replicate
  )
}

phase18_fit_gaussian_mu_rs <- function(data, cell) {
  phase18_assert_one_row_data_frame(cell, "cell")
  drmTMB(
    bf(y ~ x1 + x2 + (1 + x1 + x2 | id), sigma ~ 1),
    family = gaussian(),
    data = data
  )
}

phase18_run_gaussian_mu_rs_smoke <- function(
  conditions = phase18_gaussian_mu_rs_conditions(
    n_group = 24L,
    n_per_group = 7L
  ),
  n_rep = 1L,
  master_seed = 20260518L,
  result_dir = NULL,
  overwrite = FALSE,
  cores = 1L,
  backend = "none"
) {
  assert_positive_whole_number(n_rep, "n_rep")
  registry <- phase18_cell_registry(
    surface = "gaussian_mu_random_slope",
    conditions = conditions,
    n_rep = n_rep,
    master_seed = master_seed
  )

  results <- phase18_run_replicates(
    cells = registry$cells,
    seeds = registry$seeds,
    dgp_fun = phase18_dgp_gaussian_mu_rs_cell,
    fit_fun = phase18_fit_gaussian_mu_rs,
    summarise_fun = phase18_summarise_gaussian_mu_rs_fit,
    result_dir = result_dir,
    overwrite = overwrite,
    cores = cores,
    backend = backend
  )

  summary <- phase18_result_summaries(results)

  list(
    surface = "gaussian_mu_random_slope",
    registry = registry,
    parallel = attr(results, "phase18_parallel", exact = TRUE),
    results = results,
    summary = summary
  )
}
