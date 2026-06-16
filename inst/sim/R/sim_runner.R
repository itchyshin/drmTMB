phase18_run_replicate <- function(
  cell,
  seed_row,
  dgp_fun,
  fit_fun,
  summarise_fun,
  result_dir = NULL,
  overwrite = FALSE
) {
  phase18_assert_one_row_data_frame(cell, "cell")
  phase18_assert_one_row_data_frame(seed_row, "seed_row")
  phase18_assert_function(dgp_fun, "dgp_fun")
  phase18_assert_function(fit_fun, "fit_fun")
  phase18_assert_function(summarise_fun, "summarise_fun")

  cell_id <- phase18_extract_id(cell, "cell")
  seed_cell_id <- phase18_extract_id(seed_row, "seed_row")
  if (!identical(cell_id, seed_cell_id)) {
    stop(
      "`cell` and `seed_row` must refer to the same `cell_id`.",
      call. = FALSE
    )
  }
  replicate <- seed_row$replicate[[1L]]
  seed <- seed_row$seed[[1L]]
  assert_positive_whole_number(replicate, "replicate")
  assert_positive_whole_number(seed, "seed")

  result_path <- NULL
  if (!is.null(result_dir)) {
    result_path <- phase18_result_path(result_dir, cell_id, replicate)
    if (file.exists(result_path) && !overwrite) {
      result <- readRDS(result_path)
      result$skipped <- TRUE
      return(result)
    }
  }

  warnings <- character()
  data <- NULL
  fit <- NULL
  summary <- NULL
  status <- "ok"
  error <- NULL
  started <- proc.time()[["elapsed"]]

  withCallingHandlers(
    tryCatch(
      {
        data <- dgp_fun(
          cell = cell,
          seed = seed,
          cell_id = cell_id,
          replicate = replicate
        )
        fit <- fit_fun(data = data, cell = cell)
        summary <- summarise_fun(
          fit = fit,
          truth = data,
          cell_id = cell_id,
          replicate = replicate,
          elapsed = proc.time()[["elapsed"]] - started,
          warnings = warnings
        )
      },
      error = function(e) {
        status <<- "error"
        error <<- conditionMessage(e)
      }
    ),
    warning = function(w) {
      # The drmTMB convergence and clamp-active warnings are informational: the
      # simulation summary already tracks per-fit convergence, pdHess, and scale
      # state, so capturing them here would double-count them as ledger failures.
      # Record every other warning.
      own <- c("drmTMB_convergence_warning", "drmTMB_clamp_active_warning")
      if (!inherits(w, own)) {
        warnings <<- c(warnings, conditionMessage(w))
      }
      invokeRestart("muffleWarning")
    }
  )

  result <- list(
    cell_id = cell_id,
    replicate = replicate,
    seed = seed,
    status = status,
    summary = summary,
    warnings = warnings,
    error = error,
    elapsed = proc.time()[["elapsed"]] - started,
    skipped = FALSE,
    session = utils::sessionInfo()
  )

  if (!is.null(result_path)) {
    dir.create(dirname(result_path), recursive = TRUE, showWarnings = FALSE)
    saveRDS(result, result_path)
  }
  result
}

