#!/usr/bin/env Rscript
# Convert one fitted engine-target attempt into a terminal S7 receipt.  The
# scheduler runner supplies the real fitting function only after G7 approval;
# this layer is independently testable and has no scheduler side effects.

r071_s7_spec_row <- function(spec) {
  required <- c("logical_task_id", "fixture", "dgp_seed", "engine", "parm", "truth")
  if (!is.data.frame(spec) || nrow(spec) != 1L || !all(required %in% names(spec)) ||
      !spec$engine[[1L]] %in% c("tmb", "julia")) {
    stop("S7 fitted-attempt receipt needs exactly one valid task specification", call. = FALSE)
  }
  spec
}

r071_s7_fit_failed_attempt <- function(spec) {
  spec <- r071_s7_spec_row(spec)
  r071_s7_complete_attempt(
    logical_task_id = spec$logical_task_id, fixture = spec$fixture,
    dgp_seed = spec$dgp_seed, engine = spec$engine, parm = spec$parm,
    truth = spec$truth, estimate = NA_real_, link_estimate = NA_real_,
    std_error = NA_real_, std_error_status = "fit_failed",
    convergence_status = "fit_failed", gradient_max_abs = NA_real_,
    gradient_status = "fit_failed", hessian_status = "fit_failed",
    fit_status = "fit_failed", profile_status = "fit_failed",
    lower = NA_real_, upper = NA_real_
  )
}

r071_s7_attempt_from_fit <- function(
  fit, spec,
  target_inventory = function(object) profile_targets(object),
  profile_fun = stats::confint
) {
  spec <- r071_s7_spec_row(spec)
  targets <- target_inventory(fit)
  if (!is.data.frame(targets) || !all(c("parm", "estimate", "link_estimate", "tmb_parameter", "index", "transformation") %in% names(targets))) {
    stop("S7 profile-target inventory is incomplete", call. = FALSE)
  }
  target <- targets[targets$parm == spec$parm[[1L]], , drop = FALSE]
  if (nrow(target) != 1L) {
    stop("S7 frozen target is absent from the returned fit inventory", call. = FALSE)
  }
  diagnostic <- r071_s7_fit_diagnostics(fit, target, engine = spec$engine[[1L]])
  profile_args <- list(object = fit, parm = spec$parm[[1L]], method = "profile")
  if (identical(spec$engine[[1L]], "julia")) profile_args$threads <- FALSE
  result <- tryCatch(do.call(profile_fun, profile_args), error = identity)
  lower <- if (is.data.frame(result) && "lower" %in% names(result)) as.numeric(result$lower[[1L]]) else NA_real_
  upper <- if (is.data.frame(result) && "upper" %in% names(result)) as.numeric(result$upper[[1L]]) else NA_real_
  profile_status <- if (inherits(result, "error")) {
    "profile_failed"
  } else if (!is.finite(lower) || !is.finite(upper)) {
    "nonfinite_endpoint"
  } else if (spec$truth[[1L]] < lower || spec$truth[[1L]] > upper) {
    "truth_outside"
  } else {
    "profile"
  }
  r071_s7_complete_attempt(
    logical_task_id = spec$logical_task_id, fixture = spec$fixture,
    dgp_seed = spec$dgp_seed, engine = spec$engine, parm = spec$parm,
    truth = spec$truth, estimate = target$estimate[[1L]],
    link_estimate = target$link_estimate[[1L]],
    std_error = diagnostic$std_error, std_error_status = diagnostic$std_error_status,
    convergence_status = diagnostic$convergence_status,
    gradient_max_abs = diagnostic$gradient_max_abs,
    gradient_status = diagnostic$gradient_status, hessian_status = diagnostic$hessian_status,
    fit_status = "returned", profile_status = profile_status, lower = lower, upper = upper
  )
}
