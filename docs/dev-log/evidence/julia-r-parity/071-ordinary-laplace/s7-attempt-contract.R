# Pure validation for one S7 engine-target result.  Source
# prepare-s7-campaign-manifest.R first; this contract deliberately has no
# fitting, filesystem, or scheduler side effects.

r071_s7_attempt_key <- function(x) {
  if (!is.data.frame(x) || nrow(x) != 1L ||
      !all(c("logical_task_id", "fixture", "dgp_seed", "engine", "parm") %in% names(x))) {
    stop("S7 attempt key needs exactly one identified receipt row", call. = FALSE)
  }
  clean <- function(value) sub("_+$", "", gsub("[^A-Za-z0-9]+", "_", as.character(value)))
  paste(
    as.integer(x$logical_task_id[[1L]]), clean(x$fixture[[1L]]),
    as.integer(x$dgp_seed[[1L]]), clean(x$engine[[1L]]), clean(x$parm[[1L]]),
    sep = "-"
  )
}

r071_s7_diagnostic_columns <- function() {
  c(
    "estimate", "link_estimate", "std_error", "std_error_status",
    "convergence_status", "gradient_max_abs", "gradient_status",
    "hessian_status", "lower", "upper"
  )
}

r071_s7_complete_attempt <- function(
  logical_task_id, fixture, dgp_seed, engine, parm, truth,
  estimate, link_estimate, std_error, std_error_status,
  convergence_status, gradient_max_abs, gradient_status, hessian_status,
  fit_status, profile_status, lower, upper
) {
  out <- data.frame(
    logical_task_id = as.integer(logical_task_id), fixture = as.character(fixture),
    dgp_seed = as.integer(dgp_seed), engine = as.character(engine),
    parm = as.character(parm), truth = as.numeric(truth),
    estimate = as.numeric(estimate), link_estimate = as.numeric(link_estimate),
    std_error = as.numeric(std_error), std_error_status = as.character(std_error_status),
    convergence_status = as.character(convergence_status),
    gradient_max_abs = as.numeric(gradient_max_abs), gradient_status = as.character(gradient_status),
    hessian_status = as.character(hessian_status), fit_status = as.character(fit_status),
    profile_status = as.character(profile_status), lower = as.numeric(lower), upper = as.numeric(upper),
    stringsAsFactors = FALSE
  )
  r071_s7_validate_attempt(out)
  out
}

r071_s7_validate_diagnostics <- function(x) {
  required <- r071_s7_diagnostic_columns()
  present <- required %in% names(x)
  if (!any(present)) return(invisible(x))
  if (!all(present)) stop("attempt diagnostic classification schema drift", call. = FALSE)
  one_of <- function(column, values) {
    value <- x[[column]][[1L]]
    if (length(value) != 1L || is.na(value) || !value %in% values) {
      stop("attempt diagnostic classification is invalid for ", column, call. = FALSE)
    }
  }
  one_of("std_error_status", c("finite", "unavailable", "nonfinite", "fit_failed"))
  one_of("convergence_status", c("converged", "not_converged", "unavailable", "fit_failed"))
  one_of("gradient_status", c("finite", "unavailable", "nonfinite", "fit_failed"))
  one_of("hessian_status", c("positive_definite", "nonpositive", "unavailable", "fit_failed"))
  if (identical(x$std_error_status[[1L]], "finite") &&
      (!is.finite(x$std_error[[1L]]) || x$std_error[[1L]] < 0)) {
    stop("finite standard-error status needs a finite non-negative value", call. = FALSE)
  }
  if (identical(x$gradient_status[[1L]], "finite") &&
      (!is.finite(x$gradient_max_abs[[1L]]) || x$gradient_max_abs[[1L]] < 0)) {
    stop("finite gradient status needs a finite non-negative value", call. = FALSE)
  }
  if (identical(x$fit_status[[1L]], "fit_failed") && any(c(
    x$std_error_status[[1L]], x$convergence_status[[1L]],
    x$gradient_status[[1L]], x$hessian_status[[1L]]
  ) != "fit_failed")) {
    stop("failed fits require fit_failed diagnostic classifications", call. = FALSE)
  }
  invisible(x)
}

r071_s7_validate_attempt <- function(x) {
  required <- c("logical_task_id", "fixture", "dgp_seed", "engine", "parm", "truth",
                "fit_status", "profile_status")
  if (!is.data.frame(x) || nrow(x) != 1L || !all(required %in% names(x))) {
    stop("S7 attempt receipt schema drift", call. = FALSE)
  }
  if (!exists("r071_s7_profile_plan", mode = "function", inherits = TRUE)) {
    stop("source prepare-s7-campaign-manifest.R before the S7 attempt contract", call. = FALSE)
  }
  plan <- r071_s7_profile_plan()
  hit <- plan[plan$fixture == x$fixture[[1L]] & plan$engine == x$engine[[1L]] &
                plan$parm == x$parm[[1L]], , drop = FALSE]
  if (nrow(hit) != 1L) stop("attempt is absent from frozen profile plan", call. = FALSE)
  if (!is.finite(x$truth[[1L]]) || !isTRUE(all.equal(as.numeric(x$truth[[1L]]), hit$truth[[1L]], tolerance = 1e-12))) {
    stop("attempt truth does not match frozen profile plan", call. = FALSE)
  }
  terminal <- c("profile", "fit_failed", "profile_failed", "nonfinite_endpoint", "truth_outside")
  if (!x$fit_status[[1L]] %in% c("returned", "fit_failed") || !x$profile_status[[1L]] %in% terminal) {
    stop("attempt receipt must carry terminal fit and profile statuses", call. = FALSE)
  }
  if (identical(x$fit_status[[1L]], "fit_failed") && !identical(x$profile_status[[1L]], "fit_failed")) {
    stop("a failed fit must retain fit_failed as its terminal profile status", call. = FALSE)
  }
  r071_s7_validate_diagnostics(x)
  invisible(x)
}

