phase18_write_first_wave_artifact_status <- function(
  output_dir,
  grid_outputs,
  overwrite = FALSE
) {
  if (
    !is.character(output_dir) || length(output_dir) != 1L || !nzchar(output_dir)
  ) {
    stop("`output_dir` must be one non-empty path string.", call. = FALSE)
  }
  if (!isTRUE(overwrite) && !identical(overwrite, FALSE)) {
    stop("`overwrite` must be TRUE or FALSE.", call. = FALSE)
  }
  if (!is.list(grid_outputs) || length(grid_outputs) == 0L) {
    stop(
      "`grid_outputs` must be a non-empty list of grid outputs or manifests.",
      call. = FALSE
    )
  }

  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  output_dir <- normalizePath(output_dir, mustWork = TRUE)
  paths <- list(
    artifact_manifest_csv = file.path(
      output_dir,
      "phase18-first-wave-artifact-manifest.csv"
    ),
    artifact_status_csv = file.path(
      output_dir,
      "phase18-first-wave-artifact-status.csv"
    )
  )
  phase18_assert_first_wave_artifact_status_overwrite(paths, overwrite)

  manifest <- phase18_bind_grid_artifact_manifests(grid_outputs)
  status <- phase18_summarise_grid_artifact_manifests(manifest)

  utils::write.csv(manifest, paths$artifact_manifest_csv, row.names = FALSE)
  utils::write.csv(status, paths$artifact_status_csv, row.names = FALSE)

  list(
    surface = "phase18_first_wave_artifact_status",
    output_dir = output_dir,
    paths = paths,
    artifact_manifest = phase18_grid_artifact_manifest(
      "phase18_first_wave_artifact_status",
      paths
    ),
    manifest = manifest,
    status = status
  )
}

phase18_assert_first_wave_artifact_status_overwrite <- function(
  paths,
  overwrite
) {
  path_values <- unlist(paths, use.names = FALSE)
  existing <- path_values[file.exists(path_values)]
  if (!overwrite && length(existing) > 0L) {
    stop(
      "Phase 18 first-wave artifact status output already exists: ",
      paste(existing, collapse = ", "),
      call. = FALSE
    )
  }
  invisible(paths)
}
