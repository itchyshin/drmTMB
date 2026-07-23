phase18_summarise_meta_v_smoke <- function(
  conditions = phase18_meta_v_conditions(
    n_study = 36L,
    known_v_type = c("vector", "dense"),
    sigma = 0.25,
    sampling_sd = 0.14,
    sampling_rho = c(0, 0.20)
  ),
  n_rep = 2L,
  master_seed = 20260518L,
  result_dir = NULL,
  overwrite = FALSE,
  by = NULL,
  cores = 1L,
  backend = "none"
) {
  run <- phase18_run_meta_v_smoke(
    conditions = conditions,
    n_rep = n_rep,
    master_seed = master_seed,
    result_dir = result_dir,
    overwrite = overwrite,
    cores = cores,
    backend = backend
  )
  if (nrow(run$summary) == 0L) {
    stop("The meta_V smoke run produced no summaries.", call. = FALSE)
  }
  if (is.null(by)) {
    by <- phase18_default_summary_groups(run$summary)
  }
  interval_scale <- ifelse(
    run$summary$parameter == "sigma",
    "public",
    "formula_coefficient"
  )
  wald_intervals <- phase18_add_wald_intervals(
    run$summary,
    interval_scale = interval_scale
  )
  sigma_rows <- run$summary$parameter == "sigma"
  wald_intervals$conf.low[sigma_rows] <- run$summary$conf.low[sigma_rows]
  wald_intervals$conf.high[sigma_rows] <- run$summary$conf.high[sigma_rows]
  wald_intervals$interval_method[sigma_rows] <- run$summary$interval_method[sigma_rows]
  wald_intervals$interval_status[sigma_rows] <- run$summary$interval_status[sigma_rows]
  wald_intervals$conf.status[sigma_rows] <- run$summary$conf.status[sigma_rows]
  wald_intervals$interval_message[sigma_rows] <- run$summary$interval_message[sigma_rows]
  wald_intervals <- phase18_meta_v_classify_attempts(wald_intervals)
  aggregate <- phase18_meta_v_aggregate_all_attempts(
    wald_intervals,
    by = by
  )
  manifest <- phase18_meta_v_attempt_manifest(
    wald_intervals,
    raw_manifest = phase18_result_manifest(run$results)
  )
  failures <- phase18_result_failures(run$results)
  finite_and_covering_rate_all_attempt <- phase18_meta_v_all_attempt_coverage(
    wald_intervals,
    by = by
  )
  conditional_finite_interval_coverage <- phase18_meta_v_conditional_finite_coverage(
    wald_intervals,
    by = by
  )

  list(
    surface = "meta_v",
    run = run,
    aggregate = aggregate,
    replicates = run$summary,
    manifest = manifest,
    failures = failures,
    wald_intervals = wald_intervals,
    finite_and_covering_rate_all_attempt = finite_and_covering_rate_all_attempt,
    conditional_finite_interval_coverage = conditional_finite_interval_coverage
  )
}

phase18_meta_v_classify_attempts <- function(intervals) {
  required <- c(
    "result_status", "converged", "pdHess", "estimate", "interval_status",
    "conf.low", "conf.high"
  )
  phase18_assert_summary_columns(intervals, required)
  out <- intervals
  finite_interval <- is.finite(out$conf.low) & is.finite(out$conf.high) &
    out$interval_status == "ok"
  out$finite_interval <- finite_interval
  out$attempt_status <- "ok"
  out$attempt_status[out$result_status != "ok"] <- "fit_error"
  out$attempt_status[
    out$result_status == "ok" & !out$converged
  ] <- "nonconverged"
  out$attempt_status[
    out$result_status == "ok" & out$converged & !out$pdHess
  ] <- "pdHess_false"
  out$attempt_status[
    out$result_status == "ok" & out$converged & out$pdHess &
      !is.finite(out$estimate)
  ] <- "nonfinite_estimate"
  out$attempt_status[
    out$result_status == "ok" & out$converged & out$pdHess &
      is.finite(out$estimate) & out$interval_status == "degenerate_zero_infinite"
  ] <- "degenerate_interval"
  out$attempt_status[
    out$result_status == "ok" & out$converged & out$pdHess &
      is.finite(out$estimate) & !finite_interval &
      out$interval_status != "degenerate_zero_infinite"
  ] <- "interval_failed"
  out$finite_interval <- finite_interval & out$attempt_status == "ok"
  out
}

