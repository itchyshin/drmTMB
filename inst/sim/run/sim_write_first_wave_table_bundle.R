phase18_first_wave_table_artifacts <- function() {
  c(
    "aggregate_csv",
    "replicate_csv",
    "manifest_csv",
    "failures_csv",
    "wald_intervals_csv",
    "wald_coverage_csv",
    "profile_intervals_csv",
    "profile_coverage_csv",
    "bootstrap_intervals_csv",
    "bootstrap_coverage_csv",
    "interval_evidence_csv",
    "interval_diagnostics_csv",
    "interval_failures_csv"
  )
}

phase18_write_first_wave_table_bundle <- function(
  output_dir,
  grid_outputs,
  artifacts = phase18_first_wave_table_artifacts(),
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
  phase18_assert_first_wave_grid_outputs(grid_outputs)
  phase18_assert_first_wave_artifacts(artifacts)

  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  output_dir <- normalizePath(output_dir, mustWork = TRUE)
  paths <- phase18_first_wave_table_bundle_paths(output_dir, artifacts)
  paths$artifact_grain_status_csv <- file.path(
    output_dir,
    "phase18-first-wave-artifact-grain-status.csv"
  )
  phase18_assert_first_wave_table_bundle_overwrite(paths, overwrite)

  tables <- lapply(
    artifacts,
    function(artifact) {
      phase18_collect_first_wave_table(
        grid_outputs = grid_outputs,
        artifact = artifact
      )
    }
  )
  names(tables) <- artifacts
  for (artifact in artifacts) {
    utils::write.csv(tables[[artifact]], paths[[artifact]], row.names = FALSE)
  }
  grain_status <- phase18_first_wave_artifact_grain_status(
    grid_outputs = grid_outputs,
    artifacts = artifacts
  )
  utils::write.csv(
    grain_status,
    paths$artifact_grain_status_csv,
    row.names = FALSE
  )

  list(
    surface = "phase18_first_wave_table_bundle",
    output_dir = output_dir,
    paths = paths,
    artifact_manifest = phase18_grid_artifact_manifest(
      "phase18_first_wave_table_bundle",
      paths
    ),
    tables = tables,
    grain_status = grain_status
  )
}

phase18_collect_first_wave_table <- function(grid_outputs, artifact) {
  phase18_assert_first_wave_grid_outputs(grid_outputs)
  phase18_assert_first_wave_artifacts(artifact)
  pieces <- list()
  index <- 0L
  for (grid_output in grid_outputs) {
    paths <- phase18_first_wave_grid_paths(grid_output)
    if (!artifact %in% names(paths) || !file.exists(paths[[artifact]])) {
      next
    }
    table <- phase18_read_first_wave_table(paths[[artifact]])
    if (nrow(table) == 0L) {
      next
    }
    index <- index + 1L
    table$source_surface <- phase18_first_wave_grid_surface(grid_output)
    table$source_artifact <- artifact
    pieces[[index]] <- table
  }
  if (length(pieces) == 0L) {
    return(data.frame(
      source_surface = character(),
      source_artifact = character(),
      stringsAsFactors = FALSE
    ))
  }
  phase18_row_bind_fill(pieces)
}

