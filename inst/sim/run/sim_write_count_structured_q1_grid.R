phase18_write_count_structured_q1_grid_outputs <- function(
  output_dir,
  conditions = phase18_count_structured_q1_conditions(
    family = c("poisson", "nbinom2"),
    structured_type = c("spatial", "animal", "relmat"),
    n_level = c(10L, 16L),
    n_per_level = 8L,
    sd_structured = c(0.25, 0.60),
    mean_count = 3.0,
    sigma_baseline = 0.45,
    geometry = "ring"
  ),
  n_rep = 5L,
  master_seed = 20260529L,
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
  paths <- phase18_count_structured_q1_grid_paths(dirs$table_dir)
  phase18_assert_simple_grid_overwrite(
    paths,
    overwrite,
    "Count structured q1 grid"
  )

  summary <- phase18_summarise_count_structured_q1_smoke(
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
  phase18_write_count_structured_q1_grid_tables(summary, paths)

  list(
    surface = "count_structured_q1_grid",
    output_dir = dirs$output_dir,
    result_dir = dirs$result_dir,
    table_dir = dirs$table_dir,
    paths = paths,
    artifact_manifest = phase18_grid_artifact_manifest(
      "count_structured_q1_grid",
      paths
    ),
    summary = summary
  )
}

phase18_count_structured_q1_grid_paths <- function(table_dir) {
  c(
    phase18_simple_grid_paths(table_dir, prefix = "count-structured-q1"),
    list(
      wald_intervals_csv = file.path(
        table_dir,
        "count-structured-q1-wald-intervals.csv"
      ),
      wald_coverage_csv = file.path(
        table_dir,
        "count-structured-q1-wald-coverage.csv"
      ),
      profile_targets_csv = file.path(
        table_dir,
        "count-structured-q1-profile-targets.csv"
      ),
      profile_intervals_csv = file.path(
        table_dir,
        "count-structured-q1-profile-intervals.csv"
      ),
      profile_coverage_csv = file.path(
        table_dir,
        "count-structured-q1-profile-coverage.csv"
      ),
      interval_evidence_csv = file.path(
        table_dir,
        "count-structured-q1-interval-evidence.csv"
      ),
      interval_diagnostics_csv = file.path(
        table_dir,
        "count-structured-q1-interval-diagnostics.csv"
      ),
      interval_failures_csv = file.path(
        table_dir,
        "count-structured-q1-interval-failures.csv"
      )
    )
  )
}

phase18_write_count_structured_q1_grid_tables <- function(summary, paths) {
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
    summary$profile_targets,
    paths$profile_targets_csv,
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
  invisible(paths)
}