r071_s7_expected_attempts <- function(manifest, profile_plan) {
  r071_s7_validate_manifest(manifest)
  r071_s7_validate_profile_plan(profile_plan)
  rows <- lapply(seq_len(nrow(manifest)), function(i) {
    task <- manifest[i, , drop = FALSE]
    targets <- profile_plan[profile_plan$fixture == task$fixture[[1L]], , drop = FALSE]
    data.frame(
      logical_task_id = rep.int(task$logical_task_id[[1L]], nrow(targets)),
      fixture = rep.int(task$fixture[[1L]], nrow(targets)),
      dgp_seed = rep.int(task$dgp_seed[[1L]], nrow(targets)),
      engine = targets$engine,
      parm = targets$parm,
      truth = targets$truth,
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  if (nrow(out) != sum(manifest$profile_attempt_count) || anyDuplicated(vapply(seq_len(nrow(out)), function(i) r071_s7_attempt_key(out[i, , drop = FALSE]), character(1L)))) {
    stop("S7 expected-attempt bijection drift", call. = FALSE)
  }
  out
}

r071_s7_reconcile_attempts <- function(manifest, profile_plan, attempts) {
  expected <- r071_s7_expected_attempts(manifest, profile_plan)
  required <- c("logical_task_id", "fixture", "dgp_seed", "engine", "parm", "truth",
                "fit_status", "profile_status", r071_s7_diagnostic_columns())
  if (!is.data.frame(attempts) || !all(required %in% names(attempts))) {
    stop("S7 reconciliation diagnostic receipt schema drift", call. = FALSE)
  }
  expected_key <- vapply(seq_len(nrow(expected)), function(i) r071_s7_attempt_key(expected[i, , drop = FALSE]), character(1L))
  observed_key <- vapply(seq_len(nrow(attempts)), function(i) r071_s7_attempt_key(attempts[i, , drop = FALSE]), character(1L))
  if (nrow(attempts) != nrow(expected) || anyDuplicated(observed_key) || !setequal(observed_key, expected_key)) {
    stop("S7 reconciliation has missing or duplicate attempt keys", call. = FALSE)
  }
  ordered <- attempts[match(expected_key, observed_key), , drop = FALSE]
  if (!isTRUE(all.equal(as.numeric(ordered$truth), as.numeric(expected$truth), tolerance = 1e-12))) {
    stop("S7 reconciliation truth does not match the frozen profile plan", call. = FALSE)
  }
  terminal <- c("profile", "fit_failed", "profile_failed", "nonfinite_endpoint", "truth_outside")
  if (any(!ordered$fit_status %in% c("returned", "fit_failed")) ||
      any(!ordered$profile_status %in% terminal) ||
      any(ordered$fit_status == "fit_failed" & ordered$profile_status != "fit_failed")) {
    stop("S7 reconciliation requires terminal, internally consistent attempt statuses", call. = FALSE)
  }
  diagnostic_levels <- list(
    std_error_status = c("finite", "unavailable", "nonfinite", "fit_failed"),
    convergence_status = c("converged", "not_converged", "unavailable", "fit_failed"),
    gradient_status = c("finite", "unavailable", "nonfinite", "fit_failed"),
    hessian_status = c("positive_definite", "nonpositive", "unavailable", "fit_failed")
  )
  if (any(vapply(names(diagnostic_levels), function(column) {
    any(is.na(ordered[[column]]) | !ordered[[column]] %in% diagnostic_levels[[column]])
  }, logical(1L))) ||
      any(ordered$std_error_status == "finite" & (!is.finite(ordered$std_error) | ordered$std_error < 0)) ||
      any(ordered$gradient_status == "finite" & (!is.finite(ordered$gradient_max_abs) | ordered$gradient_max_abs < 0)) ||
      any(ordered$fit_status == "fit_failed" & (
        ordered$std_error_status != "fit_failed" |
          ordered$convergence_status != "fit_failed" |
          ordered$gradient_status != "fit_failed" |
          ordered$hessian_status != "fit_failed"
      ))) {
    stop("S7 reconciliation requires complete diagnostic classifications", call. = FALSE)
  }
  list(
    attempt_count = nrow(ordered),
    profile_count = sum(ordered$profile_status == "profile"),
    fit_failed_count = sum(ordered$profile_status == "fit_failed"),
    profile_failed_count = sum(ordered$profile_status == "profile_failed"),
    nonfinite_endpoint_count = sum(ordered$profile_status == "nonfinite_endpoint"),
    truth_outside_count = sum(ordered$profile_status == "truth_outside")
  )
}
