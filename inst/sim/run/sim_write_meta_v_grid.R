phase18_write_meta_v_grid_outputs <- function(
  output_dir,
  conditions = phase18_meta_v_conditions(
    n_study = c(36L, 72L),
    known_v_type = c("vector", "dense"),
    sigma = c(0.15, 0.35),
    sampling_sd = 0.14,
    sampling_rho = c(0, 0.20)
  ),
  n_rep = 5L,
  master_seed = 20260528L,
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
    aggregate_csv = file.path(table_dir, "meta-v-aggregate.csv"),
    replicate_csv = file.path(table_dir, "meta-v-replicates.csv"),
    manifest_csv = file.path(table_dir, "meta-v-manifest.csv"),
    failures_csv = file.path(table_dir, "meta-v-failures.csv"),
    wald_intervals_csv = file.path(table_dir, "meta-v-wald-intervals.csv"),
    wald_coverage_csv = file.path(table_dir, "meta-v-wald-coverage.csv")
  )
  phase18_assert_meta_v_grid_overwrite(paths, overwrite)

  summary <- phase18_summarise_meta_v_smoke(
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

  list(
    surface = "meta_v_grid",
    output_dir = output_dir,
    result_dir = result_dir,
    table_dir = table_dir,
    paths = paths,
    artifact_manifest = phase18_grid_artifact_manifest("meta_v_grid", paths),
    summary = summary
  )
}

phase18_assert_meta_v_grid_overwrite <- function(paths, overwrite) {
  path_values <- unlist(paths, use.names = FALSE)
  existing <- path_values[file.exists(path_values)]
  if (!overwrite && length(existing) > 0L) {
    stop(
      "meta_V grid output already exists: ",
      paste(existing, collapse = ", "),
      call. = FALSE
    )
  }
  invisible(paths)
}
