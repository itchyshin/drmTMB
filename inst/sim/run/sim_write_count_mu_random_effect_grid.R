phase18_write_count_mu_re_grid_outputs <- function(
  output_dir,
  poisson_conditions = phase18_poisson_mu_re_conditions(
    n_group = c(36L, 48L),
    n_per_group = 9L
  ),
  nbinom2_conditions = phase18_nbinom2_mu_re_conditions(
    n_group = c(44L, 56L),
    n_per_group = 10L
  ),
  n_rep = 5L,
  master_seed = 20260529L,
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

  paths <- list(
    aggregate_csv = file.path(table_dir, "count-mu-re-aggregate.csv"),
    replicate_csv = file.path(table_dir, "count-mu-re-replicates.csv"),
    manifest_csv = file.path(table_dir, "count-mu-re-manifest.csv"),
    failures_csv = file.path(table_dir, "count-mu-re-failures.csv"),
    wald_intervals_csv = file.path(
      table_dir,
      "count-mu-re-wald-intervals.csv"
    ),
    wald_coverage_csv = file.path(table_dir, "count-mu-re-wald-coverage.csv"),
    profile_intervals_csv = file.path(
      table_dir,
      "count-mu-re-profile-intervals.csv"
    ),
    profile_coverage_csv = file.path(
      table_dir,
      "count-mu-re-profile-coverage.csv"
    )
  )
  phase18_assert_count_mu_re_grid_overwrite(paths, overwrite)

  summary <- phase18_summarise_count_mu_re_pilot(
    poisson_conditions = poisson_conditions,
    nbinom2_conditions = nbinom2_conditions,
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
    surface = "count_mu_random_effect_grid",
    output_dir = output_dir,
    result_dir = result_dir,
    table_dir = table_dir,
    paths = paths,
    artifact_manifest = phase18_grid_artifact_manifest(
      "count_mu_random_effect_grid",
      paths
    ),
    summary = summary
  )
}

phase18_assert_count_mu_re_grid_overwrite <- function(paths, overwrite) {
  path_values <- unlist(paths, use.names = FALSE)
  existing <- path_values[file.exists(path_values)]
  if (!overwrite && length(existing) > 0L) {
    stop(
      "Count mu random-effect grid output already exists: ",
      paste(existing, collapse = ", "),
      call. = FALSE
    )
  }
  invisible(paths)
}
