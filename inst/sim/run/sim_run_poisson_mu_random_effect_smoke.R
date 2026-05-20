phase18_dgp_poisson_mu_re_cell <- function(cell, seed, cell_id, replicate) {
  phase18_assert_one_row_data_frame(cell, "cell")
  required <- c(
    "n_group",
    "n_per_group",
    "sd_intercept",
    "sd_x",
    "beta_mu_intercept",
    "beta_mu_x"
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
  phase18_dgp_poisson_mu_re(
    n_group = cell$n_group[[1L]],
    n_per_group = cell$n_per_group[[1L]],
    beta_mu = c(
      "(Intercept)" = cell$beta_mu_intercept[[1L]],
      x = cell$beta_mu_x[[1L]]
    ),
    sd = c(
      "(Intercept)" = cell$sd_intercept[[1L]],
      x = cell$sd_x[[1L]]
    ),
    seed = seed,
    cell_id = cell_id,
    replicate = replicate
  )
}

phase18_fit_poisson_mu_re <- function(data, cell) {
  phase18_assert_one_row_data_frame(cell, "cell")
  drmTMB(
    bf(count ~ x + (1 | id) + (0 + x | id)),
    family = stats::poisson(link = "log"),
    data = data
  )
}

phase18_run_poisson_mu_re_smoke <- function(
  conditions = phase18_poisson_mu_re_conditions(
    n_group = 36L,
    n_per_group = 9L
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
    surface = "poisson_mu_random_effect",
    conditions = conditions,
    n_rep = n_rep,
    master_seed = master_seed
  )

  results <- phase18_run_replicates(
    cells = registry$cells,
    seeds = registry$seeds,
    dgp_fun = phase18_dgp_poisson_mu_re_cell,
    fit_fun = phase18_fit_poisson_mu_re,
    summarise_fun = phase18_summarise_poisson_mu_re_fit,
    result_dir = result_dir,
    overwrite = overwrite,
    cores = cores,
    backend = backend
  )

  summary <- phase18_result_summaries(results)

  list(
    surface = "poisson_mu_random_effect",
    registry = registry,
    parallel = attr(results, "phase18_parallel", exact = TRUE),
    results = results,
    summary = summary
  )
}
