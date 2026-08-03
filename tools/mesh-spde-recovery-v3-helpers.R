# Pure contract and aggregation helpers for the fixed-kappa mesh recovery gate.
# Keep this file package-independent so its fail-closed behaviour is exercised
# by the ordinary CRAN-safe test suite.

mesh_v3_contract <- function() {
  list(
    n_sites = c(128L, 256L),
    replicates_per_rung = 50L,
    kappa = 1 / 20000,
    field_scale = 1e-4,
    residual_sd = 0.25,
    domain_width = 100000,
    max_edge = c(12000, 25000),
    offset = c(10000, 20000),
    cutoff = 100,
    max_abs_relative_bias = 0.15,
    max_rmse_log_scale = 0.30,
    max_gradient = 1e-3,
    near_zero_fraction = 0.05,
    confidence_level = 0.95
  )
}

mesh_v3_prior_seeds <- function() {
  c(
    2026180201:2026180250, 2026280201:2026280250, 2026380201:2026380250,
    2026180301:2026180350, 2026280301:2026280350, 2026380301:2026380350,
    2026080401:2026080450,
    # Exclude the entire superseded 50770c579 ledger after its first two seeds
    # were used by the local smoke and its Totoro launch was stopped.
    2031281001:2031281050, 2032561001:2032561050
  )
}

mesh_v3_design <- function(smoke = FALSE) {
  if (isTRUE(smoke)) {
    design <- data.frame(
      n_site = c(128L, 256L), replicate = c(0L, 0L),
      seed = c(2039000001L, 2039000002L)
    )
  } else {
    design <- rbind(
      data.frame(n_site = 128L, replicate = seq_len(50L), seed = 2041281001:2041281050),
      data.frame(n_site = 256L, replicate = seq_len(50L), seed = 2042561001:2042561050)
    )
  }
  rownames(design) <- NULL
  mesh_v3_validate_design(design, smoke = smoke)
  design
}

mesh_v3_validate_design <- function(design, smoke = FALSE) {
  contract <- mesh_v3_contract()
  required <- c("n_site", "replicate", "seed")
  if (!is.data.frame(design) || !all(required %in% names(design))) {
    stop("The V3 design must contain n_site, replicate, and seed columns.")
  }
  numeric_columns <- vapply(design[required], is.numeric, logical(1))
  if (!all(numeric_columns) || anyNA(design[required]) ||
      any(!is.finite(as.matrix(design[required])))) {
    stop("The V3 design columns must contain finite numeric values.")
  }
  if (!all(design$n_site == as.integer(design$n_site)) ||
      !all(design$replicate == as.integer(design$replicate)) ||
      !all(design$seed == as.integer(design$seed)) || any(design$seed <= 0)) {
    stop("The V3 design must use integer-valued sites and replicates and positive integer seeds.")
  }
  if (!setequal(unique(design$n_site), contract$n_sites)) {
    stop("The V3 design contains an out-of-domain sample-size rung.")
  }
  expected_per_rung <- if (isTRUE(smoke)) 1L else contract$replicates_per_rung
  counts <- table(factor(design$n_site, levels = contract$n_sites))
  if (!identical(as.integer(counts), rep(expected_per_rung, length(contract$n_sites)))) {
    stop("The V3 design does not contain the frozen number of attempts per rung.")
  }
  if (anyNA(design$seed) || anyDuplicated(design$seed)) {
    stop("The V3 seed ledger must contain finite unique seeds.")
  }
  expected_replicates <- if (isTRUE(smoke)) 0L else seq_len(contract$replicates_per_rung)
  replicate_ok <- vapply(split(design$replicate, design$n_site), function(x) {
    identical(sort(as.integer(x)), expected_replicates)
  }, logical(1))
  if (!all(replicate_ok)) {
    stop("The V3 design does not contain the exact frozen replicate identifiers.")
  }
  if (length(intersect(design$seed, mesh_v3_prior_seeds()))) {
    stop("The V3 seed ledger overlaps an earlier mesh recovery receipt.")
  }
  invisible(TRUE)
}

