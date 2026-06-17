phase18_write_skew_normal_fe_grid_outputs <- function(
  output_dir,
  conditions = phase18_skew_normal_fe_conditions(
    n = c(720L, 1440L),
    nu_intercept = c(-1.20, 1.20),
    nu_slope = c(0, 0.35),
    sigma_slope = c(0.15, 0.30),
    rho_xw = c(0, 0.40)
  ),
  n_rep = 5L,
  master_seed = 20260618L,
  overwrite = FALSE,
  profile_parameters = character(),
  profile_level = 0.70,
  profile_args = list(ystep = 0.50),
  bootstrap_nsim = 0L,
  bootstrap_level = 0.70,
  bootstrap_cores = 1L,
  bootstrap_backend = "none",
  cores = 1L,
  backend = "none"
) {
  if (
    !is.character(output_dir) || length(output_dir) != 1L || !nzchar(output_dir)
  ) {
    stop("`output_dir` must be one non-empty path string.", call. = FALSE)
  }
  if (!isTRUE(overwrite) && !identical(overwrite, FALSE)) {
    stop("`overwrite` must be TRUE or FALSE.", call. = FALSE)
  }

  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  output_dir <- normalizePath(output_dir, mustWork = TRUE)
  result_dir <- file.path(output_dir, "results")
  table_dir <- file.path(output_dir, "tables")
  dir.create(result_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(table_dir, recursive = TRUE, showWarnings = FALSE)

  paths <- list(
    aggregate_csv = file.path(table_dir, "skew-normal-fe-aggregate.csv"),
    replicate_csv = file.path(table_dir, "skew-normal-fe-replicates.csv"),
    manifest_csv = file.path(table_dir, "skew-normal-fe-manifest.csv"),
    failures_csv = file.path(table_dir, "skew-normal-fe-failures.csv"),
    wald_intervals_csv = file.path(
      table_dir,
      "skew-normal-fe-wald-intervals.csv"
    ),
    wald_coverage_csv = file.path(
      table_dir,
      "skew-normal-fe-wald-coverage.csv"
    ),
    profile_intervals_csv = file.path(
      table_dir,
      "skew-normal-fe-profile-intervals.csv"
    ),
    profile_coverage_csv = file.path(
      table_dir,
      "skew-normal-fe-profile-coverage.csv"
    ),
    bootstrap_intervals_csv = file.path(
      table_dir,
      "skew-normal-fe-bootstrap-intervals.csv"
    ),
    bootstrap_coverage_csv = file.path(
      table_dir,
      "skew-normal-fe-bootstrap-coverage.csv"
    ),
    interval_evidence_csv = file.path(
      table_dir,
      "skew-normal-fe-interval-evidence.csv"
    ),
    interval_diagnostics_csv = file.path(
      table_dir,
      "skew-normal-fe-interval-diagnostics.csv"
    ),
    interval_failures_csv = file.path(
      table_dir,
      "skew-normal-fe-interval-failures.csv"
    )
  )
  phase18_assert_skew_normal_fe_grid_overwrite(paths, overwrite)

  summary <- phase18_summarise_skew_normal_fe_smoke(
    conditions = conditions,
    n_rep = n_rep,
    master_seed = master_seed,
    result_dir = result_dir,
    overwrite = overwrite,
    profile_parameters = profile_parameters,
    profile_level = profile_level,
    profile_args = profile_args,
    bootstrap_nsim = bootstrap_nsim,
    bootstrap_level = bootstrap_level,
    bootstrap_cores = bootstrap_cores,
    bootstrap_backend = bootstrap_backend,
    cores = cores,
    backend = backend
  )

  utils::write.csv(summary$aggregate, paths$aggregate_csv, row.names = FALSE)
  utils::write.csv(summary$replicates, paths$replicate_csv, row.names = FALSE)
  utils::write.csv(summary$manifest, paths$manifest_csv, row.names = FALSE)
  utils::write.csv(summary$failures, paths$failures_csv, row.names = FALSE)
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
    summary$bootstrap_intervals,
    paths$bootstrap_intervals_csv,
    row.names = FALSE
  )
  utils::write.csv(
    summary$bootstrap_coverage,
    paths$bootstrap_coverage_csv,
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
    surface = "skew_normal_fixed_effect_grid",
    output_dir = output_dir,
    result_dir = result_dir,
    table_dir = table_dir,
    paths = paths,
    artifact_manifest = phase18_grid_artifact_manifest(
      "skew_normal_fixed_effect_grid",
      paths
    ),
    summary = summary
  )
}

phase18_assert_skew_normal_fe_grid_overwrite <- function(paths, overwrite) {
  path_values <- unlist(paths, use.names = FALSE)
  existing <- path_values[file.exists(path_values)]
  if (!overwrite && length(existing) > 0L) {
    stop(
      "Skew-normal fixed-effect grid output already exists: ",
      paste(existing, collapse = ", "),
      call. = FALSE
    )
  }
  invisible(paths)
}