phase18_first_wave_artifact_grain_status <- function(
  grid_outputs,
  artifacts = phase18_first_wave_table_artifacts()
) {
  phase18_assert_first_wave_grid_outputs(grid_outputs)
  phase18_assert_first_wave_artifacts(artifacts)

  rows <- list()
  index <- 0L
  for (grid_output in grid_outputs) {
    paths <- phase18_first_wave_grid_paths(grid_output)
    surface <- phase18_first_wave_grid_surface(grid_output)
    for (artifact in artifacts) {
      index <- index + 1L
      path <- if (artifact %in% names(paths)) {
        paths[[artifact]]
      } else {
        NA_character_
      }
      rows[[index]] <- phase18_first_wave_artifact_grain_row(
        surface = surface,
        artifact = artifact,
        path = path
      )
    }
  }
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

phase18_first_wave_artifact_grain_row <- function(surface, artifact, path) {
  if (
    !is.character(path) ||
      length(path) != 1L ||
      is.na(path) ||
      !nzchar(path) ||
      !file.exists(path)
  ) {
    return(phase18_first_wave_artifact_grain_record(
      surface = surface,
      artifact = artifact,
      path = path,
      n_row = NA_integer_,
      artifact_grain = NA_character_,
      grain_status = "missing_artifact",
      plot_geometry = "not_available"
    ))
  }

  table <- phase18_read_first_wave_table(path)
  if (nrow(table) == 0L) {
    return(phase18_first_wave_artifact_grain_record(
      surface = surface,
      artifact = artifact,
      path = path,
      n_row = 0L,
      artifact_grain = NA_character_,
      grain_status = "empty_artifact",
      plot_geometry = "not_available"
    ))
  }
  if (!"artifact_grain" %in% names(table)) {
    return(phase18_first_wave_artifact_grain_record(
      surface = surface,
      artifact = artifact,
      path = path,
      n_row = nrow(table),
      artifact_grain = NA_character_,
      grain_status = "missing_grain",
      plot_geometry = "grain_audit_needed"
    ))
  }

  grain <- unique(as.character(table$artifact_grain))
  grain <- sort(grain[!is.na(grain) & nzchar(grain)])
  if (length(grain) == 0L) {
    return(phase18_first_wave_artifact_grain_record(
      surface = surface,
      artifact = artifact,
      path = path,
      n_row = nrow(table),
      artifact_grain = NA_character_,
      grain_status = "missing_grain",
      plot_geometry = "grain_audit_needed"
    ))
  }
  if (length(grain) > 1L) {
    return(phase18_first_wave_artifact_grain_record(
      surface = surface,
      artifact = artifact,
      path = path,
      n_row = nrow(table),
      artifact_grain = paste(grain, collapse = ";"),
      grain_status = "mixed_grain",
      plot_geometry = "grain_audit_needed"
    ))
  }

  grain_status <- switch(
    grain,
    replicate = "replicate_ready",
    aggregate = "aggregate_only",
    "supporting_table"
  )
  plot_geometry <- switch(
    grain,
    replicate = "replicate_clouds_allowed",
    aggregate = "aggregate_points_bars_mcse_only",
    "table_only"
  )

  phase18_first_wave_artifact_grain_record(
    surface = surface,
    artifact = artifact,
    path = path,
    n_row = nrow(table),
    artifact_grain = grain,
    grain_status = grain_status,
    plot_geometry = plot_geometry
  )
}

phase18_first_wave_artifact_grain_record <- function(
  surface,
  artifact,
  path,
  n_row,
  artifact_grain,
  grain_status,
  plot_geometry
) {
  replicate_cloud_allowed <- identical(
    plot_geometry,
    "replicate_clouds_allowed"
  )
  data.frame(
    source_surface = surface,
    source_artifact = artifact,
    path = path,
    n_row = n_row,
    artifact_grain = artifact_grain,
    grain_status = grain_status,
    plot_geometry = plot_geometry,
    replicate_cloud_allowed = replicate_cloud_allowed,
    stringsAsFactors = FALSE
  )
}

phase18_first_wave_table_bundle_paths <- function(output_dir, artifacts) {
  phase18_assert_first_wave_artifacts(artifacts)
  names <- sub("_csv$", "", artifacts)
  names <- gsub("_", "-", names, fixed = TRUE)
  paths <- file.path(output_dir, paste0("phase18-first-wave-", names, ".csv"))
  stats::setNames(as.list(paths), artifacts)
}

phase18_assert_first_wave_table_bundle_overwrite <- function(paths, overwrite) {
  path_values <- unlist(paths, use.names = FALSE)
  existing <- path_values[file.exists(path_values)]
  if (!overwrite && length(existing) > 0L) {
    stop(
      "Phase 18 first-wave table bundle output already exists: ",
      paste(existing, collapse = ", "),
      call. = FALSE
    )
  }
  invisible(paths)
}

phase18_assert_first_wave_grid_outputs <- function(grid_outputs) {
  if (!is.list(grid_outputs) || length(grid_outputs) == 0L) {
    stop("`grid_outputs` must be a non-empty list.", call. = FALSE)
  }
  invisible(grid_outputs)
}

phase18_assert_first_wave_artifacts <- function(artifacts) {
  if (
    !is.character(artifacts) ||
      length(artifacts) == 0L ||
      anyNA(artifacts) ||
      any(!nzchar(artifacts))
  ) {
    stop("`artifacts` must be a non-empty character vector.", call. = FALSE)
  }
  invisible(artifacts)
}

phase18_first_wave_grid_paths <- function(grid_output) {
  if (is.list(grid_output) && is.list(grid_output$paths)) {
    return(grid_output$paths)
  }
  stop(
    "Each grid output must contain a named `paths` list.",
    call. = FALSE
  )
}

phase18_first_wave_grid_surface <- function(grid_output) {
  if (
    is.list(grid_output) &&
      is.character(grid_output$surface) &&
      length(grid_output$surface) == 1L &&
      nzchar(grid_output$surface)
  ) {
    return(grid_output$surface)
  }
  "unknown_surface"
}

phase18_read_first_wave_table <- function(path) {
  tryCatch(
    utils::read.csv(path),
    error = function(e) {
      data.frame(stringsAsFactors = FALSE)
    }
  )
}

phase18_row_bind_fill <- function(pieces) {
  pieces <- Filter(function(x) is.data.frame(x) && nrow(x) > 0L, pieces)
  if (length(pieces) == 0L) {
    return(data.frame())
  }
  all_names <- unique(unlist(lapply(pieces, names), use.names = FALSE))
  aligned <- lapply(pieces, function(x) {
    missing <- setdiff(all_names, names(x))
    for (name in missing) {
      x[[name]] <- NA
    }
    x[all_names]
  })
  out <- do.call(rbind, aligned)
  front <- intersect(c("source_surface", "source_artifact"), names(out))
  out <- out[c(front, setdiff(names(out), front))]
  row.names(out) <- NULL
  out
}
