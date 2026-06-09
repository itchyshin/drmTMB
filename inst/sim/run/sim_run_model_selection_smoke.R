phase18_run_model_selection_smoke <- function(
    conditions = phase18_model_selection_conditions(),
    n_rep = 2L,
    master_seed = 20260609L,
    result_dir = NULL,
    overwrite = FALSE,
    cores = 1L,
    backend = "none") {
  assert_positive_whole_number(n_rep, "n_rep")
  registry <- phase18_cell_registry(
    surface = "model_selection",
    conditions = conditions,
    n_rep = n_rep,
    master_seed = master_seed
  )
  results <- phase18_run_replicates(
    cells = registry$cells,
    seeds = registry$seeds,
    dgp_fun = phase18_dgp_model_selection_cell,
    fit_fun = phase18_fit_model_selection,
    summarise_fun = phase18_summarise_model_selection_fit,
    result_dir = result_dir,
    overwrite = overwrite,
    cores = cores,
    backend = backend
  )
  summary <- phase18_result_summaries(results)
  list(
    surface = "model_selection",
    registry = registry,
    parallel = attr(results, "phase18_parallel", exact = TRUE),
    results = results,
    summary = summary
  )
}
