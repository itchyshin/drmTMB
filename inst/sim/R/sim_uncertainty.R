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

phase18_add_wald_intervals <- function(
  summary,
  conf.level = 0.95,
  estimate = "estimate",
  std.error = "std.error",
  lower = "conf.low",
  upper = "conf.high",
  interval_scale = "public"
) {
  phase18_assert_summary_columns(summary, c("parameter", estimate, std.error))
  if (
    !is.numeric(conf.level) ||
      length(conf.level) != 1L ||
      !is.finite(conf.level) ||
      conf.level <= 0 ||
      conf.level >= 1
  ) {
    stop("`conf.level` must be one number between 0 and 1.", call. = FALSE)
  }
  if (
    !is.character(interval_scale) ||
      !(length(interval_scale) %in% c(1L, nrow(summary))) ||
      any(!nzchar(interval_scale))
  ) {
    stop(
      "`interval_scale` must be one non-empty string or one value per row.",
      call. = FALSE
    )
  }
  phase18_assert_interval_column_names(lower, upper)
  interval_scale <- rep(interval_scale, length.out = nrow(summary))

  estimate_value <- as.numeric(summary[[estimate]])
  se_value <- as.numeric(summary[[std.error]])
  ok <- is.finite(estimate_value) & is.finite(se_value) & se_value >= 0
  z <- stats::qnorm(1 - (1 - conf.level) / 2)

  out <- summary
  out[[lower]] <- NA_real_
  out[[upper]] <- NA_real_
  out[[lower]][ok] <- estimate_value[ok] - z * se_value[ok]
  out[[upper]][ok] <- estimate_value[ok] + z * se_value[ok]
  out$conf.level <- conf.level
  out$interval_method <- "wald"
  out$interval_scale <- interval_scale
  out$interval_status <- ifelse(ok, "ok", "failed")
  out$interval_message <- ifelse(
    ok,
    "",
    "missing or invalid estimate/std.error"
  )
  out
}

phase18_add_correlation_fisher_z_intervals <- function(
  summary,
  conf.level = 0.95,
  estimate = "estimate",
  std.error = "std.error",
  std.error.scale = c("rho", "fisher_z"),
  lower = "conf.low",
  upper = "conf.high"
) {
  std.error.scale <- match.arg(std.error.scale)
  phase18_assert_summary_columns(summary, c("parameter", estimate, std.error))
  if (
    !is.numeric(conf.level) ||
      length(conf.level) != 1L ||
      !is.finite(conf.level) ||
      conf.level <= 0 ||
      conf.level >= 1
  ) {
    stop("`conf.level` must be one number between 0 and 1.", call. = FALSE)
  }
  phase18_assert_interval_column_names(lower, upper)

  rho <- as.numeric(summary[[estimate]])
  se <- as.numeric(summary[[std.error]])
  ok <- is.finite(rho) & abs(rho) < 1 & is.finite(se) & se >= 0
  se_z <- rep(NA_real_, length(rho))
  if (identical(std.error.scale, "rho")) {
    se_z[ok] <- se[ok] / (1 - rho[ok]^2)
  } else {
    se_z[ok] <- se[ok]
  }
  ok <- ok & is.finite(se_z)
  z_hat <- rep(NA_real_, length(rho))
  z_hat[ok] <- atanh(rho[ok])
  z <- stats::qnorm(1 - (1 - conf.level) / 2)

  out <- summary
  out[[lower]] <- NA_real_
  out[[upper]] <- NA_real_
  out[[lower]][ok] <- tanh(z_hat[ok] - z * se_z[ok])
  out[[upper]][ok] <- tanh(z_hat[ok] + z * se_z[ok])
  out$conf.level <- conf.level
  out$interval_method <- "wald"
  out$interval_scale <- "fisher_z_backtransformed"
  out$std.error.scale <- std.error.scale
  out$interval_status <- ifelse(ok, "ok", "failed")
  out$interval_message <- ifelse(
    ok,
    "",
    "missing or invalid correlation/std.error"
  )
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

phase18_assert_interval_column_names <- function(lower, upper) {
  if (
    !is.character(lower) ||
      length(lower) != 1L ||
      !nzchar(lower) ||
      !is.character(upper) ||
      length(upper) != 1L ||
      !nzchar(upper)
  ) {
    stop("`lower` and `upper` must be non-empty column names.", call. = FALSE)
  }
  invisible(list(lower = lower, upper = upper))
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
