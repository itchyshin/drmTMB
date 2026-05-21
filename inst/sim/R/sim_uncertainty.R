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
    usable_interval <- is.finite(lower_value) & is.finite(upper_value)
    if ("interval_status" %in% names(x)) {
      usable_interval <- usable_interval &
        as.character(x$interval_status) == "ok"
    }
    covered <- usable_interval & lower_value <= truth & truth <= upper_value
    width <- upper_value[usable_interval] - lower_value[usable_interval]

    data.frame(
      x[1L, by, drop = FALSE],
      n_replicate = nrow(x),
      n_interval = sum(usable_interval),
      n_covered = sum(covered),
      coverage = mean(covered),
      coverage_mcse = phase18_mcse_proportion(covered),
      mean_interval_width = if (length(width) == 0L) NA_real_ else mean(width),
      interval_width_mcse = if (length(width) < 2L) {
        NA_real_
      } else {
        phase18_mcse_mean(width)
      },
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  })
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

phase18_summarise_interval_status <- function(
  intervals,
  by = NULL,
  status = "interval_status"
) {
  if (!is.data.frame(intervals)) {
    stop("`intervals` must be a data frame.", call. = FALSE)
  }
  if (nrow(intervals) == 0L) {
    return(data.frame())
  }
  if (
    !is.character(status) ||
      length(status) != 1L ||
      !nzchar(status) ||
      !status %in% names(intervals)
  ) {
    stop("`status` must name one column in `intervals`.", call. = FALSE)
  }
  if (is.null(by)) {
    by <- phase18_default_interval_groups(intervals)
  }
  phase18_assert_group_columns(intervals, by)

  split_key <- interaction(intervals[by], drop = TRUE, lex.order = TRUE)
  pieces <- split(intervals, split_key)
  rows <- lapply(pieces, function(x) {
    status_value <- as.character(x[[status]])
    ok <- !is.na(status_value) & status_value == "ok"
    failed <- is.na(status_value) | status_value == "failed"
    not_requested <- !is.na(status_value) &
      status_value == "not_requested"
    known <- ok | failed | not_requested

    data.frame(
      x[1L, by, drop = FALSE],
      n_replicate = nrow(x),
      n_ok = sum(ok),
      n_failed = sum(failed),
      n_not_requested = sum(not_requested),
      n_other_status = sum(!known),
      interval_success_rate = mean(ok),
      interval_success_mcse = phase18_mcse_proportion(ok),
      interval_failure_rate = mean(failed),
      interval_failure_mcse = phase18_mcse_proportion(failed),
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  })
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

phase18_summarise_interval_evidence <- function(
  intervals,
  by = NULL,
  lower = "conf.low",
  upper = "conf.high"
) {
  if (!is.data.frame(intervals)) {
    stop("`intervals` must be a data frame.", call. = FALSE)
  }
  if (nrow(intervals) == 0L) {
    return(data.frame())
  }
  if (is.null(by)) {
    by <- phase18_default_interval_groups(intervals)
  }
  phase18_assert_group_columns(intervals, by)

  coverage <- phase18_summarise_interval_coverage(
    intervals,
    by = by,
    lower = lower,
    upper = upper
  )
  status <- phase18_summarise_interval_status(intervals, by = by)
  status_extra <- status[,
    setdiff(names(status), "n_replicate"),
    drop = FALSE
  ]
  out <- merge(coverage, status_extra, by = by, all.x = TRUE, sort = FALSE)
  out$n_interval_missed <- out$n_interval - out$n_covered
  out$n_interval_unusable <- out$n_replicate - out$n_interval
  out$artifact_grain <- "interval_diagnostics"
  out
}

phase18_interval_failures <- function(
  intervals,
  status = NULL,
  ok_status = NULL
) {
  if (!is.data.frame(intervals)) {
    stop("`intervals` must be a data frame.", call. = FALSE)
  }
  if (nrow(intervals) == 0L) {
    return(phase18_empty_interval_failures(intervals))
  }
  if (is.null(status)) {
    if ("interval_status" %in% names(intervals)) {
      status <- "interval_status"
    } else if ("conf.status" %in% names(intervals)) {
      status <- "conf.status"
    } else {
      stop(
        "`intervals` must contain `interval_status` or `conf.status`.",
        call. = FALSE
      )
    }
  }
  if (
    !is.character(status) ||
      length(status) != 1L ||
      !nzchar(status) ||
      !status %in% names(intervals)
  ) {
    stop("`status` must name one column in `intervals`.", call. = FALSE)
  }
  if (is.null(ok_status)) {
    ok_status <- if (identical(status, "interval_status")) {
      "ok"
    } else {
      c("wald", "profile")
    }
  }
  if (
    !is.character(ok_status) ||
      length(ok_status) == 0L ||
      any(!nzchar(ok_status))
  ) {
    stop("`ok_status` must be a non-empty character vector.", call. = FALSE)
  }

  status_value <- as.character(intervals[[status]])
  failed <- is.na(status_value) | !status_value %in% ok_status
  out <- intervals[failed, , drop = FALSE]
  if (nrow(out) == 0L) {
    return(phase18_empty_interval_failures(intervals))
  }
  out$artifact_grain <- "interval_failure"
  out$interval_failure_status <- status_value[failed]
  if (!"interval_message" %in% names(out)) {
    out$interval_message <- NA_character_
  }
  row.names(out) <- NULL
  out
}

phase18_profile_interval_columns <- function(
  summary,
  fit,
  parameters,
  conf.level = 0.70,
  interval_scale = "formula_coefficient",
  trace = FALSE,
  profile_args = list(ystep = 0.50)
) {
  phase18_assert_summary_columns(summary, c("parameter"))
  if (!inherits(fit, "drmTMB")) {
    stop("`fit` must be a drmTMB object.", call. = FALSE)
  }
  if (
    !is.character(parameters) ||
      any(!nzchar(parameters))
  ) {
    stop("`parameters` must be a character vector.", call. = FALSE)
  }
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
      length(interval_scale) != 1L ||
      !nzchar(interval_scale)
  ) {
    stop("`interval_scale` must be one non-empty string.", call. = FALSE)
  }
  if (!is.list(profile_args)) {
    stop("`profile_args` must be a list.", call. = FALSE)
  }

  out <- phase18_initialise_interval_columns(
    summary,
    prefix = "profile",
    conf.level = conf.level,
    method = "profile",
    interval_scale = interval_scale,
    default_status = "not_requested"
  )
  if (length(parameters) == 0L) {
    return(out)
  }
  row_parameters <- parameters
  target_parameters <- parameters
  parameter_names <- names(parameters)
  if (!is.null(parameter_names) && any(nzchar(parameter_names))) {
    if (any(!nzchar(parameter_names))) {
      stop(
        "Named `parameters` must have one non-empty name per profile row.",
        call. = FALSE
      )
    }
    row_parameters <- parameter_names
    target_parameters <- unname(parameters)
  }
  rows <- which(out$parameter %in% row_parameters)
  for (row in rows) {
    target <- target_parameters[[match(out$parameter[[row]], row_parameters)]]
    ci <- tryCatch(
      do.call(
        stats::confint,
        c(
          list(
            object = fit,
            parm = target,
            method = "profile",
            level = conf.level,
            trace = trace
          ),
          profile_args
        )
      ),
      error = function(e) e
    )
    out$profile.status[[row]] <- "failed"
    out$profile.message[[row]] <- ""
    if (inherits(ci, "error")) {
      out$profile.message[[row]] <- conditionMessage(ci)
      next
    }
    if (!all(c("lower", "upper") %in% names(ci)) || nrow(ci) == 0L) {
      out$profile.message[[row]] <- "profile interval lacks lower/upper columns"
      next
    }
    out$profile.conf.low[[row]] <- ci$lower[[1L]]
    out$profile.conf.high[[row]] <- ci$upper[[1L]]
    out$profile.status[[row]] <- ifelse(
      is.finite(ci$lower[[1L]]) & is.finite(ci$upper[[1L]]),
      "ok",
      "failed"
    )
    out$profile.message[[row]] <- if ("profile.message" %in% names(ci)) {
      ci$profile.message[[1L]]
    } else {
      ""
    }
  }
  out
}

phase18_initialise_interval_columns <- function(
  summary,
  prefix,
  conf.level,
  method,
  interval_scale,
  default_status
) {
  out <- summary
  out[[paste0(prefix, ".conf.low")]] <- NA_real_
  out[[paste0(prefix, ".conf.high")]] <- NA_real_
  out[[paste0(prefix, ".conf.level")]] <- conf.level
  out[[paste0(prefix, ".method")]] <- method
  out[[paste0(prefix, ".interval_scale")]] <- interval_scale
  out[[paste0(prefix, ".status")]] <- default_status
  out[[paste0(prefix, ".message")]] <- ""
  out
}

phase18_intervals_from_columns <- function(
  summary,
  prefix,
  interval_scale = NULL,
  parameters = NULL
) {
  lower <- paste0(prefix, ".conf.low")
  upper <- paste0(prefix, ".conf.high")
  level <- paste0(prefix, ".conf.level")
  method <- paste0(prefix, ".method")
  scale <- paste0(prefix, ".interval_scale")
  status <- paste0(prefix, ".status")
  message <- paste0(prefix, ".message")
  phase18_assert_summary_columns(
    summary,
    c("parameter", lower, upper, level, method, scale, status, message)
  )
  out <- summary
  if (!is.null(parameters)) {
    if (
      !is.character(parameters) ||
        length(parameters) == 0L ||
        any(!nzchar(parameters))
    ) {
      stop("`parameters` must be a non-empty character vector.", call. = FALSE)
    }
    out <- out[out$parameter %in% parameters, , drop = FALSE]
  }
  if (!is.null(interval_scale)) {
    if (
      !is.character(interval_scale) ||
        length(interval_scale) != 1L ||
        !nzchar(interval_scale)
    ) {
      stop("`interval_scale` must be one non-empty string.", call. = FALSE)
    }
    out[[scale]] <- interval_scale
  }
  out$conf.low <- out[[lower]]
  out$conf.high <- out[[upper]]
  out$conf.level <- out[[level]]
  out$interval_method <- out[[method]]
  out$interval_scale <- out[[scale]]
  if (identical(prefix, "bootstrap") && "bootstrap.n" %in% names(out)) {
    out$n_bootstrap <- out$bootstrap.n
  }
  out$interval_status <- ifelse(
    is.finite(out$conf.low) &
      is.finite(out$conf.high) &
      out[[status]] %in% c("ok", "profile", "wald"),
    "ok",
    ifelse(out[[status]] == "not_requested", "not_requested", "failed")
  )
  out$interval_message <- out[[message]]
  row.names(out) <- NULL
  out
}

phase18_interval_evidence_table <- function(...) {
  pieces <- list(...)
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
  out$artifact_grain <- "interval_evidence"
  row.names(out) <- NULL
  out
}

phase18_optional_intervals_from_columns <- function(
  summary,
  prefix,
  parameters = NULL
) {
  if (!paste0(prefix, ".conf.low") %in% names(summary)) {
    return(data.frame())
  }
  if (!is.null(parameters) && length(parameters) == 0L) {
    return(data.frame())
  }
  phase18_intervals_from_columns(
    summary,
    prefix = prefix,
    parameters = parameters
  )
}

phase18_optional_interval_coverage <- function(intervals, by) {
  if (!is.data.frame(intervals) || nrow(intervals) == 0L) {
    return(data.frame())
  }
  phase18_summarise_interval_coverage(intervals, by = by)
}

phase18_optional_interval_diagnostics <- function(intervals, by) {
  if (!is.data.frame(intervals) || nrow(intervals) == 0L) {
    return(data.frame())
  }
  phase18_summarise_interval_evidence(intervals, by = by)
}

phase18_empty_interval_failures <- function(intervals) {
  out <- intervals[0L, , drop = FALSE]
  out$artifact_grain <- character()
  out$interval_failure_status <- character()
  if (!"interval_message" %in% names(out)) {
    out$interval_message <- character()
  }
  out
}

phase18_default_summary_groups <- function(summary) {
  intersect(
    c("surface", "known_v_type", "cell_id", "parameter"),
    names(summary)
  )
}

phase18_default_interval_groups <- function(intervals) {
  intersect(
    c(
      "surface",
      "known_v_type",
      "cell_id",
      "parameter",
      "interval_method",
      "interval_scale"
    ),
    names(intervals)
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
