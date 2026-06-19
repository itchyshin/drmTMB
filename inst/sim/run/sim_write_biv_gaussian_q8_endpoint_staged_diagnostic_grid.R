phase18_biv_gaussian_q8_endpoint_staged_source_formula <- function() {
  bf(
    mu1 = y1 ~ x + (1 | p | id),
    mu2 = y2 ~ x + (1 | p | id),
    sigma1 = ~ x + (1 | p | id),
    sigma2 = ~ x + (1 | p | id),
    rho12 = ~1
  )
}

phase18_biv_gaussian_q8_endpoint_staged_target_formula <- function() {
  bf(
    mu1 = y1 ~ x + (1 + x | p | id),
    mu2 = y2 ~ x + (1 + x | p | id),
    sigma1 = ~ x + (1 + x | p | id),
    sigma2 = ~ x + (1 + x | p | id),
    rho12 = ~1
  )
}

phase18_fit_biv_gaussian_q8_endpoint_staged_diagnostic <- function(
  data,
  cell,
  source_fit_fun = drmTMB,
  diagnostic_fun = drmTMB:::drm_qgt2_staged_fit_diagnostic,
  source_control = drm_control(
    optimizer = list(eval.max = 800L, iter.max = 800L),
    se = FALSE
  ),
  target_control = drm_control(
    optimizer = list(eval.max = 800L, iter.max = 800L),
    se = FALSE
  ),
  copy_theta_re_cov = FALSE,
  theta_re_cov_shrink = 0.85
) {
  phase18_assert_one_row_data_frame(cell, "cell")
  phase18_assert_function(source_fit_fun, "source_fit_fun")
  phase18_assert_function(diagnostic_fun, "diagnostic_fun")

  source_formula <- phase18_biv_gaussian_q8_endpoint_staged_source_formula()
  target_formula <- phase18_biv_gaussian_q8_endpoint_staged_target_formula()
  source_fit <- source_fit_fun(
    source_formula,
    family = biv_gaussian(),
    data = data,
    control = source_control
  )
  target_spec <- drmTMB:::drm_build_biv_gaussian_spec(
    target_formula,
    data = data
  )

  diagnostic_fun(
    source_fit = source_fit,
    target_spec = target_spec,
    formula = target_formula,
    family = biv_gaussian(),
    control = target_control,
    copy_theta_re_cov = copy_theta_re_cov,
    theta_re_cov_shrink = theta_re_cov_shrink
  )
}

phase18_run_biv_gaussian_q8_endpoint_staged_diagnostic <- function(
  conditions = phase18_biv_gaussian_q8_endpoint_conditions(
    n_id = 48L,
    n_each = 10L
  ),
  n_rep = 1L,
  master_seed = 20260636L,
  result_dir = NULL,
  overwrite = FALSE,
  cores = 1L,
  backend = "none",
  source_fit_fun = drmTMB,
  diagnostic_fun = drmTMB:::drm_qgt2_staged_fit_diagnostic
) {
  assert_positive_whole_number(n_rep, "n_rep")
  phase18_assert_function(source_fit_fun, "source_fit_fun")
  phase18_assert_function(diagnostic_fun, "diagnostic_fun")
  registry <- phase18_cell_registry(
    surface = "biv_gaussian_q8_endpoint_staged_diagnostic",
    conditions = conditions,
    n_rep = n_rep,
    master_seed = master_seed
  )

  fit_fun <- function(data, cell) {
    phase18_fit_biv_gaussian_q8_endpoint_staged_diagnostic(
      data = data,
      cell = cell,
      source_fit_fun = source_fit_fun,
      diagnostic_fun = diagnostic_fun
    )
  }

  results <- phase18_run_replicates(
    cells = registry$cells,
    seeds = registry$seeds,
    dgp_fun = phase18_dgp_biv_gaussian_q8_endpoint_cell,
    fit_fun = fit_fun,
    summarise_fun = phase18_summarise_biv_gaussian_q8_endpoint_staged_fit,
    result_dir = result_dir,
    overwrite = overwrite,
    cores = cores,
    backend = backend
  )
  summary <- phase18_result_summaries(
    results,
    artifact_grain = "diagnostic_fit"
  )

  list(
    surface = "biv_gaussian_q8_endpoint_staged_diagnostic",
    registry = registry,
    parallel = attr(results, "phase18_parallel", exact = TRUE),
    results = results,
    summary = summary
  )
}

