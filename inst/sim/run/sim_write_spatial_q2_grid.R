phase18_write_spatial_q2_grid_outputs <- function(
  output_dir,
  conditions = phase18_spatial_q2_conditions(
    n_site = 10L,
    n_each = 6L,
    geometry = c("ring", "stretched")
  ),
  n_rep = 5L,
  master_seed = 20260525L,
  overwrite = FALSE,
  profile_parameters = character(),
  profile_level = 0.70,
  profile_args = list(ystep = 0.50),
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
    prefix = "spatial-q2"
  )
  paths$wald_intervals_csv <- file.path(
    dirs$table_dir,
    "spatial-q2-wald-intervals.csv"
  )
  paths$wald_coverage_csv <- file.path(
    dirs$table_dir,
    "spatial-q2-wald-coverage.csv"
  )
  paths$profile_intervals_csv <- file.path(
    dirs$table_dir,
    "spatial-q2-profile-intervals.csv"
  )
  paths$profile_coverage_csv <- file.path(
    dirs$table_dir,
    "spatial-q2-profile-coverage.csv"
  )
  paths$interval_evidence_csv <- file.path(
    dirs$table_dir,
    "spatial-q2-interval-evidence.csv"
  )
  paths$interval_diagnostics_csv <- file.path(
    dirs$table_dir,
    "spatial-q2-interval-diagnostics.csv"
  )
  paths$interval_failures_csv <- file.path(
    dirs$table_dir,
    "spatial-q2-interval-failures.csv"
  )
  phase18_assert_simple_grid_overwrite(
    paths,
    overwrite,
    "Spatial q2 grid"
  )

  summary <- phase18_summarise_spatial_q2_smoke(
    conditions = conditions,
    n_rep = n_rep,
    master_seed = master_seed,
    result_dir = dirs$result_dir,
    overwrite = overwrite,
    profile_parameters = profile_parameters,
    profile_level = profile_level,
    profile_args = profile_args,
    cores = cores,
    backend = backend
  )
  phase18_write_simple_grid_tables(summary, paths)
  utils::write.csv(
    summary$wald_intervals,
    paths$wald_intervals_csv,
    row.names = FALSE
  )
  utils::write.csv(
    summary$wald_coverage,
    paths$wald_coverage_csv,
    row.names = FALSE
  )
  utils::write.csv(
    summary$profile_intervals,
    paths$profile_intervals_csv,
    row.names = FALSE
  )
  utils::write.csv(
    summary$profile_coverage,
    paths$profile_coverage_csv,
    row.names = FALSE
  )
  utils::write.csv(
    summary$interval_evidence,
    paths$interval_evidence_csv,
    row.names = FALSE
  )
  utils::write.csv(
    summary$interval_diagnostics,
    paths$interval_diagnostics_csv,
    row.names = FALSE
  )
  utils::write.csv(
    summary$interval_failures,
    paths$interval_failures_csv,
    row.names = FALSE
  )

  list(
    surface = "spatial_q2_grid",
    output_dir = dirs$output_dir,
    result_dir = dirs$result_dir,
    table_dir = dirs$table_dir,
    paths = paths,
    artifact_manifest = phase18_grid_artifact_manifest(
      "spatial_q2_grid",
      paths
    ),
    summary = summary
  )
}
