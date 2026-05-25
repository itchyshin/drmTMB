phase18_dgp_ordinal_fe_cell <- function(cell, seed, cell_id, replicate) {
  phase18_assert_one_row_data_frame(cell, "cell")
  required <- c("n", "n_category", "beta_mu_x", "cutpoint_pattern")
  missing <- setdiff(required, names(cell))
  if (length(missing) > 0L) {
    stop(
      "`cell` must contain ",
      paste(missing, collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  phase18_dgp_ordinal_fe(
    n = cell$n[[1L]],
    n_category = cell$n_category[[1L]],
    beta_mu = c(x = cell$beta_mu_x[[1L]]),
    cutpoint_pattern = cell$cutpoint_pattern[[1L]],
    seed = seed,
    cell_id = cell_id,
    replicate = replicate
  )
}

phase18_fit_ordinal_fe <- function(data, cell) {
  phase18_assert_one_row_data_frame(cell, "cell")
  drmTMB(
    bf(score ~ x),
    family = cumulative_logit(),
    data = data
  )
}

phase18_run_ordinal_fe_smoke <- function(
  conditions = phase18_ordinal_fe_conditions(
    n = 320L,
    n_category = c(3L, 5L),
    beta_mu_x = 0.65,
    cutpoint_pattern = "balanced"
  ),
  n_rep = 1L,
  master_seed = 20260535L,
  result_dir = NULL,
  overwrite = FALSE,
  cores = 1L,
  backend = "none"
) {
  assert_positive_whole_number(n_rep, "n_rep")
  registry <- phase18_cell_registry(
    surface = "ordinal_fixed_effect",
    conditions = conditions,
    n_rep = n_rep,
    master_seed = master_seed
  )

  results <- phase18_run_replicates(
    cells = registry$cells,
    seeds = registry$seeds,
    dgp_fun = phase18_dgp_ordinal_fe_cell,
    fit_fun = phase18_fit_ordinal_fe,
    summarise_fun = phase18_summarise_ordinal_fe_fit,
    result_dir = result_dir,
    overwrite = overwrite,
    cores = cores,
    backend = backend
  )

  summary <- phase18_result_summaries(results)

  list(
    surface = "ordinal_fixed_effect",
    registry = registry,
    parallel = attr(results, "phase18_parallel", exact = TRUE),
    results = results,
    summary = summary
  )
}