phase18_summarise_biv_gaussian_q8_endpoint_staged_fit <- function(
  fit,
  truth,
  cell_id = NA_character_,
  replicate = NA_integer_,
  elapsed = NA_real_,
  warnings = character()
) {
  if (is.data.frame(truth)) {
    truth <- attr(truth, "truth", exact = TRUE)
  }
  if (
    !is.list(truth) || !identical(truth$surface, "biv_gaussian_q8_endpoint")
  ) {
    stop(
      "`truth` must be a bivariate Gaussian q8 endpoint truth object.",
      call. = FALSE
    )
  }
  if (
    !is.list(fit) ||
      !identical(fit$strategy, "qgt2-staged-fit-diagnostic") ||
      !is.list(fit$comparison)
  ) {
    stop(
      "`fit` must be a q>2 staged-fit diagnostic result.",
      call. = FALSE
    )
  }

  metrics <- phase18_q8_staged_metric_rows(
    fit$comparison$metrics,
    cell_id = cell_id,
    replicate = replicate,
    elapsed = elapsed,
    warnings = warnings
  )
  deltas <- phase18_q8_staged_delta_rows(
    fit$comparison$deltas,
    cell_id = cell_id,
    replicate = replicate,
    elapsed = elapsed,
    warnings = warnings
  )
  provenance <- phase18_q8_staged_provenance_row(
    fit$provenance,
    cell_id = cell_id,
    replicate = replicate,
    elapsed = elapsed,
    warnings = warnings
  )
  endpoint_status <- phase18_q8_staged_endpoint_status_rows(
    fit,
    truth,
    cell_id = cell_id,
    replicate = replicate
  )
  scope <- phase18_q8_staged_scope_row(
    cell_id = cell_id,
    replicate = replicate,
    elapsed = elapsed,
    warnings = warnings
  )

  out <- rbind(metrics, deltas, provenance, endpoint_status, scope)
  row.names(out) <- NULL
  out
}

phase18_q8_staged_empty_rows <- function(
  n,
  artifact_kind,
  cell_id,
  replicate,
  elapsed,
  warnings
) {
  data.frame(
    surface = rep("biv_gaussian_q8_endpoint_staged_diagnostic", n),
    cell_id = rep(cell_id, n),
    replicate = rep(replicate, n),
    artifact_kind = rep(artifact_kind, n),
    fit_label = rep(NA_character_, n),
    ok = rep(NA, n),
    convergence = rep(NA_integer_, n),
    pdHess = rep(NA, n),
    objective = rep(NA_real_, n),
    logLik = rep(NA_real_, n),
    df = rep(NA_real_, n),
    nobs = rep(NA_real_, n),
    fit_elapsed_sec = rep(NA_real_, n),
    optimizer_preset = rep(NA_character_, n),
    optimizer_attempt_count = rep(NA_integer_, n),
    optimizer_selected_attempt = rep(NA_character_, n),
    optimizer_retried = rep(NA, n),
    optimizer_attempt_presets = rep(NA_character_, n),
    optimizer_attempt_statuses = rep(NA_character_, n),
    optimizer_message = rep(NA_character_, n),
    iterations = rep(NA_real_, n),
    function_evaluations = rep(NA_real_, n),
    gradient_evaluations = rep(NA_real_, n),
    iter_max = rep(NA_real_, n),
    eval_max = rep(NA_real_, n),
    budget_status = rep(NA_character_, n),
    sdreport_status = rep(NA_character_, n),
    sdreport_message = rep(NA_character_, n),
    se_requested = rep(NA, n),
    fixed_gradient_status = rep(NA_character_, n),
    max_abs_gradient = rep(NA_real_, n),
    max_gradient_component = rep(NA_character_, n),
    gradient_tolerance = rep(NA_real_, n),
    failure_mode = rep(NA_character_, n),
    failure_detail = rep(NA_character_, n),
    fit_warning_count = rep(NA_integer_, n),
    fit_warnings = rep(NA_character_, n),
    fit_error = rep(NA_character_, n),
    delta_metric = rep(NA_character_, n),
    cold = rep(NA_real_, n),
    staged = rep(NA_real_, n),
    staged_minus_cold = rep(NA_real_, n),
    source_model_type = rep(NA_character_, n),
    target_model_type = rep(NA_character_, n),
    theta_re_cov = rep(NA_character_, n),
    theta_re_cov_shrink = rep(NA_real_, n),
    fixed_effect_match_count = rep(NA_integer_, n),
    qgt2_sd_match_count = rep(NA_integer_, n),
    qgt2_theta_match_count = rep(NA_integer_, n),
    parameter = rep(NA_character_, n),
    parameter_class = rep(NA_character_, n),
    endpoint_index = rep(NA_integer_, n),
    endpoint = rep(NA_character_, n),
    endpoint_scope = rep(NA_character_, n),
    dpar = rep(NA_character_, n),
    coefficient = rep(NA_character_, n),
    endpoint_role = rep(NA_character_, n),
    truth = rep(NA_real_, n),
    estimate = rep(NA_real_, n),
    estimate_error = rep(NA_real_, n),
    availability_status = rep(NA_character_, n),
    point_status = rep(NA_character_, n),
    se_status = rep(NA_character_, n),
    availability_reason = rep(NA_character_, n),
    boundary_distance = rep(NA_real_, n),
    interval_status = rep(NA_character_, n),
    diagnostic_scope = rep(NA_character_, n),
    unsupported_claims = rep(NA_character_, n),
    result_elapsed_sec = rep(as.numeric(elapsed), n),
    run_warning_count = rep(length(warnings), n),
    run_warnings = rep(paste(warnings, collapse = " | "), n),
    stringsAsFactors = FALSE
  )
}

