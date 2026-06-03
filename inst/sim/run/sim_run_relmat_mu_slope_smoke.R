phase18_fit_relmat_mu_slope <- function(data, cell) {
  phase18_assert_one_row_data_frame(cell, "cell")
  truth <- attr(data, "truth", exact = TRUE)
  Q <- truth$Q
  drmTMB(
    bf(y ~ x + relmat(1 + x | id, Q = Q), sigma ~ 1),
    family = gaussian(),
    data = data
  )
}

phase18_run_relmat_mu_slope_smoke <- function(
  conditions = phase18_relmat_mu_slope_conditions(
    n_id = 8L,
    n_each = 7L
  ),
  n_rep = 1L,
  master_seed = 20260531L,
  result_dir = NULL,
  overwrite = FALSE,
  cores = 1L,
  backend = "none"
) {
  assert_positive_whole_number(n_rep, "n_rep")
  registry <- phase18_cell_registry(
    surface = "relmat_mu_slope",
    conditions = conditions,
    n_rep = n_rep,
    master_seed = master_seed
  )

  results <- phase18_run_replicates(
    cells = registry$cells,
    seeds = registry$seeds,
    dgp_fun = phase18_dgp_relmat_mu_slope_cell,
    fit_fun = phase18_fit_relmat_mu_slope,
    summarise_fun = phase18_summarise_relmat_mu_slope_fit,
    result_dir = result_dir,
    overwrite = overwrite,
    cores = cores,
    backend = backend
  )

  summary <- phase18_result_summaries(results)

  list(
    surface = "relmat_mu_slope",
    registry = registry,
    parallel = attr(results, "phase18_parallel", exact = TRUE),
    results = results,
    summary = summary
  )
}
