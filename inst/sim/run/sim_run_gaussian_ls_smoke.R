phase18_dgp_gaussian_ls_cell <- function(cell, seed, cell_id, replicate) {
  phase18_assert_one_row_data_frame(cell, "cell")
  required <- c(
    "n",
    "beta_mu_intercept",
    "beta_mu_x",
    "beta_sigma_intercept",
    "sigma_slope",
    "collinearity"
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
  phase18_dgp_gaussian_ls(
    n = cell$n[[1L]],
    beta_mu = c(
      "(Intercept)" = cell$beta_mu_intercept[[1L]],
      x = cell$beta_mu_x[[1L]]
    ),
    beta_sigma = c(
      "(Intercept)" = cell$beta_sigma_intercept[[1L]],
      z = cell$sigma_slope[[1L]]
    ),
    collinearity = cell$collinearity[[1L]],
    seed = seed,
    cell_id = cell_id,
    replicate = replicate
  )
}

phase18_fit_gaussian_ls <- function(data, cell) {
  phase18_assert_one_row_data_frame(cell, "cell")
  drmTMB(
    bf(y ~ x, sigma ~ z),
    family = gaussian(),
    data = data
  )
}

phase18_run_gaussian_ls_smoke <- function(
  conditions = phase18_gaussian_ls_conditions(
    n = 120L,
    sigma_slope = 0.25,
    collinearity = 0.1
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
    surface = "gaussian_ls",
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

  list(
    surface = "gaussian_ls",
    registry = registry,
    parallel = attr(results, "phase18_parallel", exact = TRUE),
    results = results,
    summary = summary
  )
}