phase18_q8_staged_metric_rows <- function(
  metrics,
  cell_id,
  replicate,
  elapsed,
  warnings
) {
  if (!is.data.frame(metrics) || nrow(metrics) == 0L) {
    stop("`metrics` must be a non-empty data frame.", call. = FALSE)
  }
  out <- phase18_q8_staged_empty_rows(
    nrow(metrics),
    "fit_metrics",
    cell_id = cell_id,
    replicate = replicate,
    elapsed = elapsed,
    warnings = warnings
  )
  out$fit_label <- metrics$label
  out$ok <- metrics$ok
  out$convergence <- metrics$convergence
  out$pdHess <- metrics$pdHess
  out$objective <- metrics$objective
  out$logLik <- metrics$logLik
  out$df <- metrics$df
  out$nobs <- metrics$nobs
  out$fit_elapsed_sec <- metrics$elapsed_sec
  out$optimizer_preset <- metrics$optimizer_preset
  out <- phase18_q8_staged_copy_optional_metric(
    out,
    metrics,
    c(
      "optimizer_attempt_count",
      "optimizer_selected_attempt",
      "optimizer_retried",
      "optimizer_attempt_presets",
      "optimizer_attempt_statuses",
      "optimizer_message",
      "iterations",
      "function_evaluations",
      "gradient_evaluations",
      "iter_max",
      "eval_max",
      "budget_status",
      "sdreport_status",
      "sdreport_message",
      "se_requested",
      "fixed_gradient_status",
      "max_abs_gradient",
      "max_gradient_component",
      "gradient_tolerance",
      "failure_mode",
      "failure_detail"
    )
  )
  out$fit_warning_count <- metrics$warning_count
  out$fit_warnings <- metrics$warnings
  out$fit_error <- metrics$error
  out
}

phase18_q8_staged_copy_optional_metric <- function(out, metrics, columns) {
  for (column in columns) {
    out[[column]] <- if (column %in% names(metrics)) {
      metrics[[column]]
    } else {
      out[[column]]
    }
  }
  out
}

phase18_q8_staged_delta_rows <- function(
  deltas,
  cell_id,
  replicate,
  elapsed,
  warnings
) {
  if (!is.data.frame(deltas) || nrow(deltas) == 0L) {
    stop("`deltas` must be a non-empty data frame.", call. = FALSE)
  }
  out <- phase18_q8_staged_empty_rows(
    nrow(deltas),
    "fit_deltas",
    cell_id = cell_id,
    replicate = replicate,
    elapsed = elapsed,
    warnings = warnings
  )
  out$delta_metric <- deltas$metric
  out$cold <- deltas$cold
  out$staged <- deltas$staged
  out$staged_minus_cold <- deltas$staged_minus_cold
  out
}