mesh_v3_mc_summary <- function(rows, smoke = FALSE) {
  contract <- mesh_v3_contract()
  required <- c(
    "n_site", "fit_ok", "convergence", "pdHess", "objective",
    "max_gradient", "estimate", "warning_count"
  )
  if (!is.data.frame(rows) || !all(required %in% names(rows))) {
    stop("Recovery rows are missing required fail-closed diagnostic columns.")
  }
  expected <- if (isTRUE(smoke)) 1L else contract$replicates_per_rung
  z <- stats::qnorm(0.5 + contract$confidence_level / 2)

  summarize_rung <- function(x) {
    finite_positive <- is.finite(x$estimate) & x$estimate > 0
    converged <- !is.na(x$convergence) & x$convergence == 0L
    hessian_ok <- !is.na(x$pdHess) & x$pdHess
    fit_ok <- !is.na(x$fit_ok) & x$fit_ok
    objective_ok <- is.finite(x$objective)
    gradient_ok <- is.finite(x$max_gradient) & x$max_gradient <= contract$max_gradient
    warning_ok <- !is.na(x$warning_count) & x$warning_count == 0L
    usable <- fit_ok & converged & hessian_ok & finite_positive & objective_ok &
      gradient_ok & warning_ok

    rel <- x$estimate[usable] / contract$field_scale - 1
    log_error <- log(x$estimate[usable]) - log(contract$field_scale)
    bias <- if (length(rel)) mean(rel) else NA_real_
    bias_se <- if (length(rel) > 1L) stats::sd(rel) / sqrt(length(rel)) else NA_real_
    bias_low <- bias - z * bias_se
    bias_high <- bias + z * bias_se
    rmse <- if (length(log_error)) sqrt(mean(log_error^2)) else NA_real_
    squared <- log_error^2
    rmse_se <- if (length(squared) > 1L && is.finite(rmse) && rmse == 0) {
      0
    } else if (length(squared) > 1L && is.finite(rmse) && rmse > 0) {
      stats::sd(squared) / sqrt(length(squared)) / (2 * rmse)
    } else {
      NA_real_
    }
    rmse_high <- rmse + z * rmse_se
    near_zero <- finite_positive & x$estimate < contract$near_zero_fraction * contract$field_scale

    complete <- nrow(x) == expected && sum(usable) == expected
    uncertainty_inside <- is.finite(bias_low) && is.finite(bias_high) &&
      bias_low >= -contract$max_abs_relative_bias &&
      bias_high <= contract$max_abs_relative_bias &&
      is.finite(rmse_high) && rmse_high <= contract$max_rmse_log_scale
    point_inside <- is.finite(bias) && abs(bias) <= contract$max_abs_relative_bias &&
      is.finite(rmse) && rmse <= contract$max_rmse_log_scale

    data.frame(
      n_site = x$n_site[[1L]], attempts = nrow(x), usable = sum(usable),
      convergence_ok = sum(converged), pdHess_ok = sum(hessian_ok),
      finite_positive = sum(finite_positive), objective_ok = sum(objective_ok),
      gradient_ok = sum(gradient_ok), warning_free = sum(warning_ok),
      near_zero = sum(near_zero),
      relative_bias = bias, bias_mcse = bias_se,
      bias_ci_low = bias_low, bias_ci_high = bias_high,
      rmse_log_scale = rmse, rmse_mcse = rmse_se,
      rmse_ci_high = rmse_high,
      gate_pass = !isTRUE(smoke) && complete && point_inside &&
        uncertainty_inside && sum(near_zero) == 0L
    )
  }

  out <- do.call(rbind, lapply(split(rows, rows$n_site), summarize_rung))
  rownames(out) <- NULL
  out
}
