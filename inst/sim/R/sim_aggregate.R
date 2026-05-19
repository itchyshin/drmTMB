phase18_aggregate_parameters <- function(summary, by = NULL) {
  if (!is.data.frame(summary) || nrow(summary) == 0L) {
    stop("`summary` must be a non-empty data frame.", call. = FALSE)
  }
  required <- c(
    "parameter",
    "truth",
    "estimate",
    "error",
    "converged",
    "pdHess",
    "elapsed",
    "warning_count"
  )
  missing <- setdiff(required, names(summary))
  if (length(missing) > 0L) {
    stop(
      "`summary` must contain ",
      paste(missing, collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  if (is.null(by)) {
    by <- intersect(
      c("surface", "known_v_type", "cell_id", "parameter"),
      names(summary)
    )
  }
  if (!is.character(by) || length(by) == 0L || any(!nzchar(by))) {
    stop("`by` must be a non-empty character vector.", call. = FALSE)
  }
  if (!all(by %in% names(summary))) {
    stop("Every `by` column must exist in `summary`.", call. = FALSE)
  }

  split_key <- interaction(summary[by], drop = TRUE, lex.order = TRUE)
  pieces <- split(summary, split_key)
  rows <- lapply(pieces, phase18_aggregate_parameter_group, by = by)
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

phase18_aggregate_parameter_group <- function(x, by) {
  error <- as.numeric(x$error)
  estimate <- as.numeric(x$estimate)
  truth <- as.numeric(x$truth)
  elapsed <- as.numeric(x$elapsed)
  warning_count <- as.numeric(x$warning_count)

  data.frame(
    x[1L, by, drop = FALSE],
    n_replicate = length(error),
    artifact_grain = "aggregate",
    mean_truth = mean(truth),
    mean_estimate = mean(estimate),
    bias = mean(error),
    rmse = sqrt(mean(error^2)),
    mean_abs_error = mean(abs(error)),
    empirical_se = stats::sd(estimate),
    convergence_rate = mean(as.logical(x$converged)),
    pdHess_rate = mean(as.logical(x$pdHess)),
    warning_rate = mean(warning_count > 0),
    mean_elapsed = mean(elapsed),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}