phase18_q8_staged_provenance_row <- function(
  provenance,
  cell_id,
  replicate,
  elapsed,
  warnings
) {
  if (!is.list(provenance)) {
    stop("`provenance` must be a list.", call. = FALSE)
  }
  out <- phase18_q8_staged_empty_rows(
    1L,
    "start_provenance",
    cell_id = cell_id,
    replicate = replicate,
    elapsed = elapsed,
    warnings = warnings
  )
  out$source_model_type <- phase18_q8_staged_scalar_character(
    provenance$source_model_type
  )
  out$target_model_type <- phase18_q8_staged_scalar_character(
    provenance$target_model_type
  )
  out$theta_re_cov <- phase18_q8_staged_scalar_character(
    provenance$theta_re_cov
  )
  out$theta_re_cov_shrink <- phase18_q8_staged_scalar_numeric(
    provenance$theta_re_cov_shrink
  )
  out$fixed_effect_match_count <- phase18_q8_staged_nrow(
    provenance$fixed_effect_matches
  )
  out$qgt2_sd_match_count <- phase18_q8_staged_nrow(
    provenance$qgt2_sd_matches
  )
  out$qgt2_theta_match_count <- phase18_q8_staged_nrow(
    provenance$qgt2_theta_matches
  )
  out
}

