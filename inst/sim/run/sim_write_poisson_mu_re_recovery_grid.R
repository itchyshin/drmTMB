# Standalone recovery artifact lane for ordinary Poisson `mu` random effects.
#
# The smoke summary `phase18_summarise_poisson_mu_re_smoke()` already computes
# the full recovery contract (aggregate bias/RMSE/MCSE, Wald intervals and
# coverage, and profile intervals and coverage for the random-effect SD); it is
# only ever dispatched as part of the combined `first_wave_summary`. This writer
# gives the Poisson `mu` random-effect surface its own dispatchable, auditable
# artifact set at recovery-scale `n_rep`, matching the per-lane failure-ledger
# convention used by the bivariate Gaussian recovery lanes. It adds no new
# estimator; it reuses the existing recovery-capable summary.

phase18_write_poisson_mu_re_recovery_grid_outputs <- function(
  output_dir,
  conditions = phase18_poisson_mu_re_conditions(
    n_group = c(36L, 72L),
    n_per_group = 9L
  ),
  n_rep = 50L,
  master_seed = 20260632L,
  overwrite = FALSE,
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

  prefix <- "poisson-mu-re-recovery"
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
    profile_intervals_csv = file.path(
      table_dir,
      paste0(prefix, "-profile-intervals.csv")
    ),
    profile_coverage_csv = file.path(
      table_dir,
      paste0(prefix, "-profile-coverage.csv")
    )
  )
  phase18_assert_poisson_mu_re_recovery_grid_overwrite(paths, overwrite)

  summary <- phase18_summarise_poisson_mu_re_smoke(
    conditions = conditions,
    n_rep = n_rep,
    master_seed = master_seed,
    result_dir = result_dir,
    overwrite = overwrite,
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

  list(
    surface = "poisson_mu_re_recovery_grid",
    output_dir = output_dir,
    result_dir = result_dir,
    table_dir = table_dir,
    paths = paths,
    artifact_manifest = phase18_grid_artifact_manifest(
      "poisson_mu_re_recovery_grid",
      paths
    ),
    summary = summary
  )
}

phase18_assert_poisson_mu_re_recovery_grid_overwrite <- function(
  paths,
  overwrite
) {
  path_values <- unlist(paths, use.names = FALSE)
  existing <- path_values[file.exists(path_values)]
  if (!overwrite && length(existing) > 0L) {
    stop(
      "Poisson mu random-effect recovery grid output already exists: ",
      paste(existing, collapse = ", "),
      call. = FALSE
    )
  }
  invisible(paths)
}
