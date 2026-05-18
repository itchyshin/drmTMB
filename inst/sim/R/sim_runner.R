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
      warnings <<- c(warnings, conditionMessage(w))
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

phase18_result_path <- function(result_dir, cell_id, replicate) {
  if (
    !is.character(result_dir) || length(result_dir) != 1L || !nzchar(result_dir)
  ) {
    stop("`result_dir` must be one non-empty character string.", call. = FALSE)
  }
  safe_cell_id <- gsub("[^A-Za-z0-9_.-]+", "_", cell_id)
  file.path(result_dir, safe_cell_id, sprintf("replicate_%04d.rds", replicate))
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