phase18_q8_staged_endpoint_status_rows <- function(
  fit,
  truth,
  cell_id,
  replicate
) {
  captured <- fit$fits
  if (!is.list(captured) || length(captured) == 0L) {
    return(phase18_q8_staged_empty_rows(
      0L,
      "endpoint_status",
      cell_id = cell_id,
      replicate = replicate,
      elapsed = NA_real_,
      warnings = character()
    ))
  }
  rows <- lapply(captured, function(x) {
    phase18_q8_staged_fit_endpoint_status(
      x,
      truth,
      cell_id = cell_id,
      replicate = replicate
    )
  })
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

phase18_q8_staged_fit_endpoint_status <- function(
  captured_fit,
  truth,
  cell_id,
  replicate
) {
  taxonomy <- phase18_q8_staged_endpoint_taxonomy()
  sd_truth <- c(truth$sd_mu, truth$sd_sigma)
  sd_parameter <- c(
    paste0("sd:mu:", names(truth$sd_mu)),
    paste0("sd:sigma:", names(truth$sd_sigma))
  )
  cor_truth <- truth$cor_re_cov
  residual_truth <- truth$residual_rho

  n_sd <- nrow(taxonomy)
  n_cor <- length(cor_truth)
  n_residual <- length(residual_truth)
  n <- n_sd + n_cor + n_residual
  out <- phase18_q8_staged_empty_rows(
    n,
    "endpoint_status",
    cell_id = cell_id,
    replicate = replicate,
    elapsed = NA_real_,
    warnings = character()
  )
  out$fit_label <- phase18_q8_staged_scalar_character(captured_fit$label)
  out$ok <- isTRUE(captured_fit$ok)
  out$convergence <- phase18_q8_staged_fit_metric(
    captured_fit,
    "convergence",
    NA_integer_
  )
  out$pdHess <- phase18_q8_staged_fit_metric(captured_fit, "pdHess", NA)
  out <- phase18_q8_staged_copy_captured_metrics(
    out,
    captured_fit,
    c(
      "optimizer_attempt_count",
      "optimizer_selected_attempt",
      "optimizer_retried",
      "optimizer_attempt_presets",
      "optimizer_attempt_statuses",
      "optimizer_message",
      "iterations",
      "function_evaluations",
      "gradient_evaluations",
      "iter_max",
      "eval_max",
      "budget_status",
      "sdreport_status",
      "sdreport_message",
      "se_requested",
      "fixed_gradient_status",
      "max_abs_gradient",
      "max_gradient_component",
      "gradient_tolerance",
      "failure_mode",
      "failure_detail"
    )
  )
  out$fit_warning_count <- phase18_q8_staged_fit_metric(
    captured_fit,
    "warning_count",
    NA_integer_
  )
  out$fit_warnings <- phase18_q8_staged_fit_metric(
    captured_fit,
    "warnings",
    NA_character_
  )
  out$fit_error <- phase18_q8_staged_fit_metric(
    captured_fit,
    "error",
    NA_character_
  )

  out$parameter <- c(
    sd_parameter,
    paste0("cor:re_cov:", names(cor_truth)),
    "rho12"
  )
  out$parameter_class <- c(
    rep("direct_random_sd", n_sd),
    rep("derived_random_correlation", n_cor),
    rep("residual_rho12", n_residual)
  )
  out$endpoint_index <- c(
    taxonomy$endpoint_index,
    rep(NA_integer_, n_cor),
    NA_integer_
  )
  out$endpoint <- c(
    taxonomy$endpoint,
    names(cor_truth),
    names(residual_truth)
  )
  out$endpoint_scope <- c(
    rep("q8_direct_sd", n_sd),
    rep("q8_derived_correlation", n_cor),
    rep("residual_rho12_separate", n_residual)
  )
  out$dpar <- c(taxonomy$dpar, rep("re_cov", n_cor), "rho12")
  out$coefficient <- c(taxonomy$coefficient, rep(NA_character_, n_cor), "rho12")
  out$endpoint_role <- c(
    taxonomy$endpoint_role,
    rep("derived_correlation", n_cor),
    "residual_correlation"
  )
  out$truth <- unname(c(sd_truth, cor_truth, residual_truth))
  out$interval_status <- "not_requested"

  values <- phase18_q8_staged_fit_endpoint_values(captured_fit$fit, truth)
  out$estimate <- phase18_q8_staged_match_estimates(out$parameter, values)
  out$availability_status <- phase18_q8_staged_availability_status(
    captured_fit,
    out$parameter,
    values,
    out$estimate
  )
  out$point_status <- phase18_q8_staged_point_status(out)
  out$availability_reason <- phase18_q8_staged_availability_reason(out)
  out$se_status <- if (isTRUE(out$se_requested[[1L]])) {
    "not_computed_for_endpoint_status"
  } else {
    "not_requested"
  }
  out$estimate_error <- out$estimate - out$truth
  is_correlation <- out$endpoint_scope %in%
    c(
      "q8_derived_correlation",
      "residual_rho12_separate"
    )
  out$boundary_distance[is_correlation] <- 0.999999 -
    abs(out$estimate[is_correlation])
  out$boundary_distance[
    out$endpoint_scope == "q8_direct_sd"
  ] <- out$estimate[out$endpoint_scope == "q8_direct_sd"]
  out
}

phase18_q8_staged_copy_captured_metrics <- function(
  out,
  captured_fit,
  columns
) {
  for (column in columns) {
    out[[column]] <- phase18_q8_staged_fit_metric(
      captured_fit,
      column,
      out[[column]][[1L]]
    )
  }
  out
}

phase18_q8_staged_endpoint_taxonomy <- function() {
  data.frame(
    endpoint_index = seq_len(8L),
    endpoint = c(
      "mu1:(Intercept)",
      "mu1:x",
      "mu2:(Intercept)",
      "mu2:x",
      "sigma1:(Intercept)",
      "sigma1:x",
      "sigma2:(Intercept)",
      "sigma2:x"
    ),
    dpar = rep(c("mu1", "mu2", "sigma1", "sigma2"), each = 2L),
    coefficient = rep(c("(Intercept)", "x"), 4L),
    endpoint_role = rep(c("intercept", "slope"), 4L),
    stringsAsFactors = FALSE
  )
}

phase18_q8_staged_fit_endpoint_values <- function(fit, truth) {
  if (is.null(fit)) {
    return(stats::setNames(numeric(), character()))
  }
  sd_mu <- phase18_q8_staged_named_values(
    fit$sdpars$mu,
    names(truth$sd_mu),
    "sd:mu:"
  )
  sd_sigma <- phase18_q8_staged_named_values(
    fit$sdpars$sigma,
    names(truth$sd_sigma),
    "sd:sigma:"
  )
  cor_re_cov <- phase18_q8_staged_named_values(
    fit$corpars$re_cov,
    names(truth$cor_re_cov),
    "cor:re_cov:"
  )
  residual_rho <- phase18_q8_staged_residual_rho12(fit)
  c(
    sd_mu,
    sd_sigma,
    cor_re_cov,
    c(rho12 = residual_rho)
  )
}

phase18_q8_staged_named_values <- function(x, expected, prefix) {
  out <- rep(NA_real_, length(expected))
  names(out) <- paste0(prefix, expected)
  if (is.null(x)) {
    return(out)
  }
  matched <- match(expected, names(x))
  ok <- !is.na(matched)
  out[ok] <- as.numeric(x[matched[ok]])
  out
}

phase18_q8_staged_residual_rho12 <- function(fit) {
  if (!is.null(fit$rho12)) {
    return(as.numeric(fit$rho12[[1L]]))
  }
  tryCatch(
    as.numeric(rho12(fit)[[1L]]),
    error = function(e) NA_real_
  )
}

phase18_q8_staged_match_estimates <- function(parameter, values) {
  out <- rep(NA_real_, length(parameter))
  matched <- match(parameter, names(values))
  ok <- !is.na(matched)
  out[ok] <- as.numeric(values[matched[ok]])
  out
}

phase18_q8_staged_availability_status <- function(
  captured_fit,
  parameter,
  values,
  estimate
) {
  if (!isTRUE(captured_fit$ok)) {
    return(rep("fit_failed", length(parameter)))
  }
  present <- parameter %in% names(values)
  ifelse(
    !present,
    "missing",
    ifelse(is.finite(estimate), "estimated", "nonfinite")
  )
}

phase18_q8_staged_point_status <- function(x) {
  out <- x$availability_status
  estimated <- x$availability_status == "estimated"
  clean_fit <- x$convergence == 0L &
    !is.na(x$pdHess) &
    x$pdHess &
    !is.na(x$fixed_gradient_status) &
    x$fixed_gradient_status == "ok" &
    !is.na(x$failure_mode) &
    x$failure_mode == "none"
  out[estimated & clean_fit] <- "diagnostic_clean_estimate"
  out[estimated & !clean_fit] <- "diagnostic_estimate_with_fit_warnings"
  out
}

phase18_q8_staged_availability_reason <- function(x) {
  out <- x$availability_status
  estimated <- x$availability_status == "estimated"
  detail <- paste(
    paste0("convergence=", x$convergence),
    paste0("pdHess=", x$pdHess),
    paste0("fixed_gradient_status=", x$fixed_gradient_status),
    paste0("failure_mode=", x$failure_mode),
    sep = "; "
  )
  out[estimated] <- detail[estimated]
  out
}

phase18_q8_staged_fit_metric <- function(captured_fit, column, default) {
  metrics <- captured_fit$metrics
  if (
    !is.data.frame(metrics) || !column %in% names(metrics) || nrow(metrics) < 1L
  ) {
    return(default)
  }
  value <- metrics[[column]][[1L]]
  if (length(value) == 0L) {
    return(default)
  }
  value
}

phase18_q8_staged_scope_row <- function(
  cell_id,
  replicate,
  elapsed,
  warnings
) {
  out <- phase18_q8_staged_empty_rows(
    1L,
    "scope",
    cell_id = cell_id,
    replicate = replicate,
    elapsed = elapsed,
    warnings = warnings
  )
  out$diagnostic_scope <- paste(
    "diagnostic_only: compares cold and staged optimizer starts for the same",
    "q8 target specification; supports triage of start strategies only"
  )
  out$unsupported_claims <- paste(
    "no q8 recovery, coverage, power, speed, interval, release-readiness,",
    "or public warm-start API claim; numerical guards require separate",
    "sensitivity simulations before inferential claims"
  )
  out
}

phase18_q8_staged_scalar_character <- function(x) {
  if (is.null(x) || length(x) == 0L || is.na(x[[1L]])) {
    return(NA_character_)
  }
  as.character(x[[1L]])
}

phase18_q8_staged_scalar_numeric <- function(x) {
  if (is.null(x) || length(x) == 0L || is.na(x[[1L]])) {
    return(NA_real_)
  }
  as.numeric(x[[1L]])
}

phase18_q8_staged_nrow <- function(x) {
  if (is.data.frame(x)) {
    return(nrow(x))
  }
  NA_integer_
}

phase18_summarise_biv_gaussian_q8_endpoint_staged_diagnostic <- function(
  conditions = phase18_biv_gaussian_q8_endpoint_conditions(
    n_id = 48L,
    n_each = 10L
  ),
  n_rep = 1L,
  master_seed = 20260636L,
  result_dir = NULL,
  overwrite = FALSE,
  cores = 1L,
  backend = "none",
  source_fit_fun = drmTMB,
  diagnostic_fun = drmTMB:::drm_qgt2_staged_fit_diagnostic
) {
  run <- phase18_run_biv_gaussian_q8_endpoint_staged_diagnostic(
    conditions = conditions,
    n_rep = n_rep,
    master_seed = master_seed,
    result_dir = result_dir,
    overwrite = overwrite,
    cores = cores,
    backend = backend,
    source_fit_fun = source_fit_fun,
    diagnostic_fun = diagnostic_fun
  )
  if (nrow(run$summary) == 0L) {
    stop(
      "The bivariate Gaussian q8 staged diagnostic produced no summaries.",
      call. = FALSE
    )
  }
  tables <- phase18_q8_staged_split_tables(run$summary)
  manifest <- phase18_result_manifest(run$results)
  failures <- phase18_result_failures(run$results)

  list(
    surface = "biv_gaussian_q8_endpoint_staged_diagnostic",
    run = run,
    metrics = tables$metrics,
    deltas = tables$deltas,
    provenance = tables$provenance,
    endpoint_status = tables$endpoint_status,
    scope = tables$scope,
    manifest = manifest,
    failures = failures
  )
}

phase18_q8_staged_split_tables <- function(summary) {
  if (!is.data.frame(summary) || nrow(summary) == 0L) {
    stop("`summary` must be a non-empty data frame.", call. = FALSE)
  }
  list(
    metrics = phase18_q8_staged_select(
      summary[summary$artifact_kind == "fit_metrics", , drop = FALSE],
      c(
        "surface",
        "cell_id",
        "replicate",
        "fit_label",
        "ok",
        "convergence",
        "pdHess",
        "objective",
        "logLik",
        "df",
        "nobs",
        "fit_elapsed_sec",
        "optimizer_preset",
        "optimizer_attempt_count",
        "optimizer_selected_attempt",
        "optimizer_retried",
        "optimizer_attempt_presets",
        "optimizer_attempt_statuses",
        "optimizer_message",
        "iterations",
        "function_evaluations",
        "gradient_evaluations",
        "iter_max",
        "eval_max",
        "budget_status",
        "sdreport_status",
        "sdreport_message",
        "se_requested",
        "fixed_gradient_status",
        "max_abs_gradient",
        "max_gradient_component",
        "gradient_tolerance",
        "failure_mode",
        "failure_detail",
        "fit_warning_count",
        "fit_warnings",
        "fit_error",
        "result_elapsed_sec",
        "run_warning_count",
        "run_warnings"
      )
    ),
    deltas = phase18_q8_staged_select(
      summary[summary$artifact_kind == "fit_deltas", , drop = FALSE],
      c(
        "surface",
        "cell_id",
        "replicate",
        "delta_metric",
        "cold",
        "staged",
        "staged_minus_cold"
      )
    ),
    provenance = phase18_q8_staged_select(
      summary[
        summary$artifact_kind == "start_provenance",
        ,
        drop = FALSE
      ],
      c(
        "surface",
        "cell_id",
        "replicate",
        "source_model_type",
        "target_model_type",
        "theta_re_cov",
        "theta_re_cov_shrink",
        "fixed_effect_match_count",
        "qgt2_sd_match_count",
        "qgt2_theta_match_count"
      )
    ),
    endpoint_status = phase18_q8_staged_select(
      summary[summary$artifact_kind == "endpoint_status", , drop = FALSE],
      c(
        "surface",
        "cell_id",
        "replicate",
        "fit_label",
        "ok",
        "convergence",
        "pdHess",
        "optimizer_attempt_count",
        "optimizer_selected_attempt",
        "optimizer_retried",
        "optimizer_attempt_presets",
        "optimizer_attempt_statuses",
        "optimizer_message",
        "iterations",
        "function_evaluations",
        "gradient_evaluations",
        "iter_max",
        "eval_max",
        "budget_status",
        "sdreport_status",
        "sdreport_message",
        "se_requested",
        "fixed_gradient_status",
        "max_abs_gradient",
        "max_gradient_component",
        "gradient_tolerance",
        "failure_mode",
        "failure_detail",
        "fit_warning_count",
        "fit_warnings",
        "fit_error",
        "parameter",
        "parameter_class",
        "endpoint_index",
        "endpoint",
        "endpoint_scope",
        "dpar",
        "coefficient",
        "endpoint_role",
        "truth",
        "estimate",
        "estimate_error",
        "availability_status",
        "point_status",
        "se_status",
        "availability_reason",
        "boundary_distance",
        "interval_status"
      )
    ),
    scope = phase18_q8_staged_select(
      summary[summary$artifact_kind == "scope", , drop = FALSE],
      c(
        "surface",
        "cell_id",
        "replicate",
        "diagnostic_scope",
        "unsupported_claims"
      )
    )
  )
}

phase18_q8_staged_select <- function(x, columns) {
  x[columns[columns %in% names(x)]]
}

phase18_write_biv_gaussian_q8_endpoint_staged_diagnostic_grid_outputs <-
  function(
    output_dir,
    conditions = phase18_biv_gaussian_q8_endpoint_conditions(
      n_id = 48L,
      n_each = 10L
    ),
    n_rep = 1L,
    master_seed = 20260636L,
    overwrite = FALSE,
    cores = 1L,
    backend = "none",
    source_fit_fun = drmTMB,
    diagnostic_fun = drmTMB:::drm_qgt2_staged_fit_diagnostic
  ) {
    if (
      !is.character(output_dir) ||
        length(output_dir) != 1L ||
        !nzchar(output_dir)
    ) {
      stop("`output_dir` must be one non-empty path string.", call. = FALSE)
    }
    if (!isTRUE(overwrite) && !identical(overwrite, FALSE)) {
      stop("`overwrite` must be TRUE or FALSE.", call. = FALSE)
    }

    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
    output_dir <- normalizePath(output_dir, mustWork = TRUE)
    result_dir <- file.path(output_dir, "results")
    table_dir <- file.path(output_dir, "tables")
    dir.create(result_dir, recursive = TRUE, showWarnings = FALSE)
    dir.create(table_dir, recursive = TRUE, showWarnings = FALSE)

    prefix <- "biv-gaussian-q8-endpoint-staged-diagnostic"
    paths <- list(
      metrics_csv = file.path(table_dir, paste0(prefix, "-metrics.csv")),
      deltas_csv = file.path(table_dir, paste0(prefix, "-deltas.csv")),
      provenance_csv = file.path(
        table_dir,
        paste0(prefix, "-provenance.csv")
      ),
      endpoint_status_csv = file.path(
        table_dir,
        paste0(prefix, "-endpoint-status.csv")
      ),
      scope_csv = file.path(table_dir, paste0(prefix, "-scope.csv")),
      manifest_csv = file.path(table_dir, paste0(prefix, "-manifest.csv")),
      failures_csv = file.path(table_dir, paste0(prefix, "-failures.csv"))
    )
    phase18_assert_biv_gaussian_q8_endpoint_staged_diagnostic_overwrite(
      paths,
      overwrite
    )

    summary <- phase18_summarise_biv_gaussian_q8_endpoint_staged_diagnostic(
      conditions = conditions,
      n_rep = n_rep,
      master_seed = master_seed,
      result_dir = result_dir,
      overwrite = overwrite,
      cores = cores,
      backend = backend,
      source_fit_fun = source_fit_fun,
      diagnostic_fun = diagnostic_fun
    )

    utils::write.csv(summary$metrics, paths$metrics_csv, row.names = FALSE)
    utils::write.csv(summary$deltas, paths$deltas_csv, row.names = FALSE)
    utils::write.csv(
      summary$provenance,
      paths$provenance_csv,
      row.names = FALSE
    )
    utils::write.csv(
      summary$endpoint_status,
      paths$endpoint_status_csv,
      row.names = FALSE
    )
    utils::write.csv(summary$scope, paths$scope_csv, row.names = FALSE)
    utils::write.csv(summary$manifest, paths$manifest_csv, row.names = FALSE)
    utils::write.csv(summary$failures, paths$failures_csv, row.names = FALSE)

    list(
      surface = "biv_gaussian_q8_endpoint_staged_diagnostic_grid",
      output_dir = output_dir,
      result_dir = result_dir,
      table_dir = table_dir,
      paths = paths,
      artifact_manifest = phase18_grid_artifact_manifest(
        "biv_gaussian_q8_endpoint_staged_diagnostic_grid",
        paths
      ),
      summary = summary
    )
  }

phase18_assert_biv_gaussian_q8_endpoint_staged_diagnostic_overwrite <-
  function(paths, overwrite) {
    path_values <- unlist(paths, use.names = FALSE)
    existing <- path_values[file.exists(path_values)]
    if (!overwrite && length(existing) > 0L) {
      stop(
        "Bivariate Gaussian q8 staged diagnostic output already exists: ",
        paste(existing, collapse = ", "),
        call. = FALSE
      )
    }
    invisible(paths)
  }
