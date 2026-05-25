phase18_write_nbinom2_sigma_re_grid_outputs <- function(
  output_dir,
  conditions = phase18_nbinom2_sigma_re_conditions(
    n_group = c(32L, 48L),
    n_per_group = 14L,
    mean_count = c(2.5, 4.0),
    sigma_baseline = c(0.55, 0.85),
    sd_sigma_intercept = c(0.25, 0.45)
  ),
  n_rep = 5L,
  master_seed = 20260524L,
  overwrite = FALSE,
  profile_parameters = character(),
  profile_level = 0.70,
  profile_args = list(ystep = 0.50),
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
    aggregate_csv = file.path(table_dir, "nbinom2-sigma-re-aggregate.csv"),
    replicate_csv = file.path(table_dir, "nbinom2-sigma-re-replicates.csv"),
    manifest_csv = file.path(table_dir, "nbinom2-sigma-re-manifest.csv"),
    failures_csv = file.path(table_dir, "nbinom2-sigma-re-failures.csv"),
    wald_intervals_csv = file.path(
      table_dir,
      "nbinom2-sigma-re-wald-intervals.csv"
    ),
    wald_coverage_csv = file.path(
      table_dir,
      "nbinom2-sigma-re-wald-coverage.csv"
    ),
    profile_targets_csv = file.path(
      table_dir,
      "nbinom2-sigma-re-profile-targets.csv"
    ),
    profile_intervals_csv = file.path(
      table_dir,
      "nbinom2-sigma-re-profile-intervals.csv"
    ),
    profile_coverage_csv = file.path(
      table_dir,
      "nbinom2-sigma-re-profile-coverage.csv"
    ),
    interval_evidence_csv = file.path(
      table_dir,
      "nbinom2-sigma-re-interval-evidence.csv"
    ),
    interval_diagnostics_csv = file.path(
      table_dir,
      "nbinom2-sigma-re-interval-diagnostics.csv"
    ),
    interval_failures_csv = file.path(
      table_dir,
      "nbinom2-sigma-re-interval-failures.csv"
    )
  )
  phase18_assert_nbinom2_sigma_re_grid_overwrite(paths, overwrite)

  summary <- phase18_summarise_nbinom2_sigma_re_smoke(
    conditions = conditions,
    n_rep = n_rep,
    master_seed = master_seed,
    result_dir = result_dir,
    overwrite = overwrite,
    profile_parameters = profile_parameters,
    profile_level = profile_level,
    profile_args = profile_args,
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

  list(
    surface = "nbinom2_sigma_random_effect_grid",
    output_dir = output_dir,
    result_dir = result_dir,
    table_dir = table_dir,
    paths = paths,
    artifact_manifest = phase18_grid_artifact_manifest(
      "nbinom2_sigma_random_effect_grid",
      paths
    ),
    summary = summary
  )
}

phase18_assert_nbinom2_sigma_re_grid_overwrite <- function(paths, overwrite) {
  path_values <- unlist(paths, use.names = FALSE)
  existing <- path_values[file.exists(path_values)]
  if (!overwrite && length(existing) > 0L) {
    stop(
      "NB2 sigma random-effect grid output already exists: ",
      paste(existing, collapse = ", "),
      call. = FALSE
    )
  }
  invisible(paths)
}
