phase18_write_biv_rho12_grid_outputs <- function(
  output_dir,
  conditions = phase18_biv_rho12_conditions(
    n = c(180L, 360L),
    delta0 = atanh(c(-0.25, 0.25)),
    delta1 = c(0, 0.25),
    sigma_ratio = c(0.8, 1.2),
    rho_xw = c(0, 0.4)
  ),
  n_rep = 5L,
  master_seed = 20260524L,
  overwrite = FALSE,
  profile_parameters = character(),
  profile_level = 0.70,
  profile_args = list(ystep = 0.50),
  bootstrap_nsim = 0L,
  bootstrap_level = 0.70
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
    aggregate_csv = file.path(table_dir, "biv-rho12-aggregate.csv"),
    replicate_csv = file.path(table_dir, "biv-rho12-replicates.csv"),
    manifest_csv = file.path(table_dir, "biv-rho12-manifest.csv"),
    failures_csv = file.path(table_dir, "biv-rho12-failures.csv"),
    wald_intervals_csv = file.path(table_dir, "biv-rho12-wald-intervals.csv"),
    wald_coverage_csv = file.path(table_dir, "biv-rho12-wald-coverage.csv"),
    profile_intervals_csv = file.path(
      table_dir,
      "biv-rho12-profile-intervals.csv"
    ),
    profile_coverage_csv = file.path(
      table_dir,
      "biv-rho12-profile-coverage.csv"
    ),
    bootstrap_intervals_csv = file.path(
      table_dir,
      "biv-rho12-bootstrap-intervals.csv"
    ),
    bootstrap_coverage_csv = file.path(
      table_dir,
      "biv-rho12-bootstrap-coverage.csv"
    ),
    interval_evidence_csv = file.path(
      table_dir,
      "biv-rho12-interval-evidence.csv"
    ),
    interval_diagnostics_csv = file.path(
      table_dir,
      "biv-rho12-interval-diagnostics.csv"
    ),
    interval_failures_csv = file.path(
      table_dir,
      "biv-rho12-interval-failures.csv"
    )
  )
  phase18_assert_biv_rho12_grid_overwrite(paths, overwrite)

  summary <- phase18_summarise_biv_rho12_smoke(
    conditions = conditions,
    n_rep = n_rep,
    master_seed = master_seed,
    result_dir = result_dir,
    overwrite = overwrite,
    profile_parameters = profile_parameters,
    profile_level = profile_level,
    profile_args = profile_args,
    bootstrap_nsim = bootstrap_nsim,
    bootstrap_level = bootstrap_level
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
    surface = "biv_rho12_grid",
    output_dir = output_dir,
    result_dir = result_dir,
    table_dir = table_dir,
    paths = paths,
    summary = summary
  )
}

phase18_assert_biv_rho12_grid_overwrite <- function(paths, overwrite) {
  path_values <- unlist(paths, use.names = FALSE)
  existing <- path_values[file.exists(path_values)]
  if (!overwrite && length(existing) > 0L) {
    stop(
      "Bivariate rho12 grid output already exists: ",
      paste(existing, collapse = ", "),
      call. = FALSE
    )
  }
  invisible(paths)
}
