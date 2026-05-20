phase18_write_gaussian_mu_rs_grid_outputs <- function(
  output_dir,
  conditions = phase18_gaussian_mu_rs_conditions(
    n_group = c(24L, 36L),
    n_per_group = 7L
  ),
  n_rep = 5L,
  master_seed = 20260530L,
  overwrite = FALSE,
  cores = 1L,
  backend = "none"
) {
  phase18_assert_simple_grid_output_dir(output_dir)
  if (!isTRUE(overwrite) && !identical(overwrite, FALSE)) {
    stop("`overwrite` must be TRUE or FALSE.", call. = FALSE)
  }

  dirs <- phase18_prepare_simple_grid_dirs(output_dir)
  paths <- phase18_simple_grid_paths(
    dirs$table_dir,
    prefix = "gaussian-mu-rs"
  )
  phase18_assert_simple_grid_overwrite(
    paths,
    overwrite,
    "Gaussian mu random-slope grid"
  )

  summary <- phase18_summarise_gaussian_mu_rs_smoke(
    conditions = conditions,
    n_rep = n_rep,
    master_seed = master_seed,
    result_dir = dirs$result_dir,
    overwrite = overwrite,
    cores = cores,
    backend = backend
  )
  phase18_write_simple_grid_tables(summary, paths)

  list(
    surface = "gaussian_mu_random_slope_grid",
    output_dir = dirs$output_dir,
    result_dir = dirs$result_dir,
    table_dir = dirs$table_dir,
    paths = paths,
    artifact_manifest = phase18_grid_artifact_manifest(
      "gaussian_mu_random_slope_grid",
      paths
    ),
    summary = summary
  )
}
