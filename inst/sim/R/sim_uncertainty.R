phase18_mcse_mean <- function(x) {
  x <- phase18_finite_numeric_vector(x, "x")
  if (length(x) < 2L) {
    return(NA_real_)
  }
  stats::sd(x) / sqrt(length(x))
}

phase18_mcse_proportion <- function(x) {
  if (!is.logical(x) || length(x) == 0L || anyNA(x)) {
    stop(
      "`x` must be a non-empty logical vector without missing values.",
      call. = FALSE
    )
  }
  p <- mean(x)
  sqrt(p * (1 - p) / length(x))
}

phase18_mcse_rmse <- function(error) {
  error <- phase18_finite_numeric_vector(error, "error")
  if (length(error) < 2L) {
    return(NA_real_)
  }
  squared_error <- error^2
  rmse <- sqrt(mean(squared_error))
  if (identical(rmse, 0)) {
    return(0)
  }
  stats::sd(squared_error) / sqrt(length(error)) / (2 * rmse)
}

phase18_aggregate_error_mcse <- function(summary, by = NULL) {
  phase18_assert_summary_columns(summary, c("parameter", "error"))
  if (is.null(by)) {
    by <- phase18_default_summary_groups(summary)
  }
  phase18_assert_group_columns(summary, by)

  split_key <- interaction(summary[by], drop = TRUE, lex.order = TRUE)
  pieces <- split(summary, split_key)
  rows <- lapply(pieces, function(x) {
    error <- as.numeric(x$error)
    data.frame(
      x[1L, by, drop = FALSE],
      n_replicate = length(error),
      bias_mcse = phase18_mcse_mean(error),
      rmse_mcse = phase18_mcse_rmse(error),
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  })
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

phase18_summarise_interval_coverage <- function(
  summary,
  by = NULL,
  lower = "conf.low",
  upper = "conf.high"
) {
  phase18_assert_summary_columns(summary, c("parameter", "truth", lower, upper))
  if (is.null(by)) {
    by <- phase18_default_summary_groups(summary)
  }
  phase18_assert_group_columns(summary, by)

  split_key <- interaction(summary[by], drop = TRUE, lex.order = TRUE)
  pieces <- split(summary, split_key)
  rows <- lapply(pieces, function(x) {
    lower_value <- as.numeric(x[[lower]])
    upper_value <- as.numeric(x[[upper]])
    truth <- as.numeric(x$truth)
    finite_interval <- is.finite(lower_value) & is.finite(upper_value)
    covered <- finite_interval & lower_value <= truth & truth <= upper_value
    width <- upper_value[finite_interval] - lower_value[finite_interval]

    data.frame(
      x[1L, by, drop = FALSE],
      n_replicate = nrow(x),
      n_interval = sum(finite_interval),
      coverage = mean(covered),
      coverage_mcse = phase18_mcse_proportion(covered),
      mean_interval_width = if (length(width) == 0L) NA_real_ else mean(width),
      interval_width_mcse = phase18_mcse_mean(width),
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  })
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

phase18_default_summary_groups <- function(summary) {
  intersect(
    c("surface", "known_v_type", "cell_id", "parameter"),
    names(summary)
  )
}

phase18_assert_summary_columns <- function(summary, required) {
  if (!is.data.frame(summary) || nrow(summary) == 0L) {
    stop("`summary` must be a non-empty data frame.", call. = FALSE)
  }
  missing <- setdiff(required, names(summary))
  if (length(missing) > 0L) {
    stop(
      "`summary` must contain ",
      paste(missing, collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  invisible(summary)
}

phase18_assert_group_columns <- function(summary, by) {
  if (!is.character(by) || length(by) == 0L || any(!nzchar(by))) {
    stop("`by` must be a non-empty character vector.", call. = FALSE)
  }
  if (!all(by %in% names(summary))) {
    stop("Every `by` column must exist in `summary`.", call. = FALSE)
  }
  invisible(by)
}

phase18_finite_numeric_vector <- function(x, name) {
  if (!is.numeric(x) || length(x) == 0L || any(!is.finite(x))) {
    stop(
      "`",
      name,
      "` must be a non-empty finite numeric vector.",
      call. = FALSE
    )
  }
  x
}