phase18_run_replicates <- function(
  cells,
  seeds,
  dgp_fun,
  fit_fun,
  summarise_fun = NULL,
  summarise_fun_factory = NULL,
  result_dir = NULL,
  overwrite = FALSE,
  cores = 1L,
  backend = "none"
) {
  if (!is.data.frame(cells) || nrow(cells) == 0L) {
    stop("`cells` must be a non-empty data frame.", call. = FALSE)
  }
  if (!is.data.frame(seeds) || nrow(seeds) == 0L) {
    stop("`seeds` must be a non-empty data frame.", call. = FALSE)
  }
  missing_seed <- setdiff(
    c("cell_id", "cell_index", "replicate", "seed"),
    names(seeds)
  )
  if (length(missing_seed) > 0L) {
    stop(
      "`seeds` must contain ",
      paste(missing_seed, collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  phase18_assert_function(dgp_fun, "dgp_fun")
  phase18_assert_function(fit_fun, "fit_fun")
  if (is.null(summarise_fun_factory)) {
    phase18_assert_function(summarise_fun, "summarise_fun")
  } else {
    phase18_assert_function(summarise_fun_factory, "summarise_fun_factory")
  }
  plan <- phase18_runner_parallel_plan(
    n_task = nrow(seeds),
    cores = cores,
    backend = backend
  )

  worker <- function(i) {
    seed_row <- seeds[i, , drop = FALSE]
    cell_index <- seed_row$cell_index[[1L]]
    assert_positive_whole_number(cell_index, "cell_index")
    if (cell_index > nrow(cells)) {
      stop(
        "`seeds$cell_index` must refer to a row in `cells`.",
        call. = FALSE
      )
    }
    cell <- cells[cell_index, , drop = FALSE]
    replicate_summarise_fun <- phase18_runner_summarise_fun(
      summarise_fun = summarise_fun,
      summarise_fun_factory = summarise_fun_factory,
      cell = cell,
      seed_row = seed_row
    )
    phase18_run_replicate(
      cell = cell,
      seed_row = seed_row,
      dgp_fun = dgp_fun,
      fit_fun = fit_fun,
      summarise_fun = replicate_summarise_fun,
      result_dir = result_dir,
      overwrite = overwrite
    )
  }
  results <- phase18_runner_lapply(seq_len(nrow(seeds)), worker, plan)
  names(results) <- paste(
    seeds$cell_id,
    sprintf("rep%04d", seeds$replicate),
    sep = ":"
  )
  attr(results, "phase18_parallel") <- plan
  results
}

phase18_runner_summarise_fun <- function(
  summarise_fun,
  summarise_fun_factory,
  cell,
  seed_row
) {
  if (is.null(summarise_fun_factory)) {
    return(summarise_fun)
  }
  out <- summarise_fun_factory(
    cell = cell,
    seed_row = seed_row
  )
  phase18_assert_function(out, "summarise_fun_factory()")
  out
}

phase18_result_path <- function(result_dir, cell_id, replicate) {
  if (
    !is.character(result_dir) || length(result_dir) != 1L || !nzchar(result_dir)
  ) {
    stop("`result_dir` must be one non-empty character string.", call. = FALSE)
  }
  safe_cell_id <- gsub("[^A-Za-z0-9_.-]+", "_", cell_id)
  file.path(result_dir, safe_cell_id, sprintf("replicate_%04d.rds", replicate))
}

phase18_read_result_dir <- function(result_dir, pattern = "[.]rds$") {
  if (
    !is.character(result_dir) || length(result_dir) != 1L || !nzchar(result_dir)
  ) {
    stop("`result_dir` must be one non-empty character string.", call. = FALSE)
  }
  if (!dir.exists(result_dir)) {
    stop("`result_dir` must be an existing directory.", call. = FALSE)
  }
  if (!is.character(pattern) || length(pattern) != 1L || !nzchar(pattern)) {
    stop("`pattern` must be one non-empty character string.", call. = FALSE)
  }

  paths <- sort(list.files(
    result_dir,
    pattern = pattern,
    recursive = TRUE,
    full.names = TRUE
  ))
  if (length(paths) == 0L) {
    stop("`result_dir` does not contain any result files.", call. = FALSE)
  }

  results <- lapply(paths, phase18_read_result_file)
  names(results) <- paths
  results
}

phase18_read_result_file <- function(path) {
  result <- tryCatch(
    readRDS(path),
    error = function(e) {
      stop(
        "`",
        path,
        "` could not be read as an RDS result: ",
        conditionMessage(e),
        call. = FALSE
      )
    }
  )
  tryCatch(
    phase18_manifest_row(result),
    error = function(e) {
      stop(
        "`",
        path,
        "` is not a valid Phase 18 replicate result: ",
        conditionMessage(e),
        call. = FALSE
      )
    }
  )
  result$source_path <- path
  result
}

phase18_result_summaries <- function(
  results,
  artifact_grain = "replicate"
) {
  if (!is.list(results) || length(results) == 0L) {
    stop(
      "`results` must be a non-empty list of replicate results.",
      call. = FALSE
    )
  }
  if (
    !is.character(artifact_grain) ||
      length(artifact_grain) != 1L ||
      !nzchar(artifact_grain)
  ) {
    stop("`artifact_grain` must be one non-empty string.", call. = FALSE)
  }

  summaries <- lapply(results, function(result) result$summary)
  summaries <- Filter(
    function(x) is.data.frame(x) && nrow(x) > 0L,
    summaries
  )
  if (length(summaries) == 0L) {
    return(data.frame())
  }
  out <- do.call(rbind, summaries)
  row.names(out) <- NULL
  if (!"artifact_grain" %in% names(out)) {
    out$artifact_grain <- artifact_grain
  }
  out
}

phase18_assert_one_row_data_frame <- function(x, name) {
  if (!is.data.frame(x) || nrow(x) != 1L) {
    stop("`", name, "` must be a one-row data frame.", call. = FALSE)
  }
  invisible(x)
}

phase18_assert_function <- function(x, name) {
  if (!is.function(x)) {
    stop("`", name, "` must be a function.", call. = FALSE)
  }
  invisible(x)
}

phase18_extract_id <- function(x, name) {
  if (!"cell_id" %in% names(x)) {
    stop("`", name, "` must contain a `cell_id` column.", call. = FALSE)
  }
  cell_id <- x$cell_id[[1L]]
  if (!is.character(cell_id) || length(cell_id) != 1L || !nzchar(cell_id)) {
    stop(
      "`",
      name,
      "$cell_id` must be one non-empty character string.",
      call. = FALSE
    )
  }
  cell_id
}

phase18_result_manifest <- function(results) {
  if (!is.list(results) || length(results) == 0L) {
    stop(
      "`results` must be a non-empty list of replicate results.",
      call. = FALSE
    )
  }
  rows <- lapply(results, phase18_manifest_row)
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

phase18_manifest_row <- function(result) {
  required <- c("cell_id", "replicate", "seed", "status", "warnings", "elapsed")
  missing <- setdiff(required, names(result))
  if (length(missing) > 0L) {
    stop(
      "Each result must contain ",
      paste(missing, collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  data.frame(
    cell_id = result$cell_id,
    replicate = result$replicate,
    seed = result$seed,
    status = result$status,
    skipped = isTRUE(result$skipped),
    warning_count = length(result$warnings),
    error = if (is.null(result$error)) NA_character_ else result$error,
    elapsed = result$elapsed,
    stringsAsFactors = FALSE
  )
}

phase18_result_failures <- function(results) {
  manifest <- phase18_result_manifest(results)
  rows <- list()
  index <- 0L
  for (i in seq_along(results)) {
    result <- results[[i]]
    if (!identical(result$status, "ok")) {
      index <- index + 1L
      rows[[index]] <- phase18_failure_row(
        result,
        severity = "error",
        message = if (is.null(result$error)) NA_character_ else result$error
      )
    }
    for (warning in unique(result$warnings)) {
      index <- index + 1L
      rows[[index]] <- phase18_failure_row(
        result,
        severity = "warning",
        message = warning
      )
    }
  }
  if (length(rows) == 0L) {
    return(data.frame(
      cell_id = character(),
      replicate = integer(),
      seed = integer(),
      status = character(),
      severity = character(),
      message = character(),
      skipped = logical(),
      stringsAsFactors = FALSE
    ))
  }
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

phase18_failure_row <- function(result, severity, message) {
  data.frame(
    cell_id = result$cell_id,
    replicate = result$replicate,
    seed = result$seed,
    status = result$status,
    severity = severity,
    message = message,
    skipped = isTRUE(result$skipped),
    stringsAsFactors = FALSE
  )
}

phase18_runner_parallel_plan <- function(
  n_task,
  cores = 1L,
  backend = "none"
) {
  assert_positive_whole_number(n_task, "n_task")
  assert_positive_whole_number(cores, "cores")
  if (
    !is.character(backend) ||
      length(backend) != 1L ||
      !nzchar(backend)
  ) {
    stop("`backend` must be one non-empty character string.", call. = FALSE)
  }
  if (!backend %in% c("none", "multicore")) {
    stop(
      "`backend` must be either \"none\" or \"multicore\".",
      call. = FALSE
    )
  }
  if (identical(backend, "multicore") && .Platform$OS.type == "windows") {
    stop(
      "`backend = \"multicore\"` is not available on Windows.",
      call. = FALSE
    )
  }

  requested_cores <- as.integer(cores)
  actual_cores <- if (identical(backend, "none")) {
    1L
  } else {
    min(10L, as.integer(n_task), requested_cores)
  }
  list(
    backend = backend,
    requested_cores = requested_cores,
    cores = actual_cores
  )
}

phase18_runner_lapply <- function(indices, worker, plan) {
  if (identical(plan$backend, "none") || identical(plan$cores, 1L)) {
    return(lapply(indices, worker))
  }
  parallel::mclapply(indices, worker, mc.cores = plan$cores)
}

phase18_assert_no_nested_parallel <- function(outer_plan, inner_plan) {
  if (
    is.list(outer_plan) &&
      is.list(inner_plan) &&
      !is.null(outer_plan$cores) &&
      !is.null(inner_plan$cores) &&
      outer_plan$cores > 1L &&
      inner_plan$cores > 1L
  ) {
    stop(
      "Parallelize either the replicate layer or the bootstrap layer, not both.",
      call. = FALSE
    )
  }
  invisible(TRUE)
}

phase18_assert_simple_grid_output_dir <- function(output_dir) {
  if (
    !is.character(output_dir) || length(output_dir) != 1L || !nzchar(output_dir)
  ) {
    stop("`output_dir` must be one non-empty path string.", call. = FALSE)
  }
  invisible(output_dir)
}

phase18_prepare_simple_grid_dirs <- function(output_dir) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  output_dir <- normalizePath(output_dir, mustWork = TRUE)
  result_dir <- file.path(output_dir, "results")
  table_dir <- file.path(output_dir, "tables")
  dir.create(result_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(table_dir, recursive = TRUE, showWarnings = FALSE)
  list(output_dir = output_dir, result_dir = result_dir, table_dir = table_dir)
}

phase18_simple_grid_paths <- function(table_dir, prefix) {
  list(
    aggregate_csv = file.path(table_dir, paste0(prefix, "-aggregate.csv")),
    replicate_csv = file.path(table_dir, paste0(prefix, "-replicates.csv")),
    manifest_csv = file.path(table_dir, paste0(prefix, "-manifest.csv")),
    failures_csv = file.path(table_dir, paste0(prefix, "-failures.csv"))
  )
}

phase18_assert_simple_grid_overwrite <- function(paths, overwrite, label) {
  path_values <- unlist(paths, use.names = FALSE)
  existing <- path_values[file.exists(path_values)]
  if (!overwrite && length(existing) > 0L) {
    stop(
      label,
      " output already exists: ",
      paste(existing, collapse = ", "),
      call. = FALSE
    )
  }
  invisible(paths)
}

phase18_write_simple_grid_tables <- function(summary, paths) {
  utils::write.csv(summary$aggregate, paths$aggregate_csv, row.names = FALSE)
  utils::write.csv(summary$replicates, paths$replicate_csv, row.names = FALSE)
  utils::write.csv(summary$manifest, paths$manifest_csv, row.names = FALSE)
  utils::write.csv(summary$failures, paths$failures_csv, row.names = FALSE)
  invisible(paths)
}

phase18_grid_artifact_manifest <- function(surface, paths) {
  if (!is.character(surface) || length(surface) != 1L || !nzchar(surface)) {
    stop("`surface` must be one non-empty character string.", call. = FALSE)
  }
  if (!is.list(paths) || length(paths) == 0L || is.null(names(paths))) {
    stop("`paths` must be a named list of artifact paths.", call. = FALSE)
  }
  rows <- lapply(names(paths), function(artifact) {
    path <- paths[[artifact]]
    if (!is.character(path) || length(path) != 1L || !nzchar(path)) {
      stop("Each artifact path must be one non-empty string.", call. = FALSE)
    }
    exists <- file.exists(path)
    n_row <- NA_integer_
    if (exists && grepl("[.]csv$", path)) {
      n_row <- tryCatch(
        nrow(utils::read.csv(path)),
        error = function(e) 0L
      )
    }
    data.frame(
      surface = surface,
      artifact = artifact,
      path = path,
      exists = exists,
      n_row = n_row,
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

phase18_bind_grid_artifact_manifests <- function(...) {
  pieces <- list(...)
  if (
    length(pieces) == 1L &&
      is.list(pieces[[1L]]) &&
      !is.data.frame(pieces[[1L]])
  ) {
    pieces <- pieces[[1L]]
  }
  pieces <- lapply(pieces, phase18_extract_grid_artifact_manifest)
  pieces <- Filter(function(x) is.data.frame(x) && nrow(x) > 0L, pieces)
  if (length(pieces) == 0L) {
    return(data.frame())
  }
  required <- c("surface", "artifact", "path", "exists", "n_row")
  for (piece in pieces) {
    missing <- setdiff(required, names(piece))
    if (length(missing) > 0L) {
      stop(
        "`artifact_manifest` is missing ",
        paste(missing, collapse = ", "),
        ".",
        call. = FALSE
      )
    }
  }
  out <- do.call(rbind, pieces)
  out$artifact_grain <- "grid_artifact_manifest"
  row.names(out) <- NULL
  out
}

phase18_extract_grid_artifact_manifest <- function(x) {
  if (is.data.frame(x)) {
    return(x)
  }
  if (is.list(x) && is.data.frame(x$artifact_manifest)) {
    return(x$artifact_manifest)
  }
  stop(
    "Each input must be an artifact manifest data frame or a grid-writer result.",
    call. = FALSE
  )
}

phase18_summarise_grid_artifact_manifests <- function(manifest) {
  required <- c("surface", "artifact", "exists", "n_row")
  missing <- setdiff(required, names(manifest))
  if (length(missing) > 0L) {
    stop(
      "`manifest` is missing ",
      paste(missing, collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  if (nrow(manifest) == 0L) {
    return(data.frame())
  }
  pieces <- split(manifest, manifest$surface)
  rows <- lapply(pieces, function(x) {
    data.frame(
      surface = x$surface[[1L]],
      n_artifact = nrow(x),
      n_present = sum(x$exists),
      n_missing = sum(!x$exists),
      n_empty_csv = sum(x$exists & !is.na(x$n_row) & x$n_row == 0L),
      n_total_csv_rows = sum(x$n_row, na.rm = TRUE),
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  out$artifact_grain <- "grid_artifact_status"
  row.names(out) <- NULL
  out
}
