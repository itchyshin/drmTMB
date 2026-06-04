phase18_write_biv_gaussian_q2_scale_recovery_grid_outputs <- function(
  output_dir,
  conditions = phase18_biv_gaussian_q2_scale_conditions(
    n_id = c(48L, 96L),
    n_each = 8L
  ),
  n_rep = 50L,
  master_seed = 20260626L,
  overwrite = FALSE,
  wald_level = 0.95,
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

  prefix <- "biv-gaussian-q2-scale-recovery"
  paths <- list(
    aggregate_csv = file.path(table_dir, paste0(prefix, "-aggregate.csv")),
    replicate_csv = file.path(table_dir, paste0(prefix, "-replicates.csv")),
    manifest_csv = file.path(table_dir, paste0(prefix, "-manifest.csv")),
    failures_csv = file.path(table_dir, paste0(prefix, "-failures.csv")),
    wald_intervals_csv = file.path(
      table_dir,
      paste0(prefix, "-wald-intervals.csv")
    ),
    wald_coverage_csv = file.path(
      table_dir,
      paste0(prefix, "-wald-coverage.csv")
    ),
    interval_evidence_csv = file.path(
      table_dir,
      paste0(prefix, "-interval-evidence.csv")
    ),
    interval_diagnostics_csv = file.path(
      table_dir,
      paste0(prefix, "-interval-diagnostics.csv")
    ),
    interval_failures_csv = file.path(
      table_dir,
      paste0(prefix, "-interval-failures.csv")
    )
  )
  phase18_assert_biv_gaussian_q2_scale_recovery_grid_overwrite(paths, overwrite)

  summary <- phase18_summarise_biv_gaussian_q2_scale_recovery(
    conditions = conditions,
    n_rep = n_rep,
    master_seed = master_seed,
    result_dir = result_dir,
    overwrite = overwrite,
    wald_level = wald_level,
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
    surface = "biv_gaussian_q2_scale_recovery_grid",
    output_dir = output_dir,
    result_dir = result_dir,
    table_dir = table_dir,
    paths = paths,
    artifact_manifest = phase18_grid_artifact_manifest(
      "biv_gaussian_q2_scale_recovery_grid",
      paths
    ),
    summary = summary
  )
}

phase18_assert_biv_gaussian_q2_scale_recovery_grid_overwrite <- function(
  paths,
  overwrite
) {
  path_values <- unlist(paths, use.names = FALSE)
  existing <- path_values[file.exists(path_values)]
  if (!overwrite && length(existing) > 0L) {
    stop(
      "Bivariate Gaussian q2 scale recovery grid output already exists: ",
      paste(existing, collapse = ", "),
      call. = FALSE
    )
  }
  invisible(paths)
}
