phase18_write_biv_gaussian_q8_endpoint_diagnostic_grid_outputs <- function(
  output_dir,
  conditions = phase18_biv_gaussian_q8_endpoint_diagnostic_audit_conditions(
    mode = "stress"
  ),
  n_rep = 1L,
  master_seed = 20260639L,
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
    prefix = "biv-gaussian-q8-endpoint-diagnostic"
  )
  paths$diagnostic_summary_csv <- file.path(
    dirs$table_dir,
    "biv-gaussian-q8-endpoint-diagnostic-summary.csv"
  )
  phase18_assert_simple_grid_overwrite(
    paths,
    overwrite,
    "Bivariate Gaussian q8 endpoint diagnostic grid"
  )

  summary <- phase18_summarise_biv_gaussian_q8_endpoint_diagnostic_presets(
    conditions = conditions,
    n_rep = n_rep,
    master_seed = master_seed,
    result_dir = dirs$result_dir,
    overwrite = overwrite,
    cores = cores,
    backend = backend
  )
  phase18_write_simple_grid_tables(summary, paths)
  utils::write.csv(
    summary$diagnostic_summary,
    paths$diagnostic_summary_csv,
    row.names = FALSE
  )

  list(
    surface = "biv_gaussian_q8_endpoint_diagnostic_grid",
    output_dir = dirs$output_dir,
    result_dir = dirs$result_dir,
    table_dir = dirs$table_dir,
    paths = paths,
    artifact_manifest = phase18_grid_artifact_manifest(
      "biv_gaussian_q8_endpoint_diagnostic_grid",
      paths
    ),
    summary = summary
  )
}
