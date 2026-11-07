# Pure two-look decision logic for the native SD-regression calibration.
#
# Inputs must already be reconciled against the frozen manifest by the full
# summarizer. This function checks planned denominators and standardized fields;
# it does not authenticate seeds, result identities, or artifact hashes.
# Bias intervals are approximate finite-estimate diagnostics, not decision gates.

native_sd_staged_decision <- function(
  attempts,
  manifest_count,
  look,
  completed_campaign
) {
  integrity_failure <- function(reason) {
    list(
      decision = "integrity_failure",
      look = if (length(look) == 1L) look else NA_integer_,
      reason = reason,
      metrics = data.frame(),
      gates = data.frame(),
      status_counts = data.frame()
    )
  }
  incomplete <- function(reason) {
    list(
      decision = "incomplete",
      look = as.integer(look),
      reason = reason,
      metrics = data.frame(),
      gates = data.frame(),
      status_counts = data.frame()
    )
  }

  if (!is.data.frame(attempts)) {
    return(integrity_failure("attempts must be a data frame"))
  }
  required <- c("truth", "estimate", "lower", "upper", "valid", "status")
  if (!all(required %in% names(attempts))) {
    return(integrity_failure("attempts lack required standardized columns"))
  }
  if (!is.numeric(look) || length(look) != 1L || is.na(look) ||
      !look %in% c(1, 2)) {
    return(integrity_failure("look must be 1 or 2"))
  }
  look <- as.integer(look)
  expected_per_truth <- if (look == 1L) 1000L else 4000L
  expected_manifest_count <- 3L * expected_per_truth
  if (!is.numeric(manifest_count) || length(manifest_count) != 1L ||
      !is.finite(manifest_count) ||
      manifest_count != expected_manifest_count) {
    return(integrity_failure(
      paste0("look ", look, " requires manifest_count = ",
             expected_manifest_count)
    ))
  }
  if (!is.logical(completed_campaign) || length(completed_campaign) != 1L ||
      is.na(completed_campaign)) {
    return(integrity_failure("completed_campaign must be one non-missing logical value"))
  }
  if (!is.numeric(attempts$truth) || !is.numeric(attempts$estimate) ||
      !is.numeric(attempts$lower) || !is.numeric(attempts$upper) ||
      !is.logical(attempts$valid) || anyNA(attempts$truth) ||
      anyNA(attempts$valid) || !is.character(attempts$status) ||
      anyNA(attempts$status)) {
    return(integrity_failure("standardized worker columns have invalid types or missing keys"))
  }
  expected_truths <- c(-0.5, 0, 0.5)
  if (any(!is.finite(attempts$truth)) ||
      !setequal(unique(attempts$truth), expected_truths)) {
    return(integrity_failure("truth must contain exactly -0.5, 0, and 0.5"))
  }
  observed_per_truth <- vapply(expected_truths, function(truth) {
    as.integer(sum(attempts$truth == truth))
  }, integer(1L))
  if (!completed_campaign) {
    return(incomplete("campaign has not reached its terminal receipt"))
  }
  if (nrow(attempts) != manifest_count ||
      any(observed_per_truth != expected_per_truth)) {
    return(integrity_failure(
      "worker rows do not match the full planned manifest denominator"
    ))
  }

  terminal_status <- c("completed", "error", "timeout")
  if (any(!attempts$status %in% terminal_status)) {
    return(integrity_failure(
      paste0(
        "a completed campaign may contain only completed, error, or timeout ",
        "attempt statuses"
      )
    ))
  }
  if (any(attempts$valid & attempts$status != "completed")) {
    return(integrity_failure(
      "a valid interval is recorded for an attempt without completed worker status"
    ))
  }
  valid_rows <- which(attempts$valid)
  if (length(valid_rows) > 0L) {
    values <- c(
      attempts$estimate[valid_rows],
      attempts$lower[valid_rows],
      attempts$upper[valid_rows]
    )
    if (any(!is.finite(values)) ||
        any(attempts$lower[valid_rows] >= attempts$upper[valid_rows])) {
      return(integrity_failure(
        "valid intervals require finite estimates and ordered finite bounds"
      ))
    }
  }

  exact_ci <- function(success, n) {
    unname(stats::binom.test(success, n, conf.level = 0.975)$conf.int)
  }
  mean_t_ci <- function(x) {
    if (length(x) < 2L || any(!is.finite(x))) {
      return(c(NA_real_, NA_real_, if (length(x)) mean(x) else NA_real_))
    }
    estimate <- mean(x)
    half_width <- stats::qt(0.9875, df = length(x) - 1L) *
      stats::sd(x) / sqrt(length(x))
    c(estimate - half_width, estimate + half_width, estimate)
  }
  interval_state <- function(lower, upper, band_lower, band_upper) {
    if (!is.finite(lower) || !is.finite(upper)) {
      return("ambiguous")
    }
    if (lower >= band_lower && upper <= band_upper) {
      return("pass")
    }
    if (upper < band_lower || lower > band_upper) {
      return("fail")
    }
    "ambiguous"
  }
  lower_gate_state <- function(lower, upper, threshold) {
    if (!is.finite(lower) || !is.finite(upper)) {
      return("ambiguous")
    }
    if (lower >= threshold) {
      return("pass")
    }
    if (upper < threshold) {
      return("fail")
    }
    "ambiguous"
  }

  gate_rows <- list()
  metric_rows <- list()
  gate_i <- 0L
  metric_i <- 0L
  add_metric <- function(truth, metric, success, n, ci, band, state) {
    metric_i <<- metric_i + 1L
    metric_rows[[metric_i]] <<- data.frame(
      truth = truth,
      metric = metric,
      success = success,
      n = n,
      estimate = if (n > 0) success / n else NA_real_,
      ci_lower = ci[[1L]],
      ci_upper = ci[[2L]],
      band_lower = band[[1L]],
      band_upper = band[[2L]],
      stringsAsFactors = FALSE
    )
    gate_i <<- gate_i + 1L
    gate_rows[[gate_i]] <<- data.frame(
      truth = truth,
      metric = metric,
      state = state,
      stringsAsFactors = FALSE
    )
  }

  for (truth in expected_truths) {
    rows <- which(attempts$truth == truth)
    n <- length(rows)
    valid <- attempts$valid[rows]
    covered <- valid &
      attempts$lower[rows] <= truth & attempts$upper[rows] >= truth
    coverage_success <- sum(covered)
    coverage_ci <- exact_ci(coverage_success, n)
    add_metric(
      truth, "coverage", coverage_success, n, coverage_ci,
      c(0.925, 0.975),
      interval_state(coverage_ci[[1L]], coverage_ci[[2L]], 0.925, 0.975)
    )

    valid_count <- sum(valid)
    valid_ci <- exact_ci(valid_count, n)
    add_metric(
      truth, "valid_fraction", valid_count, n, valid_ci,
      c(0.95, Inf),
      lower_gate_state(valid_ci[[1L]], valid_ci[[2L]], 0.95)
    )

    estimate <- attempts$estimate[rows]
    estimate <- estimate[is.finite(estimate)]
    log_bias_ci <- mean_t_ci(estimate - truth)
    metric_i <- metric_i + 1L
    metric_rows[[metric_i]] <- data.frame(
      truth = truth,
      metric = "log_sd_bias",
      success = NA_integer_,
      n = length(estimate),
      estimate = log_bias_ci[[3L]],
      ci_lower = log_bias_ci[[1L]],
      ci_upper = log_bias_ci[[2L]],
      band_lower = -0.10,
      band_upper = 0.10,
      stringsAsFactors = FALSE
    )
    relative_bias <- exp(estimate - truth) - 1
    ratio_ci <- mean_t_ci(relative_bias)
    metric_i <- metric_i + 1L
    metric_rows[[metric_i]] <- data.frame(
      truth = truth,
      metric = "relative_exp_a_bias",
      success = NA_integer_,
      n = length(relative_bias),
      estimate = ratio_ci[[3L]],
      ci_lower = ratio_ci[[1L]],
      ci_upper = ratio_ci[[2L]],
      band_lower = -0.10,
      band_upper = 0.10,
      stringsAsFactors = FALSE
    )
    if (truth == 0) {
      false_positive <- valid &
        (attempts$lower[rows] > 0 | attempts$upper[rows] < 0)
      fp_success <- sum(false_positive)
      fp_ci <- exact_ci(fp_success, n)
      add_metric(
        truth, "false_positive", fp_success, n, fp_ci,
        c(0.025, 0.075),
        interval_state(fp_ci[[1L]], fp_ci[[2L]], 0.025, 0.075)
      )
    }
  }

  metrics <- do.call(rbind, metric_rows)
  gates <- do.call(rbind, gate_rows)
  rownames(metrics) <- rownames(gates) <- NULL
  status_counts <- as.data.frame(table(
    truth = factor(attempts$truth, levels = expected_truths),
    status = factor(attempts$status, levels = terminal_status)
  ), stringsAsFactors = FALSE)
  status_counts <- status_counts[status_counts$Freq > 0L, , drop = FALSE]
  names(status_counts)[[3L]] <- "n"

  if (any(gates$state == "fail")) {
    decision <- "fail"
  } else if (all(gates$state == "pass")) {
    decision <- "accept"
  } else if (look == 1L) {
    decision <- "look2_required"
  } else {
    decision <- "inconclusive"
  }
  list(
    decision = decision,
    look = look,
    confidence_level = 0.975,
    manifest_count = as.integer(manifest_count),
    n_per_truth = expected_per_truth,
    completed_campaign = TRUE,
    metrics = metrics,
    gates = gates,
    status_counts = status_counts,
    failed_gates = gates[gates$state == "fail", , drop = FALSE],
    ambiguous_gates = gates[gates$state == "ambiguous", , drop = FALSE]
  )
}