phase18_meta_v_aggregate_all_attempts <- function(intervals, by) {
  phase18_assert_group_columns(intervals, by)
  pieces <- split(
    intervals,
    interaction(intervals[by], drop = TRUE, lex.order = TRUE)
  )
  rows <- lapply(pieces, function(x) {
    estimated <- is.finite(x$estimate) & is.finite(x$error)
    data.frame(
      x[1L, by, drop = FALSE],
      n_replicate = nrow(x),
      n_attempt = nrow(x),
      n_finite_estimate_only = sum(estimated),
      artifact_grain = "aggregate_all_attempt",
      mean_truth = mean(x$truth),
      mean_estimate_finite_only = phase18_meta_v_mean_or_na(x$estimate[estimated]),
      bias_finite_estimate_only = phase18_meta_v_mean_or_na(x$error[estimated]),
      rmse_finite_estimate_only = phase18_meta_v_rmse_or_na(x$error[estimated]),
      mean_abs_error_finite_estimate_only = phase18_meta_v_mean_or_na(abs(x$error[estimated])),
      empirical_se_finite_estimate_only = phase18_meta_v_sd_or_na(x$estimate[estimated]),
      bias_mcse_finite_estimate_only = phase18_meta_v_mcse_mean_or_na(x$error[estimated]),
      rmse_mcse_finite_estimate_only = phase18_meta_v_mcse_rmse_or_na(x$error[estimated]),
      convergence_rate_all_attempt = mean(x$result_status == "ok" & x$converged),
      convergence_rate_all_attempt_mcse = phase18_meta_v_mcse_proportion_or_na(
        x$result_status == "ok" & x$converged
      ),
      pdHess_rate_all_attempt = mean(
        x$result_status == "ok" & x$converged & x$pdHess
      ),
      pdHess_rate_all_attempt_mcse = phase18_meta_v_mcse_proportion_or_na(
        x$result_status == "ok" & x$converged & x$pdHess
      ),
      n_fit_error = sum(x$result_status != "ok"),
      n_nonconverged = sum(x$result_status == "ok" & !x$converged),
      n_pdHess_false = sum(x$result_status == "ok" & x$converged & !x$pdHess),
      n_nonfinite_estimate = sum(
        x$result_status == "ok" & x$converged & x$pdHess &
          !is.finite(x$estimate)
      ),
      warning_rate_all_attempt = mean(x$warning_count > 0),
      warning_rate_all_attempt_mcse = phase18_meta_v_mcse_proportion_or_na(
        x$warning_count > 0
      ),
      mean_elapsed_all_attempt = mean(x$elapsed),
      median_elapsed_all_attempt = stats::median(x$elapsed),
      p90_elapsed_all_attempt = as.numeric(stats::quantile(x$elapsed, 0.90)),
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  })
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

phase18_meta_v_attempt_manifest <- function(intervals, raw_manifest = NULL) {
  required <- c(
    "cell_id", "replicate", "seed", "result_status", "result_error",
    "warning_count", "elapsed", "attempt_status", "finite_interval"
  )
  phase18_assert_summary_columns(intervals, required)
  key <- interaction(
    intervals[c("cell_id", "replicate", "seed")],
    drop = TRUE,
    lex.order = TRUE
  )
  pieces <- split(intervals, key)
  rows <- lapply(pieces, function(x) {
    data.frame(
      cell_id = x$cell_id[[1L]],
      replicate = x$replicate[[1L]],
      seed = x$seed[[1L]],
      status = x$result_status[[1L]],
      skipped = NA,
      warning_count = x$warning_count[[1L]],
      error = x$result_error[[1L]],
      elapsed = x$elapsed[[1L]],
      n_parameter_attempt = nrow(x),
      n_parameter_ok = sum(x$attempt_status == "ok"),
      n_fit_error = sum(x$attempt_status == "fit_error"),
      n_nonconverged = sum(x$attempt_status == "nonconverged"),
      n_pdHess_false = sum(x$attempt_status == "pdHess_false"),
      n_nonfinite_estimate = sum(x$attempt_status == "nonfinite_estimate"),
      n_interval_failed = sum(x$attempt_status == "interval_failed"),
      n_interval_degenerate = sum(x$attempt_status == "degenerate_interval"),
      n_finite_interval = sum(x$finite_interval),
      n_interval = sum(x$finite_interval),
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  if (!is.null(raw_manifest)) {
    required_manifest <- c("cell_id", "replicate", "seed", "skipped")
    phase18_assert_summary_columns(raw_manifest, required_manifest)
    key <- paste(out$cell_id, out$replicate, out$seed, sep = "\r")
    raw_key <- paste(
      raw_manifest$cell_id,
      raw_manifest$replicate,
      raw_manifest$seed,
      sep = "\r"
    )
    matched <- match(key, raw_key)
    if (anyNA(matched)) {
      stop("Every all-attempt manifest row must match a raw result.", call. = FALSE)
    }
    out$skipped <- raw_manifest$skipped[matched]
  }
  out
}

phase18_meta_v_all_attempt_coverage <- function(intervals, by) {
  phase18_assert_group_columns(intervals, by)
  pieces <- split(
    intervals,
    interaction(intervals[by], drop = TRUE, lex.order = TRUE)
  )
  rows <- lapply(pieces, function(x) {
    covered <- x$finite_interval & x$conf.low <= x$truth & x$truth <= x$conf.high
    data.frame(
      x[1L, by, drop = FALSE],
      n_replicate = nrow(x),
      n_attempt = nrow(x),
      n_finite_interval = sum(x$finite_interval),
      n_interval = sum(x$finite_interval),
      n_finite_and_covering_interval = sum(covered),
      finite_interval_rate_all_attempt = mean(x$finite_interval),
      finite_interval_rate_all_attempt_mcse = phase18_meta_v_mcse_proportion_or_na(
        x$finite_interval
      ),
      finite_and_covering_interval_rate_all_attempt = mean(covered),
      finite_and_covering_interval_rate_all_attempt_mcse =
        phase18_meta_v_mcse_proportion_or_na(covered),
      n_fit_error = sum(x$attempt_status == "fit_error"),
      n_nonconverged = sum(x$attempt_status == "nonconverged"),
      n_pdHess_false = sum(x$attempt_status == "pdHess_false"),
      n_nonfinite_estimate = sum(x$attempt_status == "nonfinite_estimate"),
      n_interval_failed = sum(x$attempt_status == "interval_failed"),
      n_interval_degenerate = sum(x$attempt_status == "degenerate_interval"),
      mean_interval_width = phase18_meta_v_mean_or_na(
        x$conf.high[x$finite_interval] - x$conf.low[x$finite_interval]
      ),
      interval_width_mcse = phase18_meta_v_mcse_mean_or_na(
        x$conf.high[x$finite_interval] - x$conf.low[x$finite_interval]
      ),
      rate_definition = "finite_and_covering_interval_over_all_attempts",
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  })
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

phase18_meta_v_conditional_finite_coverage <- function(intervals, by) {
  phase18_assert_group_columns(intervals, by)
  pieces <- split(
    intervals,
    interaction(intervals[by], drop = TRUE, lex.order = TRUE)
  )
  rows <- lapply(pieces, function(x) {
    covered <- x$finite_interval & x$conf.low <= x$truth & x$truth <= x$conf.high
    finite_covered <- covered[x$finite_interval]
    data.frame(
      x[1L, by, drop = FALSE],
      n_attempt = nrow(x),
      n_finite_interval = sum(x$finite_interval),
      n_covered_finite_interval = sum(finite_covered),
      conditional_finite_interval_set_coverage = phase18_meta_v_mean_or_na(
        finite_covered
      ),
      conditional_finite_interval_set_coverage_mcse = phase18_meta_v_mcse_proportion_or_na(
        finite_covered
      ),
      rate_definition = "set_coverage_given_finite_interval",
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  })
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

phase18_meta_v_mean_or_na <- function(x) {
  if (length(x) == 0L) NA_real_ else mean(x)
}

phase18_meta_v_sd_or_na <- function(x) {
  if (length(x) < 2L) NA_real_ else stats::sd(x)
}

phase18_meta_v_rmse_or_na <- function(x) {
  if (length(x) == 0L) NA_real_ else sqrt(mean(x^2))
}

phase18_meta_v_mcse_mean_or_na <- function(x) {
  if (length(x) < 2L) NA_real_ else stats::sd(x) / sqrt(length(x))
}

phase18_meta_v_mcse_rmse_or_na <- function(x) {
  if (length(x) < 2L) return(NA_real_)
  rmse <- sqrt(mean(x^2))
  if (identical(rmse, 0)) return(0)
  stats::sd(x^2) / sqrt(length(x)) / (2 * rmse)
}

phase18_meta_v_mcse_proportion_or_na <- function(x) {
  if (length(x) == 0L) return(NA_real_)
  p <- mean(x)
  sqrt(p * (1 - p) / length(x))
}
