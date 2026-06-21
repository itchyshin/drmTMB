phase18_write_model_selection_smoke_outputs <- function(
    output_dir,
    conditions = phase18_model_selection_conditions(),
    n_rep = 2L,
    master_seed = 20260609L,
    overwrite = FALSE,
    cores = 1L,
    backend = "none",
    save_results = TRUE) {
  if (
    !is.character(output_dir) || length(output_dir) != 1L || !nzchar(output_dir)
  ) {
    stop("`output_dir` must be one non-empty path string.", call. = FALSE)
  }
  if (!isTRUE(overwrite) && !identical(overwrite, FALSE)) {
    stop("`overwrite` must be TRUE or FALSE.", call. = FALSE)
  }
  if (!isTRUE(save_results) && !identical(save_results, FALSE)) {
    stop("`save_results` must be TRUE or FALSE.", call. = FALSE)
  }

  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  output_dir <- normalizePath(output_dir, mustWork = TRUE)
  table_dir <- file.path(output_dir, "tables")
  result_dir <- if (isTRUE(save_results)) {
    file.path(output_dir, "results")
  } else {
    NULL
  }
  if (!is.null(result_dir)) {
    dir.create(result_dir, recursive = TRUE, showWarnings = FALSE)
  }
  dir.create(table_dir, recursive = TRUE, showWarnings = FALSE)

  paths <- list(
    candidates_csv = file.path(table_dir, "model-selection-candidates.csv"),
    selection_summary_csv = file.path(
      table_dir,
      "model-selection-summary.csv"
    ),
    manifest_csv = file.path(table_dir, "model-selection-manifest.csv"),
    failures_csv = file.path(table_dir, "model-selection-failures.csv")
  )
  phase18_assert_model_selection_overwrite(paths, overwrite)

  run <- phase18_run_model_selection_smoke(
    conditions = conditions,
    n_rep = n_rep,
    master_seed = master_seed,
    result_dir = result_dir,
    overwrite = overwrite,
    cores = cores,
    backend = backend
  )
  selection_summary <- phase18_summarise_model_selection_choices(run$summary)
  manifest <- phase18_result_manifest(run$results)
  failures <- phase18_result_failures(run$results)

  utils::write.csv(run$summary, paths$candidates_csv, row.names = FALSE)
  utils::write.csv(
    selection_summary,
    paths$selection_summary_csv,
    row.names = FALSE
  )
  utils::write.csv(manifest, paths$manifest_csv, row.names = FALSE)
  utils::write.csv(failures, paths$failures_csv, row.names = FALSE)

  list(
    surface = "model_selection_smoke",
    output_dir = output_dir,
    result_dir = result_dir,
    table_dir = table_dir,
    paths = paths,
    artifact_manifest = phase18_grid_artifact_manifest(
      "model_selection_smoke",
      paths
    ),
    candidates = run$summary,
    selection_summary = selection_summary,
    manifest = manifest,
    failures = failures,
    run = run
  )
}

phase18_assert_model_selection_overwrite <- function(paths, overwrite) {
  path_values <- unlist(paths, use.names = FALSE)
  existing <- path_values[file.exists(path_values)]
  if (!overwrite && length(existing) > 0L) {
    stop(
      "Model-selection smoke output already exists: ",
      paste(existing, collapse = ", "),
      call. = FALSE
    )
  }
  invisible(paths)
}
