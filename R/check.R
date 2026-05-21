#' Check convergence and diagnostic flags for a drmTMB fit
#'
#' `check_drm()` runs a compact set of model-fit diagnostics. It is intended as
#' a first-pass guardrail before interpreting distributional models, especially
#' fits with random effects, known sampling covariance, phylogenetic location
#' effects, or bivariate residual correlation `rho12`.
#'
#' The current checks cover optimizer convergence, finite objective values,
#' optimizer evaluation counts, fixed-parameter gradients including the largest
#' gradient component label, whether
#' [TMB::sdreport()] was computed, skipped, or failed, Hessian status from
#' [TMB::sdreport()], finite fixed-effect standard errors, dropped rows,
#' positive scale parameters, random-effect standard deviations near the lower
#' boundary, bivariate residual-correlation `rho12` values near the boundary,
#' Student-t `nu` boundary behaviour, known sampling covariance summaries,
#' dense known-covariance storage scale, dense fixed-effect design size and
#' density, random-effect replication, and random-slope design variation. If a
#' univariate Gaussian fit includes one or more matched labelled
#' `mu`/`sigma` random-intercept covariance blocks, `check_drm()` also reports
#' group replication and whether either component is tiny relative to its
#' interpretation scale for each independent block. If a bivariate Gaussian fit
#' includes one or more matched same-response labelled `mu`/`sigma`
#' random-intercept covariance blocks, `check_drm()` reports one row per block.
#' If a bivariate Gaussian fit includes a matched
#' labelled `mu1`/`mu2` random-intercept covariance block, `check_drm()` reports
#' group replication and whether either group-level SD is tiny relative to the
#' matching residual scale. For a matched labelled `sigma1`/`sigma2` block, it
#' reports group replication and whether either log-`sigma` random-effect SD is
#' tiny. If a bivariate Gaussian fit includes an ordinary all-four q=4
#' `mu1`/`mu2`/`sigma1`/`sigma2` block, it reports group replication, location
#' SDs relative to residual scales, log-`sigma` SDs, and whether any latent
#' correlation is near the boundary. If a bivariate Gaussian fit includes
#' matching `mu1`/`mu2` phylogenetic location effects, `check_drm()` also reports
#' whether the fitted phylogenetic mean-mean correlation is near the boundary,
#' whether either phylogenetic SD is tiny relative to the matching residual
#' scale, and whether an ordinary group-level covariance block uses the same
#' grouping factor. Matching bivariate coordinate-spatial q=2, `animal()`, and
#' `relmat()` q=2 location effects receive the corresponding structured
#' replication and SD-ratio diagnostics. If a bivariate Gaussian fit includes a
#' phylogenetic, coordinate-spatial, animal-model, or `relmat()` q=4
#' `mu1`/`mu2`/`sigma1`/`sigma2` block, it reports level replication, location
#' SDs relative to residual scales, log-`sigma` SDs, and whether any latent
#' structured correlation is near the boundary. If a univariate
#' Gaussian fit includes `phylo(1 | species, tree = tree)` or
#' `phylo(1 + x | species, tree = tree)` in `mu`, it reports species
#' replication, the fitted phylogenetic SDs, and whether the smallest
#' phylogenetic SD is tiny relative to the residual scale. If a univariate
#' Gaussian fit includes `spatial(1 | site, coords = coords)` or
#' `spatial(1 + x | site, coords = coords)` in `mu`, it reports site
#' replication, fitted coordinate range, the spatial SDs, and whether the
#' smallest spatial SD is tiny relative to the residual scale. If a Gaussian
#' fit includes `sd_phylo(species) ~ x_species`,
#' `sd_phylo1(species) ~ x_species`, or
#' `sd_phylo2(species) ~ x_species`, it reports species replication and the
#' fitted direct-SD surface range. If a univariate Gaussian fit used
#' `drm_control(aggregate_gaussian = TRUE)`, it reports original rows,
#' aggregation cells, compression ratio, and largest cell size. If a fit was
#' stored with
#' `drm_control(keep_tmb_object = FALSE)`, the
#' fixed-gradient check is reported as a note because the TMB
#' automatic-differentiation object is not available. If a fit used
#' `drm_control(se = FALSE)`, the `sdreport_status`, Hessian, and
#' finite-standard-error checks are reported as notes. If `sdreport()` was
#' requested but failed, those rows are warnings.
#'
#' Use `check_drm()` before interpreting coefficients, fitted values, or
#' response-scale quantities. A `note` records something to inspect, such as
#' dropped rows or a singly observed random-effect level. A `warning` means the
#' fitted model may still be useful but needs inspection before inference. An
#' `error` means at least one basic diagnostic failed. For programmatic checks,
#' the returned object has `attr(x, "ok") == TRUE` only when no rows have
#' `warning` or `error` status.
#'
#' @param object A `drmTMB` fit.
#' @param gradient_tolerance Maximum absolute fixed-parameter gradient treated
#'   as acceptable.
#' @param rho_boundary Absolute residual or structured correlation value above
#'   which a bivariate Gaussian fit receives a warning.
#' @param sd_boundary Random-effect standard deviation below which a fit
#'   receives a warning that the variance component is near the lower
#'   boundary.
#' @param ... Reserved for future diagnostic options.
#'
#' @return A data frame of checks with columns `check`, `status`, `value`, and
#'   `message`. The returned object has class `drm_check`.
#' @export
#'
#' @examples
#' set.seed(1)
#' dat <- data.frame(y = rnorm(40), x = rnorm(40))
#' fit <- drmTMB(drm_formula(y ~ x, sigma ~ x), data = dat)
#' check_drm(fit)
check_drm <- function(object, ...) {
  UseMethod("check_drm")
}

#' @rdname check_drm
#' @export
check_drm.drmTMB <- function(
  object,
  gradient_tolerance = 1e-3,
  rho_boundary = 0.98,
  sd_boundary = 1e-4,
  ...
) {
  dots <- list(...)
  if (length(dots) > 0L) {
    cli::cli_abort(
      "{.arg ...} is reserved for future {.fn check_drm} diagnostic options."
    )
  }
  validate_check_scalar(gradient_tolerance, "gradient_tolerance", lower = 0)
  validate_check_scalar(rho_boundary, "rho_boundary", lower = 0, upper = 1)
  validate_check_scalar(sd_boundary, "sd_boundary", lower = 0)

  rows <- list(
    check_optimizer_convergence(object),
    check_optimizer_budget(object),
    check_finite_objective(object),
    check_fixed_gradient(object, gradient_tolerance = gradient_tolerance),
    check_sdreport_status(object),
    check_hessian(object),
    check_standard_errors_finite(object),
    check_dropped_rows(object),
    check_scale_positive(object),
    check_random_effect_sd_boundary(object, sd_boundary = sd_boundary),
    check_rho12_boundary(object, rho_boundary = rho_boundary),
    check_student_nu(object),
    check_known_v(object),
    check_fixed_effect_design_size(object),
    check_gaussian_aggregation(object),
    check_random_effect_replication(object, "mu"),
    check_random_effect_replication(object, "sigma"),
    check_random_effect_design(object, "mu"),
    check_random_effect_design(object, "sigma"),
    check_mu_sigma_random_effect_covariance(object),
    check_biv_mu_sigma_random_effect_covariance(object),
    check_biv_mu_random_effect_covariance(object),
    check_biv_sigma_random_effect_covariance(object),
    check_biv_q4_random_effect_covariance(
      object,
      rho_boundary = rho_boundary
    ),
    check_phylo_replication(object),
    check_phylo_mu_diagnostics(object),
    check_spatial_mu_diagnostics(object),
    check_known_relatedness_mu_diagnostics(object),
    check_phylo_direct_sd_model(object),
    check_biv_phylo_mu_covariance(object, rho_boundary = rho_boundary),
    check_biv_structured_q4_covariance(object, rho_boundary = rho_boundary)
  )
  rows <- Filter(Negate(is.null), rows)
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  class(out) <- c("drm_check", "data.frame")
  attr(out, "ok") <- !any(out$status %in% c("warning", "error"))
  out
}

#' @export
print.drm_check <- function(x, ...) {
  cli::cli_text("<drm_check: {nrow(x)} checks>")
  n_warn <- sum(x$status == "warning")
  n_error <- sum(x$status == "error")
  n_note <- sum(x$status == "note")
  cli::cli_text(
    "  ok: {sum(x$status == 'ok')}; notes: {n_note}; warnings: {n_warn}; errors: {n_error}"
  )
  print.data.frame(x, row.names = FALSE, ...)
  invisible(x)
}

check_row <- function(check, status, value, message) {
  data.frame(
    check = check,
    status = status,
    value = as.character(value),
    message = as.character(message),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

validate_check_scalar <- function(x, name, lower = -Inf, upper = Inf) {
  if (
    !is.numeric(x) ||
      length(x) != 1L ||
      is.na(x) ||
      !is.finite(x) ||
      x <= lower ||
      x >= upper
  ) {
    cli::cli_abort(
      "{.arg {name}} must be a finite numeric scalar between {lower} and {upper}."
    )
  }
  invisible(x)
}

check_optimizer_convergence <- function(object) {
  convergence <- object$opt$convergence
  ok <- identical(as.integer(convergence), 0L)
  message <- if (ok) {
    "nlminb convergence code is 0."
  } else {
    paste("nlminb convergence message:", object$opt$message)
  }
  check_row(
    "optimizer_convergence",
    if (ok) "ok" else "warning",
    convergence,
    message
  )
}

check_optimizer_budget <- function(object) {
  iterations <- object$opt$iterations
  evaluations <- object$opt$evaluations
  function_evaluations <- optimizer_evaluation_count(evaluations, "function")
  gradient_evaluations <- optimizer_evaluation_count(evaluations, "gradient")

  control <- object$control$optimizer
  if (is.null(control)) {
    control <- list()
  }
  iter_max <- optimizer_budget_limit(control, "iter.max")
  eval_max <- optimizer_budget_limit(control, "eval.max")

  hit_iter <- optimizer_budget_reached(iterations, iter_max)
  hit_eval <- optimizer_budget_reached(function_evaluations, eval_max)
  hit_budget <- hit_iter || hit_eval
  converged <- identical(as.integer(object$opt$convergence), 0L)

  value <- paste0(
    "iterations=",
    format_optimizer_count(iterations),
    "; function=",
    format_optimizer_count(function_evaluations),
    "; gradient=",
    format_optimizer_count(gradient_evaluations)
  )
  message <- if (hit_budget) {
    paste(
      "Optimizer reached a supplied evaluation or iteration limit;",
      "inspect convergence, gradients, and model structure before increasing",
      "`eval.max` or `iter.max`."
    )
  } else if (length(control) > 0L) {
    "Optimizer stayed below supplied evaluation and iteration limits."
  } else {
    "Optimizer evaluation counts recorded; no eval.max or iter.max control was supplied."
  }

  check_row(
    "optimizer_budget",
    if (hit_budget && !converged) {
      "warning"
    } else if (hit_budget) {
      "note"
    } else {
      "ok"
    },
    value,
    message
  )
}

optimizer_evaluation_count <- function(evaluations, name) {
  if (is.null(evaluations) || is.null(evaluations[[name]])) {
    return(NA_real_)
  }
  as.numeric(evaluations[[name]])
}

optimizer_budget_limit <- function(control, name) {
  if (is.null(control[[name]])) {
    return(NA_real_)
  }
  as.numeric(control[[name]])
}

optimizer_budget_reached <- function(count, limit) {
  length(count) == 1L &&
    length(limit) == 1L &&
    is.finite(count) &&
    is.finite(limit) &&
    count >= limit
}

format_optimizer_count <- function(x) {
  if (length(x) != 1L || !is.finite(x)) {
    return("NA")
  }
  as.character(as.integer(x))
}

check_finite_objective <- function(object) {
  values <- c(object$opt$objective, object$logLik)
  ok <- all(is.finite(values))
  check_row(
    "finite_objective",
    if (ok) "ok" else "error",
    format_check_number(object$opt$objective),
    if (ok) {
      "Objective and log-likelihood are finite."
    } else {
      "Objective or log-likelihood is not finite."
    }
  )
}

check_fixed_gradient <- function(object, gradient_tolerance) {
  if (is.null(object$obj)) {
    return(check_row(
      "fixed_gradient",
      "note",
      NA_character_,
      paste(
        "TMB object was not retained;",
        "refit with drm_control(keep_tmb_object = TRUE) to check fixed gradients."
      )
    ))
  }
  gradient <- tryCatch(
    as.numeric(object$obj$gr(object$opt$par)),
    error = function(e) e
  )
  if (inherits(gradient, "error")) {
    return(check_row(
      "fixed_gradient",
      "warning",
      NA_character_,
      paste("Could not evaluate TMB gradient:", conditionMessage(gradient))
    ))
  }
  if (!all(is.finite(gradient))) {
    return(check_row(
      "fixed_gradient",
      "error",
      NA_character_,
      "At least one fixed-parameter gradient is not finite."
    ))
  }
  max_abs <- max(abs(gradient), 0)
  max_index <- if (length(gradient) > 0L) {
    which.max(abs(gradient))
  } else {
    NA_integer_
  }
  max_component <- fixed_gradient_component_label(object, gradient, max_index)
  ok <- max_abs <= gradient_tolerance
  check_row(
    "fixed_gradient",
    if (ok) "ok" else "warning",
    paste0(
      "max=",
      format_check_number(max_abs),
      "; component=",
      max_component
    ),
    if (ok) {
      paste0(
        "Maximum absolute fixed gradient is <= ",
        gradient_tolerance,
        "; largest component is ",
        max_component,
        "."
      )
    } else {
      paste0(
        "Maximum absolute fixed gradient is > ",
        gradient_tolerance,
        "; largest component is ",
        max_component,
        "."
      )
    }
  )
}

fixed_gradient_component_label <- function(object, gradient, index) {
  if (length(index) != 1L || is.na(index)) {
    return("none")
  }
  labels <- names(object$opt$par)
  if (is.null(labels) || length(labels) != length(gradient)) {
    labels <- names(gradient)
  }
  if (is.null(labels) || length(labels) != length(gradient)) {
    labels <- paste0("par", seq_along(gradient))
  }
  labels[is.na(labels) | !nzchar(labels)] <- paste0(
    "par",
    which(is.na(labels) | !nzchar(labels))
  )
  labels <- disambiguate_duplicate_labels(labels)
  labels[[index]]
}

disambiguate_duplicate_labels <- function(labels) {
  duplicated_labels <- labels %in% labels[duplicated(labels)]
  if (!any(duplicated_labels)) {
    return(labels)
  }
  sequence <- stats::ave(seq_along(labels), labels, FUN = seq_along)
  labels[duplicated_labels] <- paste0(
    labels[duplicated_labels],
    "[",
    sequence[duplicated_labels],
    "]"
  )
  labels
}

check_hessian <- function(object) {
  if (is.null(object$sdr)) {
    return(check_row(
      "hessian_positive_definite",
      drm_uncertainty_check_status(object),
      NA_character_,
      paste(
        "Hessian status is unavailable because",
        drm_uncertainty_message(object)
      )
    ))
  }
  pd_hess <- isTRUE(object$sdr$pdHess)
  check_row(
    "hessian_positive_definite",
    if (pd_hess) "ok" else "warning",
    pd_hess,
    if (pd_hess) {
      "sdreport reports a positive-definite Hessian."
    } else {
      "sdreport does not report a positive-definite Hessian."
    }
  )
}

check_sdreport_status <- function(object) {
  status <- drm_uncertainty_status(object)
  check_row(
    "sdreport_status",
    switch(
      status,
      ok = "ok",
      skipped = "note",
      failed = "warning",
      "warning"
    ),
    status,
    drm_uncertainty_message(object)
  )
}

check_standard_errors_finite <- function(object) {
  vcov <- tryCatch(stats::vcov(object), error = function(e) e)
  if (inherits(vcov, "error")) {
    return(check_row(
      "standard_errors_finite",
      drm_uncertainty_check_status(object),
      NA_character_,
      paste(
        "Could not extract fixed-effect standard errors:",
        conditionMessage(vcov)
      )
    ))
  }

  variances <- diag(vcov)
  standard_errors <- rep(NA_real_, length(variances))
  non_negative <- is.finite(variances) & variances >= 0
  standard_errors[non_negative] <- sqrt(variances[non_negative])
  ok <- length(standard_errors) > 0L &&
    all(is.finite(standard_errors)) &&
    all(variances >= 0)
  finite_standard_errors <- standard_errors[is.finite(standard_errors)]
  value <- if (length(finite_standard_errors) == 0L) {
    NA_character_
  } else {
    paste0(
      "range=[",
      format_check_number(min(finite_standard_errors)),
      ",",
      format_check_number(max(finite_standard_errors)),
      "]"
    )
  }

  check_row(
    "standard_errors_finite",
    if (ok) "ok" else "warning",
    value,
    if (ok) {
      "All fixed-effect standard errors are finite."
    } else {
      "At least one fixed-effect standard error is non-finite; inspect Hessian status, identifiability, and model scaling."
    }
  )
}

check_dropped_rows <- function(object) {
  keep <- object$model$keep
  if (is.null(keep)) {
    return(check_row(
      "dropped_rows",
      "note",
      NA_character_,
      "Original row filter is not stored on this fit."
    ))
  }
  dropped <- sum(!keep)
  check_row(
    "dropped_rows",
    if (dropped == 0L) "ok" else "note",
    paste0("nobs=", object$nobs, "; dropped=", dropped),
    if (dropped == 0L) {
      "No rows were dropped by model-frame or known-covariance filtering."
    } else {
      "Rows were dropped by complete-case or known-covariance filtering."
    }
  )
}

check_gaussian_aggregation <- function(object) {
  aggregation <- if (is.list(object$model$aggregation)) {
    object$model$aggregation$gaussian
  } else {
    NULL
  }
  summary <- drm_gaussian_aggregation_summary(aggregation)
  if (is.null(summary)) {
    return(NULL)
  }
  row <- summary[1L, , drop = FALSE]
  ratio <- row$compression_ratio[[1L]]
  check_row(
    "gaussian_aggregation",
    if (ratio > 1) "ok" else "note",
    paste0(
      "original_rows=",
      row$original_rows[[1L]],
      "; aggregation_cells=",
      row$aggregation_cells[[1L]],
      "; compression_ratio=",
      format_check_number(ratio),
      "; largest_cell_n=",
      row$largest_cell_n[[1L]]
    ),
    if (ratio > 1) {
      "Gaussian aggregation compressed repeated fixed-effect likelihood rows before TMB optimization."
    } else {
      "Gaussian aggregation was enabled, but no fixed-effect likelihood rows were collapsed."
    }
  )
}

check_scale_positive <- function(object) {
  scale_values <- tryCatch(stats::sigma(object), error = function(e) e)
  if (inherits(scale_values, "error")) {
    return(check_row(
      "positive_scale",
      "warning",
      NA_character_,
      paste("Could not extract scale values:", conditionMessage(scale_values))
    ))
  }
  scale_values <- unlist(scale_values, use.names = FALSE)
  ok <- length(scale_values) > 0L &&
    all(is.finite(scale_values)) &&
    all(scale_values > 0)
  check_row(
    "positive_scale",
    if (ok) "ok" else "error",
    paste0("min=", format_check_number(min(scale_values, na.rm = TRUE))),
    if (ok) {
      "All fitted scale values are finite and positive."
    } else {
      "At least one fitted scale value is non-positive or non-finite."
    }
  )
}

check_random_effect_sd_boundary <- function(object, sd_boundary) {
  sd_values <- unlist(object$sdpars, use.names = TRUE)
  if (length(sd_values) == 0L) {
    return(NULL)
  }
  if (is.null(names(sd_values))) {
    names(sd_values) <- paste0("sd", seq_along(sd_values))
  }
  missing_names <- !nzchar(names(sd_values)) | is.na(names(sd_values))
  names(sd_values)[missing_names] <- paste0("sd", which(missing_names))

  ok <- all(is.finite(sd_values)) && all(sd_values > 0)
  if (!ok) {
    return(check_row(
      "random_effect_sd_boundary",
      "error",
      NA_character_,
      "At least one fitted random-effect standard deviation is non-positive or non-finite."
    ))
  }

  min_index <- which.min(sd_values)
  min_value <- sd_values[[min_index]]
  min_name <- names(sd_values)[[min_index]]
  near_boundary <- min_value < sd_boundary

  check_row(
    "random_effect_sd_boundary",
    if (near_boundary) "warning" else "ok",
    paste0(
      "min=",
      format_check_number(min_value),
      "; boundary=",
      format_check_number(sd_boundary),
      "; term=",
      min_name
    ),
    if (near_boundary) {
      "At least one fitted random-effect standard deviation is near the lower boundary at zero."
    } else {
      "All fitted random-effect standard deviations are finite, positive, and above the requested lower-boundary warning threshold."
    }
  )
}

check_rho12_boundary <- function(object, rho_boundary) {
  if (!identical(object$model$model_type, "biv_gaussian")) {
    return(NULL)
  }
  rho <- rho12(object)
  max_abs <- max(abs(rho), 0)
  ok <- all(is.finite(rho)) && max_abs <= rho_boundary
  check_row(
    "rho12_boundary",
    if (ok) "ok" else "warning",
    format_check_number(max_abs),
    if (ok) {
      paste0(
        "All fitted residual correlations have absolute value <= ",
        rho_boundary,
        "."
      )
    } else {
      paste0(
        "At least one fitted residual correlation is close to +/-1 using boundary ",
        rho_boundary,
        "."
      )
    }
  )
}

check_student_nu <- function(object) {
  if (!identical(object$model$model_type, "student")) {
    return(NULL)
  }
  nu <- tryCatch(predict(object, dpar = "nu"), error = function(e) e)
  if (inherits(nu, "error")) {
    return(check_row(
      "student_nu",
      "warning",
      NA_character_,
      paste("Could not extract Student-t nu values:", conditionMessage(nu))
    ))
  }
  if (!all(is.finite(nu)) || any(nu <= 2)) {
    return(check_row(
      "student_nu",
      "error",
      NA_character_,
      "At least one fitted Student-t nu value is non-finite or not above 2."
    ))
  }

  min_nu <- min(nu)
  max_nu <- max(nu)
  value <- paste0(
    "range=[",
    format_check_number(min_nu),
    ",",
    format_check_number(max_nu),
    "]"
  )
  if (min_nu < 2.05) {
    return(check_row(
      "student_nu",
      "warning",
      value,
      "At least one fitted Student-t nu value is very close to the finite-variance boundary at 2."
    ))
  }
  if (max_nu > 100) {
    return(check_row(
      "student_nu",
      "note",
      value,
      "At least one fitted Student-t nu value is large; compare against a Gaussian model because tails may be nearly Gaussian."
    ))
  }
  check_row(
    "student_nu",
    "ok",
    value,
    "All fitted Student-t nu values are finite and above the boundary at 2."
  )
}

check_known_v <- function(object) {
  if (!isTRUE(object$model$has_known_v)) {
    return(NULL)
  }
  known_type <- object$model$V_known_type
  known_diag <- known_v_diag(object)
  ok <- all(is.finite(known_diag)) && all(known_diag >= 0)
  if (identical(known_type, "matrix")) {
    V <- object$model$V_known
    eig <- eigen(
      (V + t(V)) / 2,
      symmetric = TRUE,
      only.values = TRUE
    )$values
    tol <- sqrt(.Machine$double.eps) * max(abs(eig), 1)
    rank <- sum(eig > tol)
    positive_eig <- eig[eig > tol]
    condition <- if (length(positive_eig) == 0L) {
      Inf
    } else {
      max(positive_eig) / min(positive_eig)
    }
    storage <- known_v_dense_storage_summary(V)
    status <- if (!ok) {
      "error"
    } else {
      "note"
    }
    return(check_row(
      "known_sampling_covariance",
      status,
      paste0(
        "type=matrix; n=",
        length(eig),
        "; storage=dense; density=",
        format_check_number(storage$density),
        "; size_mb=",
        format_check_number(storage$size_mb),
        "; rank=",
        rank,
        "; cond=",
        format_check_number(condition)
      ),
      if (identical(status, "error")) {
        "Known sampling covariance has a non-finite or negative diagonal entry."
      } else if (rank < length(eig) || condition > 1e8) {
        paste(
          "Known sampling covariance is recorded as a dense matrix;",
          "inspect rank or conditioning if estimates are unstable, and treat dense V as small-to-moderate until sparse or block-sparse storage is implemented."
        )
      } else if (storage$density <= 0.25) {
        paste(
          "Known sampling covariance is recorded as a dense matrix with many zero entries;",
          "large block-structured V will need sparse or block-sparse storage before being treated as scalable."
        )
      } else {
        paste(
          "Known sampling covariance is recorded as a dense matrix with finite non-negative diagonal;",
          "treat this as a small-to-moderate path until sparse or block-sparse storage has benchmark evidence."
        )
      }
    ))
  }
  check_row(
    "known_sampling_covariance",
    if (ok) "ok" else "error",
    paste0(
      "type=",
      known_type,
      "; n=",
      length(known_diag),
      "; range=[",
      format_check_number(min(known_diag, na.rm = TRUE)),
      ",",
      format_check_number(max(known_diag, na.rm = TRUE)),
      "]"
    ),
    if (ok) {
      "Known sampling covariance is recorded through meta_known_V(V = V)."
    } else {
      "Known sampling variances contain non-finite or negative values."
    }
  )
}

known_v_dense_storage_summary <- function(V) {
  entries <- length(V)
  nonzero <- sum(!is.na(V) & V != 0)
  list(
    nonzero = nonzero,
    density = if (entries == 0L) NA_real_ else nonzero / entries,
    size_mb = as.numeric(utils::object.size(V)) / 1024^2
  )
}

check_fixed_effect_design_size <- function(object) {
  X <- object$model$X
  if (is.null(X) || length(X) == 0L) {
    return(NULL)
  }
  design <- fixed_effect_design_summary(X)
  if (nrow(design) == 0L) {
    return(NULL)
  }
  total_mb <- sum(design$size_mb)
  max_cols <- max(design$n_cols, 0L)
  largest_row <- design[which.max(design$size_mb), , drop = FALSE]
  largest <- largest_row$dpar[[1L]]
  if (is.na(largest) || !nzchar(largest)) {
    largest <- "unnamed"
  }
  largest_density <- largest_row$density[[1L]]
  largest_class <- largest_row$matrix_class[[1L]]
  has_sparse <- any(vapply(X, inherits, logical(1), "sparseMatrix"))
  sparse_candidate <- is.finite(largest_density) &&
    max_cols >= 30L &&
    largest_density <= 0.25
  note <- total_mb >= 25 || max_cols >= 30L
  value <- paste0(
    "total_mb=",
    format_check_number(total_mb),
    "; max_cols=",
    max_cols,
    "; largest=",
    largest,
    "; largest_class=",
    largest_class,
    "; largest_density=",
    format_check_number(largest_density)
  )
  check_row(
    "fixed_effect_design_size",
    if (note) "note" else "ok",
    value,
    if (has_sparse) {
      "Sparse fixed-effect design matrices are enabled for at least one fixed-effect block."
    } else if (sparse_candidate) {
      paste(
        "Dense fixed-effect design matrices are wide and mostly zero;",
        "high-cardinality factors or sparse interactions may dominate memory before TMB optimization and are candidates for future sparse fixed-effect matrices."
      )
    } else if (note) {
      paste(
        "Dense fixed-effect design matrices are large enough to inspect;",
        "high-cardinality factors or interactions may dominate memory before TMB optimization."
      )
    } else {
      "Dense fixed-effect design matrices are modest for this fit."
    }
  )
}

fixed_effect_design_summary <- function(X) {
  x_names <- names(X)
  if (is.null(x_names)) {
    x_names <- rep(NA_character_, length(X))
  }
  rows <- lapply(seq_along(X), function(i) {
    name <- x_names[[i]]
    if (is.na(name) || !nzchar(name)) {
      name <- paste0("X", i)
    }
    x <- X[[i]]
    dims <- dim(x)
    if (is.null(dims) || length(dims) != 2L) {
      return(NULL)
    }
    n_values <- prod(dims)
    n_nonzero <- fixed_effect_design_nonzero(x)
    density <- if (n_values == 0L) {
      NA_real_
    } else {
      n_nonzero / n_values
    }
    data.frame(
      dpar = name,
      matrix_class = class(x)[[1L]],
      n_rows = dims[[1L]],
      n_cols = dims[[2L]],
      n_nonzero = n_nonzero,
      density = density,
      size_mb = as.numeric(utils::object.size(x)) / 1024^2,
      stringsAsFactors = FALSE
    )
  })
  rows <- Filter(Negate(is.null), rows)
  if (length(rows) == 0L) {
    return(data.frame(
      dpar = character(),
      matrix_class = character(),
      n_rows = integer(),
      n_cols = integer(),
      n_nonzero = numeric(),
      density = numeric(),
      size_mb = numeric()
    ))
  }
  do.call(rbind, rows)
}

fixed_effect_design_nonzero <- function(x) {
  if (inherits(x, "sparseMatrix")) {
    return(Matrix::nnzero(x))
  }
  sum(x != 0, na.rm = TRUE)
}

check_random_effect_replication <- function(object, block) {
  if (!identical(object$model$model_type, "gaussian")) {
    return(NULL)
  }
  re <- object$model$random[[block]]
  if (is.null(re) || re$n_re == 0L) {
    return(NULL)
  }
  min_counts <- vapply(
    seq_len(re$n_terms),
    function(k) {
      min(tabulate(re$index[, k], nbins = re$n_re)[re$index[, k]])
    },
    integer(1)
  )
  names(min_counts) <- re$labels
  min_count <- min(min_counts)
  check_row(
    paste0(block, "_random_effect_replication"),
    if (min_count < 2L) "note" else "ok",
    paste(names(min_counts), min_counts, sep = "=", collapse = "; "),
    if (min_count < 2L) {
      "At least one random-effect level has one fitted observation; interpret its conditional effect cautiously."
    } else {
      "Every random-effect level has at least two fitted observations."
    }
  )
}

check_random_effect_design <- function(object, block) {
  if (!identical(object$model$model_type, "gaussian")) {
    return(NULL)
  }
  re <- object$model$random[[block]]
  if (is.null(re) || re$n_re == 0L) {
    return(NULL)
  }
  slope_terms <- which(
    !vapply(re$labels, random_effect_label_is_intercept, logical(1))
  )
  correlated_ranks <- random_effect_correlated_block_ranks(re)
  if (length(slope_terms) == 0L && length(correlated_ranks) == 0L) {
    return(NULL)
  }

  unique_counts <- vapply(
    slope_terms,
    function(k) {
      min(vapply(
        split(re$value[, k], re$index[, k]),
        random_effect_unique_n,
        integer(1)
      ))
    },
    integer(1)
  )
  names(unique_counts) <- re$labels[slope_terms]

  values <- character()
  if (length(unique_counts) > 0L) {
    values <- c(
      values,
      paste0(
        "min_unique=",
        paste(names(unique_counts), unique_counts, sep = "=", collapse = "; ")
      )
    )
  }
  if (length(correlated_ranks) > 0L) {
    values <- c(
      values,
      paste0(
        "min_rank=",
        paste(
          names(correlated_ranks),
          correlated_ranks,
          sep = "=",
          collapse = "; "
        )
      )
    )
  }

  weak_unique <- length(unique_counts) > 0L && any(unique_counts < 2L)
  weak_rank <- length(correlated_ranks) > 0L &&
    any(
      as.integer(sub("/.*", "", correlated_ranks)) <
        as.integer(sub(".*/", "", correlated_ranks))
    )
  ok <- !weak_unique && !weak_rank

  check_row(
    paste0(block, "_random_effect_design"),
    if (ok) "ok" else "note",
    paste(values, collapse = " | "),
    if (ok) {
      "Random-slope design values show within-group variation for implemented random-effect checks."
    } else {
      "At least one random-slope or correlated random-effect block has weak within-group design variation; interpret slope SDs or correlations cautiously."
    }
  )
}

registry_covariance_pair <- function(
  object,
  class,
  from_dpar = NULL,
  to_dpar = NULL
) {
  registry <- object$model$random$covariance_blocks
  if (
    !is.list(registry) ||
      is.null(registry$pairs) ||
      nrow(registry$pairs) == 0L
  ) {
    return(NULL)
  }

  pairs <- registry$pairs
  keep <- pairs$class == class
  if (!is.null(from_dpar)) {
    keep <- keep & pairs$from_dpar %in% from_dpar
  }
  if (!is.null(to_dpar)) {
    keep <- keep & pairs$to_dpar %in% to_dpar
  }
  pairs <- pairs[keep, , drop = FALSE]
  if (nrow(pairs) == 0L) {
    return(NULL)
  }
  if (nrow(pairs) != 1L) {
    return(list(complex = TRUE, n_pairs = nrow(pairs)))
  }

  pair <- pairs[1L, , drop = FALSE]
  registry <- object$model$random$covariance_blocks
  block <- registry$blocks[
    registry$blocks$block_id0 == pair$block_id0[[1L]],
    ,
    drop = FALSE
  ]
  members <- registry$members[
    registry$members$block_id0 == pair$block_id0[[1L]],
    ,
    drop = FALSE
  ]
  if (nrow(block) != 1L || nrow(members) == 0L) {
    return(list(complex = TRUE, n_pairs = nrow(pairs)))
  }

  list(
    complex = FALSE,
    pair = pair,
    block = block,
    members = members
  )
}

registry_covariance_member <- function(info, dpar) {
  member <- info$members[info$members$dpar == dpar, , drop = FALSE]
  if (nrow(member) != 1L) {
    return(NULL)
  }
  member
}

registry_member_group_counts <- function(member, n_groups) {
  if (!is.finite(n_groups) || n_groups < 1L) {
    return(integer())
  }
  index <- member$latent_index0[[1L]]
  index <- index[!is.na(index) & index >= 0L]
  tabulate((index %% n_groups) + 1L, nbins = n_groups)
}

check_mu_sigma_random_effect_covariance <- function(object) {
  if (!identical(object$model$model_type, "gaussian")) {
    return(NULL)
  }
  re_mu_sigma <- object$model$random$mu_sigma
  if (
    is.list(re_mu_sigma) &&
      !is.null(re_mu_sigma$n_cors) &&
      re_mu_sigma$n_cors > 1L
  ) {
    return(check_mu_sigma_random_effect_covariance_rows(object, re_mu_sigma))
  }

  registry_pair <- registry_covariance_pair(
    object,
    class = "mean-scale",
    from_dpar = "mu",
    to_dpar = "sigma"
  )
  if (!is.null(registry_pair)) {
    if (isTRUE(registry_pair$complex)) {
      return(check_row(
        "mu_sigma_random_effect_covariance",
        "note",
        paste0("n_pairs=", registry_pair$n_pairs),
        "The fitted mu/sigma covariance block is more complex than the current diagnostic summary."
      ))
    }

    mu_member <- registry_covariance_member(registry_pair, "mu")
    sigma_member <- registry_covariance_member(registry_pair, "sigma")
    if (is.null(mu_member) || is.null(sigma_member)) {
      return(NULL)
    }

    group_counts <- registry_member_group_counts(
      sigma_member,
      registry_pair$block$n_groups[[1L]]
    )
    min_count <- min(group_counts)
    singleton_groups <- sum(group_counts < 2L)
    sd_mu <- unname(object$sdpars$mu[[mu_member$label[[1L]]]])
    sd_sigma <- unname(object$sdpars$sigma[[sigma_member$label[[1L]]]])
    residual_scale <- mean(stats::sigma(object), na.rm = TRUE)
    mu_sd_ratio <- sd_mu / residual_scale
    weak_replication <- min_count < 2L
    weak_sd <- !is.finite(mu_sd_ratio) ||
      !is.finite(sd_sigma) ||
      mu_sd_ratio < 0.05 ||
      sd_sigma < 0.05

    return(check_row(
      "mu_sigma_random_effect_covariance",
      if (weak_replication || weak_sd) "note" else "ok",
      paste0(
        "term=",
        sigma_member$label[[1L]],
        "; n_groups=",
        registry_pair$block$n_groups[[1L]],
        "; min_group_n=",
        min_count,
        "; singleton_groups=",
        singleton_groups,
        "; mu_sd_ratio=",
        format_check_number(mu_sd_ratio),
        "; sigma_log_sd=",
        format_check_number(sd_sigma)
      ),
      mu_sigma_re_diagnostic_message(weak_replication, weak_sd)
    ))
  }

  if (is.null(re_mu_sigma) || re_mu_sigma$n_cors == 0L) {
    return(NULL)
  }
  check_mu_sigma_random_effect_covariance_rows(object, re_mu_sigma)
}

check_mu_sigma_random_effect_covariance_rows <- function(object, re_mu_sigma) {
  re_mu <- object$model$random$mu
  re_sigma <- object$model$random$sigma
  rows <- lapply(seq_len(re_mu_sigma$n_cors), function(cor_id) {
    sigma_rows <- which(re_mu_sigma$sigma_cross_cor_id0 == cor_id - 1L)
    if (length(sigma_rows) == 0L) {
      return(NULL)
    }

    sigma_terms <- unique(re_sigma$term_id0[sigma_rows] + 1L)
    mu_rows <- re_mu_sigma$sigma_cross_mu_index0[sigma_rows] + 1L
    mu_terms <- unique(re_mu$term_id0[mu_rows] + 1L)
    if (length(sigma_terms) != 1L || length(mu_terms) != 1L) {
      return(check_row(
        "mu_sigma_random_effect_covariance",
        "note",
        paste0("n_cors=", re_mu_sigma$n_cors, "; cor_id=", cor_id),
        "The fitted mu/sigma covariance block is more complex than the current diagnostic summary."
      ))
    }

    sigma_term <- sigma_terms[[1L]]
    mu_term <- mu_terms[[1L]]
    group_counts <- tabulate(
      re_sigma$index[, sigma_term],
      nbins = re_sigma$n_re
    )[sigma_rows]
    min_count <- min(group_counts)
    singleton_groups <- sum(group_counts < 2L)

    sd_mu <- unname(object$sdpars$mu[[re_mu$labels[[mu_term]]]])
    sd_sigma <- unname(object$sdpars$sigma[[re_sigma$labels[[sigma_term]]]])
    residual_scale <- mean(stats::sigma(object), na.rm = TRUE)
    mu_sd_ratio <- sd_mu / residual_scale
    weak_replication <- min_count < 2L
    weak_sd <- !is.finite(mu_sd_ratio) ||
      !is.finite(sd_sigma) ||
      mu_sd_ratio < 0.05 ||
      sd_sigma < 0.05

    check_row(
      "mu_sigma_random_effect_covariance",
      if (weak_replication || weak_sd) "note" else "ok",
      paste0(
        "term=",
        re_sigma$labels[[sigma_term]],
        "; n_groups=",
        length(sigma_rows),
        "; min_group_n=",
        min_count,
        "; singleton_groups=",
        singleton_groups,
        "; mu_sd_ratio=",
        format_check_number(mu_sd_ratio),
        "; sigma_log_sd=",
        format_check_number(sd_sigma)
      ),
      mu_sigma_re_diagnostic_message(weak_replication, weak_sd)
    )
  })
  rows <- Filter(Negate(is.null), rows)
  if (length(rows) == 0L) {
    return(NULL)
  }
  do.call(rbind, rows)
}

mu_sigma_re_diagnostic_message <- function(weak_replication, weak_sd) {
  if (weak_replication && weak_sd) {
    return(paste(
      "At least one group has fewer than two fitted observations and one",
      "component SD is tiny; interpret the mu/sigma group-level correlation cautiously."
    ))
  }
  if (weak_replication) {
    return(paste(
      "At least one group has fewer than two fitted observations;",
      "interpret the mu/sigma group-level correlation cautiously."
    ))
  }
  if (weak_sd) {
    return(paste(
      "At least one component SD is tiny on its interpretation scale;",
      "the mu/sigma group-level correlation may be weakly identified."
    ))
  }
  "Mu/sigma group-level covariance has replicated groups and non-negligible fitted component SDs."
}

check_biv_mu_random_effect_covariance <- function(object) {
  if (!identical(object$model$model_type, "biv_gaussian")) {
    return(NULL)
  }
  registry_pair <- registry_covariance_pair(
    object,
    class = "mean-mean",
    from_dpar = "mu1",
    to_dpar = "mu2"
  )
  if (is.null(registry_pair)) {
    registry_pair <- registry_covariance_pair(
      object,
      class = "slope-slope",
      from_dpar = "mu1",
      to_dpar = "mu2"
    )
  }
  if (!is.null(registry_pair)) {
    if (isTRUE(registry_pair$complex)) {
      return(check_row(
        "biv_mu_random_effect_covariance",
        "note",
        paste0("n_pairs=", registry_pair$n_pairs),
        "The fitted bivariate mu covariance block is more complex than the current diagnostic summary."
      ))
    }

    first_member <- registry_covariance_member(registry_pair, "mu1")
    if (is.null(first_member)) {
      return(NULL)
    }
    n_group <- registry_pair$block$n_groups[[1L]]
    group_counts <- registry_member_group_counts(first_member, n_group)
    min_count <- min(group_counts)
    singleton_groups <- sum(group_counts < 2L)
    sd_ratios <- bivariate_mu_registry_sd_ratios(
      object,
      registry_pair$members
    )
    finite_sd_ratios <- sd_ratios[is.finite(sd_ratios)]
    min_sd_ratio <- if (length(finite_sd_ratios) > 0L) {
      min(finite_sd_ratios)
    } else {
      NA_real_
    }
    weak_sd <- any(finite_sd_ratios < 0.05)
    weak_replication <- min_count < 2L
    pair_class <- registry_pair$pair$class[[1L]]

    return(check_row(
      "biv_mu_random_effect_covariance",
      if (weak_replication || weak_sd) "note" else "ok",
      paste0(
        "class=",
        pair_class,
        "; n_groups=",
        n_group,
        "; min_group_n=",
        min_count,
        "; singleton_groups=",
        singleton_groups,
        "; min_sd_ratio=",
        format_check_number(min_sd_ratio)
      ),
      bivariate_mu_re_diagnostic_message(weak_replication, weak_sd)
    ))
  }

  re <- object$model$random$mu
  if (is.null(re) || re$n_re == 0L || re$n_terms == 0L) {
    return(NULL)
  }
  if (!setequal(re$dpars, c("mu1", "mu2"))) {
    return(NULL)
  }

  n_group <- as.integer(re$n_re / re$n_terms)
  group_counts <- tabulate(re$index[, 1L], nbins = n_group)
  min_count <- min(group_counts)
  singleton_groups <- sum(group_counts < 2L)
  sd_ratios <- bivariate_mu_re_sd_ratios(object, re)
  finite_sd_ratios <- sd_ratios[is.finite(sd_ratios)]
  min_sd_ratio <- if (length(finite_sd_ratios) > 0L) {
    min(finite_sd_ratios)
  } else {
    NA_real_
  }
  weak_sd <- any(finite_sd_ratios < 0.05)
  weak_replication <- min_count < 2L

  check_row(
    "biv_mu_random_effect_covariance",
    if (weak_replication || weak_sd) "note" else "ok",
    paste0(
      "n_groups=",
      n_group,
      "; min_group_n=",
      min_count,
      "; singleton_groups=",
      singleton_groups,
      "; min_sd_ratio=",
      format_check_number(min_sd_ratio)
    ),
    bivariate_mu_re_diagnostic_message(weak_replication, weak_sd)
  )
}

bivariate_mu_registry_sd_ratios <- function(object, members) {
  sdpars <- object$sdpars$mu
  if (is.null(sdpars) || length(sdpars) == 0L) {
    return(numeric())
  }
  sigma_values <- tryCatch(stats::sigma(object), error = function(e) e)
  if (inherits(sigma_values, "error") || !is.list(sigma_values)) {
    return(numeric())
  }
  residual_scale <- c(
    mu1 = mean(sigma_values$sigma1, na.rm = TRUE),
    mu2 = mean(sigma_values$sigma2, na.rm = TRUE)
  )
  sd_values <- unname(sdpars[match(members$label, names(sdpars))])
  sd_values / residual_scale[members$dpar]
}

bivariate_mu_re_sd_ratios <- function(object, re) {
  sdpars <- object$sdpars$mu
  if (is.null(sdpars) || length(sdpars) == 0L) {
    return(numeric())
  }
  sigma_values <- tryCatch(stats::sigma(object), error = function(e) e)
  if (inherits(sigma_values, "error") || !is.list(sigma_values)) {
    return(numeric())
  }
  residual_scale <- c(
    mu1 = mean(sigma_values$sigma1, na.rm = TRUE),
    mu2 = mean(sigma_values$sigma2, na.rm = TRUE)
  )
  sd_values <- unname(sdpars[match(re$labels, names(sdpars))])
  sd_values / residual_scale[re$dpars]
}

bivariate_mu_re_diagnostic_message <- function(weak_replication, weak_sd) {
  if (weak_replication && weak_sd) {
    return(paste(
      "At least one group has fewer than two fitted observations and at least",
      "one group-level SD is tiny relative to the matching residual scale;",
      "interpret bivariate group-level SDs and correlations cautiously."
    ))
  }
  if (weak_replication) {
    return(paste(
      "At least one group has fewer than two fitted observations;",
      "interpret bivariate group-level SDs and correlations cautiously."
    ))
  }
  if (weak_sd) {
    return(paste(
      "At least one group-level SD is tiny relative to the matching residual",
      "scale; the bivariate group-level correlation may be weakly identified."
    ))
  }
  "Bivariate group-level covariance has replicated groups and non-negligible fitted SDs relative to residual scales."
}

check_biv_mu_sigma_random_effect_covariance <- function(object) {
  if (!identical(object$model$model_type, "biv_gaussian")) {
    return(NULL)
  }
  registry_pair <- registry_covariance_pair(
    object,
    class = "mean-scale",
    from_dpar = c("mu1", "mu2"),
    to_dpar = c("sigma1", "sigma2")
  )
  if (!is.null(registry_pair) && !isTRUE(registry_pair$complex)) {
    mu_member <- registry_covariance_member(
      registry_pair,
      registry_pair$pair$from_dpar[[1L]]
    )
    sigma_member <- registry_covariance_member(
      registry_pair,
      registry_pair$pair$to_dpar[[1L]]
    )
    if (is.null(mu_member) || is.null(sigma_member)) {
      return(NULL)
    }

    group_counts <- registry_member_group_counts(
      sigma_member,
      registry_pair$block$n_groups[[1L]]
    )
    min_count <- min(group_counts)
    singleton_groups <- sum(group_counts < 2L)
    sd_mu <- unname(object$sdpars$mu[[mu_member$label[[1L]]]])
    sd_sigma <- unname(object$sdpars$sigma[[sigma_member$label[[1L]]]])
    sigma_values <- tryCatch(stats::sigma(object), error = function(e) e)
    sigma_dpar <- sigma_member$dpar[[1L]]
    residual_scale <- if (
      inherits(sigma_values, "error") || !is.list(sigma_values)
    ) {
      NA_real_
    } else {
      mean(sigma_values[[sigma_dpar]], na.rm = TRUE)
    }
    mu_sd_ratio <- sd_mu / residual_scale
    weak_replication <- min_count < 2L
    weak_sd <- !is.finite(mu_sd_ratio) ||
      !is.finite(sd_sigma) ||
      mu_sd_ratio < 0.05 ||
      sd_sigma < 0.05

    return(check_row(
      "biv_mu_sigma_random_effect_covariance",
      if (weak_replication || weak_sd) "note" else "ok",
      paste0(
        "term=",
        sigma_member$label[[1L]],
        "; n_groups=",
        registry_pair$block$n_groups[[1L]],
        "; min_group_n=",
        min_count,
        "; singleton_groups=",
        singleton_groups,
        "; mu_sd_ratio=",
        format_check_number(mu_sd_ratio),
        "; sigma_log_sd=",
        format_check_number(sd_sigma)
      ),
      bivariate_mu_sigma_re_diagnostic_message(weak_replication, weak_sd)
    ))
  }

  re_mu_sigma <- object$model$random$mu_sigma
  if (is.null(re_mu_sigma) || re_mu_sigma$n_cors == 0L) {
    return(NULL)
  }

  re_mu <- object$model$random$mu
  re_sigma <- object$model$random$sigma
  sigma_rows <- which(re_mu_sigma$sigma_cross_cor_id0 >= 0L)
  if (length(sigma_rows) == 0L) {
    return(NULL)
  }

  rows <- lapply(seq_len(re_mu_sigma$n_cors), function(cor_id) {
    sigma_rows <- which(re_mu_sigma$sigma_cross_cor_id0 == cor_id - 1L)
    if (length(sigma_rows) == 0L) {
      return(NULL)
    }

    sigma_terms <- unique(re_sigma$term_id0[sigma_rows] + 1L)
    mu_rows <- re_mu_sigma$sigma_cross_mu_index0[sigma_rows] + 1L
    mu_terms <- unique(re_mu$term_id0[mu_rows] + 1L)
    if (length(sigma_terms) != 1L || length(mu_terms) != 1L) {
      return(check_row(
        "biv_mu_sigma_random_effect_covariance",
        "note",
        paste0("n_cors=", re_mu_sigma$n_cors, "; cor_id=", cor_id),
        "The fitted bivariate mu/sigma covariance block is more complex than the current diagnostic summary."
      ))
    }

    sigma_term <- sigma_terms[[1L]]
    mu_term <- mu_terms[[1L]]
    group_counts <- tabulate(
      re_sigma$index[, sigma_term],
      nbins = re_sigma$n_re
    )[sigma_rows]
    min_count <- min(group_counts)
    singleton_groups <- sum(group_counts < 2L)

    sd_mu <- unname(object$sdpars$mu[[re_mu$labels[[mu_term]]]])
    sd_sigma <- unname(object$sdpars$sigma[[re_sigma$labels[[sigma_term]]]])
    sigma_values <- tryCatch(stats::sigma(object), error = function(e) e)
    response_id <- sub("^mu", "", re_mu$dpars[[mu_term]])
    sigma_dpar <- paste0("sigma", response_id)
    residual_scale <- if (
      inherits(sigma_values, "error") || !is.list(sigma_values)
    ) {
      NA_real_
    } else {
      mean(sigma_values[[sigma_dpar]], na.rm = TRUE)
    }
    mu_sd_ratio <- sd_mu / residual_scale
    weak_replication <- min_count < 2L
    weak_sd <- !is.finite(mu_sd_ratio) ||
      !is.finite(sd_sigma) ||
      mu_sd_ratio < 0.05 ||
      sd_sigma < 0.05

    check_row(
      "biv_mu_sigma_random_effect_covariance",
      if (weak_replication || weak_sd) "note" else "ok",
      paste0(
        "term=",
        re_sigma$labels[[sigma_term]],
        "; n_groups=",
        length(sigma_rows),
        "; min_group_n=",
        min_count,
        "; singleton_groups=",
        singleton_groups,
        "; mu_sd_ratio=",
        format_check_number(mu_sd_ratio),
        "; sigma_log_sd=",
        format_check_number(sd_sigma)
      ),
      bivariate_mu_sigma_re_diagnostic_message(weak_replication, weak_sd)
    )
  })
  rows <- Filter(Negate(is.null), rows)
  if (length(rows) == 0L) {
    return(NULL)
  }
  do.call(rbind, rows)
}

bivariate_mu_sigma_re_diagnostic_message <- function(
  weak_replication,
  weak_sd
) {
  if (weak_replication && weak_sd) {
    return(paste(
      "At least one group has fewer than two fitted observations and one",
      "component SD is tiny; interpret the bivariate mu/sigma group-level",
      "correlation cautiously."
    ))
  }
  if (weak_replication) {
    return(paste(
      "At least one group has fewer than two fitted observations;",
      "interpret the bivariate mu/sigma group-level correlation cautiously."
    ))
  }
  if (weak_sd) {
    return(paste(
      "At least one component SD is tiny; the bivariate mu/sigma group-level",
      "correlation may be weakly identified."
    ))
  }
  "Bivariate mu/sigma group-level covariance has replicated groups and non-negligible fitted SDs."
}

check_biv_sigma_random_effect_covariance <- function(object) {
  if (!identical(object$model$model_type, "biv_gaussian")) {
    return(NULL)
  }
  registry_pair <- registry_covariance_pair(
    object,
    class = "scale-scale",
    from_dpar = "sigma1",
    to_dpar = "sigma2"
  )
  if (!is.null(registry_pair)) {
    if (isTRUE(registry_pair$complex)) {
      return(check_row(
        "biv_sigma_random_effect_covariance",
        "note",
        paste0("n_pairs=", registry_pair$n_pairs),
        "The fitted bivariate sigma covariance block is more complex than the current diagnostic summary."
      ))
    }

    first_member <- registry_covariance_member(registry_pair, "sigma1")
    if (is.null(first_member)) {
      return(NULL)
    }
    n_group <- registry_pair$block$n_groups[[1L]]
    group_counts <- registry_member_group_counts(first_member, n_group)
    min_count <- min(group_counts)
    singleton_groups <- sum(group_counts < 2L)
    sdpars <- object$sdpars$sigma
    sd_values <- unname(sdpars[match(
      registry_pair$members$label,
      names(sdpars)
    )])
    finite_sd_values <- sd_values[is.finite(sd_values)]
    min_sd <- if (length(finite_sd_values) > 0L) {
      min(finite_sd_values)
    } else {
      NA_real_
    }
    weak_sd <- any(finite_sd_values < 0.05)
    weak_replication <- min_count < 2L

    return(check_row(
      "biv_sigma_random_effect_covariance",
      if (weak_replication || weak_sd) "note" else "ok",
      paste0(
        "n_groups=",
        n_group,
        "; min_group_n=",
        min_count,
        "; singleton_groups=",
        singleton_groups,
        "; min_log_sigma_sd=",
        format_check_number(min_sd)
      ),
      bivariate_sigma_re_diagnostic_message(weak_replication, weak_sd)
    ))
  }

  re <- object$model$random$sigma
  if (is.null(re) || re$n_re == 0L || re$n_terms == 0L) {
    return(NULL)
  }
  if (!setequal(re$dpars, c("sigma1", "sigma2"))) {
    return(NULL)
  }

  n_group <- as.integer(re$n_re / re$n_terms)
  group_counts <- tabulate(re$index[, 1L], nbins = n_group)
  min_count <- min(group_counts)
  singleton_groups <- sum(group_counts < 2L)
  sdpars <- object$sdpars$sigma
  sd_values <- unname(sdpars[match(re$labels, names(sdpars))])
  finite_sd_values <- sd_values[is.finite(sd_values)]
  min_sd <- if (length(finite_sd_values) > 0L) {
    min(finite_sd_values)
  } else {
    NA_real_
  }
  weak_sd <- any(finite_sd_values < 0.05)
  weak_replication <- min_count < 2L

  check_row(
    "biv_sigma_random_effect_covariance",
    if (weak_replication || weak_sd) "note" else "ok",
    paste0(
      "n_groups=",
      n_group,
      "; min_group_n=",
      min_count,
      "; singleton_groups=",
      singleton_groups,
      "; min_log_sigma_sd=",
      format_check_number(min_sd)
    ),
    bivariate_sigma_re_diagnostic_message(weak_replication, weak_sd)
  )
}

bivariate_sigma_re_diagnostic_message <- function(weak_replication, weak_sd) {
  if (weak_replication && weak_sd) {
    return(paste(
      "At least one group has fewer than two fitted observations and at least",
      "one residual-scale random-effect SD is tiny; interpret the bivariate",
      "scale-scale group-level correlation cautiously."
    ))
  }
  if (weak_replication) {
    return(paste(
      "At least one group has fewer than two fitted observations;",
      "interpret the bivariate scale-scale group-level correlation cautiously."
    ))
  }
  if (weak_sd) {
    return(paste(
      "At least one residual-scale random-effect SD is tiny;",
      "the bivariate scale-scale group-level correlation may be weakly identified."
    ))
  }
  "Bivariate scale-scale covariance has replicated groups and non-negligible log-scale SDs."
}

check_biv_q4_random_effect_covariance <- function(object, rho_boundary) {
  if (!identical(object$model$model_type, "biv_gaussian")) {
    return(NULL)
  }
  registry <- object$model$random$covariance_blocks
  if (
    !is.list(registry) ||
      is.null(registry$blocks) ||
      nrow(registry$blocks) == 0L
  ) {
    return(NULL)
  }

  blocks <- registry$blocks[
    registry$blocks$implemented &
      registry$blocks$n_members == 4L &
      registry$blocks$level == "group",
    ,
    drop = FALSE
  ]
  if (nrow(blocks) == 0L) {
    return(NULL)
  }

  block_summaries <- lapply(seq_len(nrow(blocks)), function(i) {
    block <- blocks[i, , drop = FALSE]
    members <- registry$members[
      registry$members$block_id0 == block$block_id0[[1L]],
      ,
      drop = FALSE
    ]
    pairs <- registry$pairs[
      registry$pairs$block_id0 == block$block_id0[[1L]],
      ,
      drop = FALSE
    ]
    first_member <- members[order(members$member_id0), , drop = FALSE][1L, ]
    group_counts <- registry_member_group_counts(
      first_member,
      block$n_groups[[1L]]
    )
    location_sd_ratios <- bivariate_q4_location_sd_ratios(object, members)
    scale_sd_values <- bivariate_q4_scale_sd_values(object, members)
    correlations <- bivariate_q4_correlations(object, pairs)

    list(
      n_groups = block$n_groups[[1L]],
      min_group_n = min(group_counts),
      singleton_groups = sum(group_counts < 2L),
      min_location_sd_ratio = min_finite_or_na(location_sd_ratios),
      min_log_sigma_sd = min_finite_or_na(scale_sd_values),
      max_abs_cor = max_abs_finite_or_na(correlations)
    )
  })

  min_groups <- min(vapply(block_summaries, `[[`, numeric(1L), "n_groups"))
  min_group_n <- min(vapply(block_summaries, `[[`, numeric(1L), "min_group_n"))
  singleton_groups <- sum(vapply(
    block_summaries,
    `[[`,
    numeric(1L),
    "singleton_groups"
  ))
  min_location_sd_ratio <- min(vapply(
    block_summaries,
    `[[`,
    numeric(1L),
    "min_location_sd_ratio"
  ))
  min_log_sigma_sd <- min(vapply(
    block_summaries,
    `[[`,
    numeric(1L),
    "min_log_sigma_sd"
  ))
  max_abs_cor <- max(vapply(block_summaries, `[[`, numeric(1L), "max_abs_cor"))

  weak_group_count <- min_groups < 8L
  weak_replication <- min_group_n < 2L
  weak_location_sd <- is.finite(min_location_sd_ratio) &&
    min_location_sd_ratio < 0.05
  weak_scale_sd <- is.finite(min_log_sigma_sd) && min_log_sigma_sd < 0.05
  near_rho_boundary <- !is.finite(max_abs_cor) || max_abs_cor > rho_boundary

  check_row(
    "biv_q4_random_effect_covariance",
    if (near_rho_boundary) {
      "warning"
    } else if (
      weak_group_count ||
        weak_replication ||
        weak_location_sd ||
        weak_scale_sd
    ) {
      "note"
    } else {
      "ok"
    },
    paste0(
      "n_blocks=",
      nrow(blocks),
      "; min_groups=",
      min_groups,
      "; min_group_n=",
      min_group_n,
      "; singleton_groups=",
      singleton_groups,
      "; min_location_sd_ratio=",
      format_check_number(min_location_sd_ratio),
      "; min_log_sigma_sd=",
      format_check_number(min_log_sigma_sd),
      "; max_abs_cor=",
      format_check_number(max_abs_cor),
      "; boundary=",
      format_check_number(rho_boundary)
    ),
    bivariate_q4_re_diagnostic_message(
      near_rho_boundary,
      weak_group_count,
      weak_replication,
      weak_location_sd,
      weak_scale_sd
    )
  )
}

bivariate_q4_location_sd_ratios <- function(object, members) {
  location_members <- members[members$dpar %in% c("mu1", "mu2"), , drop = FALSE]
  if (nrow(location_members) == 0L) {
    return(NA_real_)
  }
  sdpars <- object$sdpars$mu
  sigma_values <- tryCatch(stats::sigma(object), error = function(e) e)
  if (
    is.null(sdpars) ||
      length(sdpars) == 0L ||
      inherits(sigma_values, "error") ||
      !is.list(sigma_values)
  ) {
    return(NA_real_)
  }
  residual_scale <- c(
    mu1 = mean(sigma_values$sigma1, na.rm = TRUE),
    mu2 = mean(sigma_values$sigma2, na.rm = TRUE)
  )
  sd_values <- unname(sdpars[match(location_members$label, names(sdpars))])
  sd_values / residual_scale[location_members$dpar]
}

bivariate_q4_scale_sd_values <- function(object, members) {
  scale_members <- members[
    members$dpar %in% c("sigma1", "sigma2"),
    ,
    drop = FALSE
  ]
  if (nrow(scale_members) == 0L) {
    return(NA_real_)
  }
  sdpars <- object$sdpars$sigma
  if (is.null(sdpars) || length(sdpars) == 0L) {
    return(NA_real_)
  }
  unname(sdpars[match(scale_members$label, names(sdpars))])
}

bivariate_q4_correlations <- function(object, pairs) {
  corpars <- object$corpars$re_cov
  if (is.null(corpars) || length(corpars) == 0L || nrow(pairs) == 0L) {
    return(NA_real_)
  }
  unname(corpars[match(pairs$parameter, names(corpars))])
}

min_finite_or_na <- function(x) {
  x <- x[is.finite(x)]
  if (length(x) == 0L) {
    return(NA_real_)
  }
  min(x)
}

max_finite_or_na <- function(x) {
  x <- x[is.finite(x)]
  if (length(x) == 0L) {
    return(NA_real_)
  }
  max(x)
}

max_abs_finite_or_na <- function(x) {
  x <- x[is.finite(x)]
  if (length(x) == 0L) {
    return(NA_real_)
  }
  max(abs(x))
}

bivariate_q4_re_diagnostic_message <- function(
  near_rho_boundary,
  weak_group_count,
  weak_replication,
  weak_location_sd,
  weak_scale_sd
) {
  if (near_rho_boundary) {
    return(paste(
      "At least one latent q4 group-level correlation is close to +/-1;",
      "profile, simulate, or simplify before interpreting all six correlations."
    ))
  }
  weak <- c(
    if (weak_group_count) "few groups for a four-member covariance block",
    if (weak_replication) {
      "at least one group has fewer than two fitted observations"
    },
    if (weak_location_sd) {
      "at least one location SD is tiny relative to residual scale"
    },
    if (weak_scale_sd) "at least one log-sigma random-effect SD is tiny"
  )
  if (length(weak) > 0L) {
    return(paste(
      "Ordinary q4 location-scale covariance is fitted, but",
      paste(weak, collapse = "; "),
      "so interpret all six latent correlations cautiously."
    ))
  }
  "Ordinary q4 location-scale covariance has replicated groups, non-negligible fitted component SDs, and latent correlations away from the boundary."
}

random_effect_label_is_intercept <- function(label) {
  grepl("^\\(1 \\| [^)]+\\)$", label) || grepl(":(Intercept)$", label)
}

random_effect_unique_n <- function(x) {
  length(unique(x[is.finite(x)]))
}

random_effect_correlated_block_ranks <- function(re) {
  if (re$n_cors == 0L) {
    return(character())
  }
  term_cor_id <- vapply(
    seq_len(re$n_terms),
    function(k) {
      ids <- unique(re$re_cor_id0[re$term_id0 == k - 1L])
      ids <- ids[ids >= 0L]
      if (length(ids) == 0L) -1L else ids[[1L]]
    },
    integer(1)
  )
  out <- character()
  for (cor_id in unique(term_cor_id[term_cor_id >= 0L])) {
    cols <- which(term_cor_id == cor_id)
    group_id <- re$index[, cols[[1L]]]
    ranks <- vapply(
      split(seq_along(group_id), group_id),
      function(row) {
        qr(re$value[row, cols, drop = FALSE])$rank
      },
      integer(1)
    )
    out <- c(out, paste0(min(ranks), "/", length(cols)))
  }
  names(out) <- re$cor_labels[unique(term_cor_id[term_cor_id >= 0L]) + 1L]
  out
}

check_phylo_replication <- function(object) {
  if (!has_phylo_mu_effect(object)) {
    return(NULL)
  }
  index <- object$model$structured$phylo_mu$observation_node_index
  counts <- tabulate(match(index, unique(index)))
  min_count <- min(counts)
  check_row(
    "phylo_mu_replication",
    if (min_count < 2L) "note" else "ok",
    paste0("min_species_n=", min_count),
    if (min_count < 2L) {
      "At least one observed species has one fitted observation; phylogenetic SD may be weakly identified."
    } else {
      "Every observed species has at least two fitted observations."
    }
  )
}

check_phylo_mu_diagnostics <- function(object) {
  if (!has_phylo_mu_effect(object)) {
    return(NULL)
  }

  phylo_mu <- object$model$structured$phylo_mu
  index <- phylo_mu$observation_node_index
  counts <- tabulate(match(index, unique(index)))
  min_count <- if (length(counts) > 0L) min(counts) else NA_integer_
  n_species <- length(counts)
  weak_replication <- is.finite(min_count) && min_count < 2L

  sd_label <- phylo_mu_sd_labels(phylo_mu, object$model$model_type)
  sd_values <- unname(object$sdpars$mu[match(
    sd_label,
    names(object$sdpars$mu)
  )])
  finite_positive_sd <- length(sd_values) == length(sd_label) &&
    all(is.finite(sd_values)) &&
    all(sd_values > 0)

  residual_scale <- spatial_mu_residual_scale(object)
  sd_ratios <- if (finite_positive_sd && is.finite(residual_scale)) {
    sd_values / residual_scale
  } else {
    NA_real_
  }
  finite_sd_ratios <- sd_ratios[is.finite(sd_ratios)]
  min_sd <- if (finite_positive_sd) min(sd_values) else NA_real_
  min_sd_ratio <- if (length(finite_sd_ratios) > 0L) {
    min(finite_sd_ratios)
  } else {
    NA_real_
  }
  weak_sd <- !finite_positive_sd ||
    any(finite_sd_ratios < 0.05)
  sd_text <- if (length(sd_label) == 1L) {
    paste0(
      "; phylo_sd=",
      format_check_number(sd_values),
      "; sd_ratio=",
      format_check_number(sd_ratios)
    )
  } else {
    paste0(
      "; n_coef=",
      length(sd_label),
      "; min_phylo_sd=",
      format_check_number(min_sd),
      "; min_sd_ratio=",
      format_check_number(min_sd_ratio)
    )
  }

  check_row(
    "phylo_mu_diagnostics",
    if (!finite_positive_sd) {
      "error"
    } else if (weak_replication || weak_sd) {
      "note"
    } else {
      "ok"
    },
    paste0(
      "group=",
      phylo_mu$group,
      "; n_species=",
      n_species,
      "; min_species_n=",
      min_count,
      sd_text
    ),
    phylo_mu_diagnostic_message(
      finite_positive_sd,
      weak_replication,
      weak_sd
    )
  )
}

phylo_mu_diagnostic_message <- function(
  finite_positive_sd,
  weak_replication,
  weak_sd
) {
  if (!finite_positive_sd) {
    return(paste(
      "The fitted phylogenetic SD is non-positive or non-finite;",
      "inspect convergence, tree input, and the fitted structured effect."
    ))
  }
  if (weak_replication && weak_sd) {
    return(paste(
      "At least one species has fewer than two fitted observations and the",
      "phylogenetic SD is tiny relative to residual scale; interpret the",
      "phylogenetic field cautiously."
    ))
  }
  if (weak_replication) {
    return(paste(
      "At least one species has fewer than two fitted observations;",
      "interpret conditional phylogenetic effects and SDs cautiously."
    ))
  }
  if (weak_sd) {
    return(paste(
      "The phylogenetic SD is tiny relative to residual scale; the structured",
      "phylogenetic field may be weakly identified."
    ))
  }
  paste(
    "The phylogenetic random effect has replicated species and a non-negligible",
    "fitted SD relative to residual scale."
  )
}

check_spatial_mu_diagnostics <- function(object) {
  if (!has_spatial_mu_effect(object)) {
    return(NULL)
  }

  spatial_mu <- object$model$structured$phylo_mu
  index <- spatial_mu$observation_node_index
  counts <- tabulate(match(index, unique(index)))
  min_count <- if (length(counts) > 0L) min(counts) else NA_integer_
  n_sites <- length(counts)
  weak_replication <- is.finite(min_count) && min_count < 2L

  sd_label <- phylo_mu_sd_labels(spatial_mu, object$model$model_type)
  sd_values <- unname(object$sdpars$mu[match(
    sd_label,
    names(object$sdpars$mu)
  )])
  finite_positive_sd <- length(sd_values) == length(sd_label) &&
    all(is.finite(sd_values)) &&
    all(sd_values > 0)

  residual_scale <- spatial_mu_residual_scale(object)
  sd_ratios <- if (finite_positive_sd && is.finite(residual_scale)) {
    sd_values / residual_scale
  } else {
    NA_real_
  }
  finite_sd_ratios <- sd_ratios[is.finite(sd_ratios)]
  min_sd <- if (finite_positive_sd) min(sd_values) else NA_real_
  min_sd_ratio <- if (length(finite_sd_ratios) > 0L) {
    min(finite_sd_ratios)
  } else {
    NA_real_
  }
  weak_sd <- !finite_positive_sd ||
    any(finite_sd_ratios < 0.05)

  coord_range <- spatial_mu$precision$range
  sd_text <- if (length(sd_label) == 1L) {
    paste0(
      "; spatial_sd=",
      format_check_number(sd_values),
      "; sd_ratio=",
      format_check_number(sd_ratios)
    )
  } else {
    paste0(
      "; n_coef=",
      length(sd_label),
      "; min_spatial_sd=",
      format_check_number(min_sd),
      "; min_sd_ratio=",
      format_check_number(min_sd_ratio)
    )
  }
  check_row(
    "spatial_mu_diagnostics",
    if (!finite_positive_sd) {
      "error"
    } else if (weak_replication || weak_sd) {
      "note"
    } else {
      "ok"
    },
    paste0(
      "group=",
      spatial_mu$group,
      "; n_sites=",
      n_sites,
      "; min_site_n=",
      min_count,
      "; coord_range=",
      format_check_number(coord_range),
      sd_text
    ),
    spatial_mu_diagnostic_message(
      finite_positive_sd,
      weak_replication,
      weak_sd
    )
  )
}

spatial_mu_residual_scale <- function(object) {
  sigma_values <- tryCatch(stats::sigma(object), error = function(e) e)
  if (inherits(sigma_values, "error")) {
    return(NA_real_)
  }
  if (is.list(sigma_values)) {
    sigma_values <- unlist(sigma_values, use.names = FALSE)
  }
  mean(sigma_values, na.rm = TRUE)
}

spatial_mu_diagnostic_message <- function(
  finite_positive_sd,
  weak_replication,
  weak_sd
) {
  if (!finite_positive_sd) {
    return(paste(
      "The fitted spatial SD is non-positive or non-finite;",
      "inspect convergence, coordinate input, and the fitted structured effect."
    ))
  }
  if (weak_replication && weak_sd) {
    return(paste(
      "At least one spatial site has fewer than two fitted observations and",
      "the spatial SD is tiny relative to the residual scale; interpret the",
      "coordinate spatial field cautiously."
    ))
  }
  if (weak_replication) {
    return(paste(
      "At least one spatial site has fewer than two fitted observations;",
      "interpret conditional spatial effects and the spatial SD cautiously."
    ))
  }
  if (weak_sd) {
    return(paste(
      "The spatial SD is tiny relative to the residual scale; the coordinate",
      "spatial field may be weakly identified."
    ))
  }
  paste(
    "The coordinate spatial random intercept has replicated sites and a",
    "non-negligible fitted SD relative to the residual scale."
  )
}

check_known_relatedness_mu_diagnostics <- function(object) {
  structured_mu <- object$model$structured$phylo_mu
  type <- structured_mu_type(structured_mu)
  if (!type %in% c("animal", "relmat")) {
    return(NULL)
  }

  index <- structured_mu$observation_node_index
  counts <- tabulate(match(index, unique(index)))
  min_count <- if (length(counts) > 0L) min(counts) else NA_integer_
  weak_replication <- is.finite(min_count) && min_count < 2L
  sd_label <- phylo_mu_sd_labels(structured_mu, object$model$model_type)
  sd_values <- unname(object$sdpars$mu[match(
    sd_label,
    names(object$sdpars$mu)
  )])
  finite_positive_sd <- length(sd_values) == length(sd_label) &&
    all(is.finite(sd_values)) &&
    all(sd_values > 0)
  residual_scale <- spatial_mu_residual_scale(object)
  sd_ratios <- if (finite_positive_sd && is.finite(residual_scale)) {
    sd_values / residual_scale
  } else {
    NA_real_
  }
  finite_sd_ratios <- sd_ratios[is.finite(sd_ratios)]
  min_sd <- if (finite_positive_sd) min(sd_values) else NA_real_
  min_sd_ratio <- if (length(finite_sd_ratios) > 0L) {
    min(finite_sd_ratios)
  } else {
    NA_real_
  }
  weak_sd <- !finite_positive_sd ||
    any(finite_sd_ratios < 0.05)
  sd_text <- if (length(sd_label) == 1L) {
    paste0(
      "; structured_sd=",
      format_check_number(sd_values),
      "; sd_ratio=",
      format_check_number(sd_ratios)
    )
  } else {
    paste0(
      "; n_coef=",
      length(sd_label),
      "; min_structured_sd=",
      format_check_number(min_sd),
      "; min_sd_ratio=",
      format_check_number(min_sd_ratio)
    )
  }

  check_row(
    paste0(type, "_mu_diagnostics"),
    if (!finite_positive_sd) {
      "error"
    } else if (weak_replication || weak_sd) {
      "note"
    } else {
      "ok"
    },
    paste0(
      "group=",
      structured_mu$group,
      "; n_nodes=",
      structured_mu$n_re,
      "; n_observed=",
      length(unique(index)),
      "; min_group_n=",
      min_count,
      "; matrix_type=",
      structured_mu$precision$matrix_type,
      sd_text
    ),
    known_relatedness_mu_diagnostic_message(
      type,
      finite_positive_sd,
      weak_replication,
      weak_sd
    )
  )
}

known_relatedness_mu_diagnostic_message <- function(
  type,
  finite_positive_sd,
  weak_replication,
  weak_sd
) {
  label <- if (identical(type, "animal")) "animal-model" else "relatedness"
  if (!finite_positive_sd) {
    return(paste(
      "The fitted",
      label,
      "SD is non-positive or non-finite; inspect convergence and the supplied matrix."
    ))
  }
  if (weak_replication && weak_sd) {
    return(paste(
      "At least one observed level has fewer than two fitted observations and",
      "the",
      label,
      "SD is tiny relative to residual scale; interpret the structured effect cautiously."
    ))
  }
  if (weak_replication) {
    return(paste(
      "At least one observed level has fewer than two fitted observations;",
      "interpret conditional",
      label,
      "effects and the structured SD cautiously."
    ))
  }
  if (weak_sd) {
    return(paste(
      "The",
      label,
      "SD is tiny relative to residual scale; the structured effect may be weakly identified."
    ))
  }
  paste(
    "The",
    label,
    "random intercept has replicated observed levels and a non-negligible fitted SD relative to residual scale."
  )
}

check_phylo_direct_sd_model <- function(object) {
  sd_phylo <- object$model$random_scale$phylo
  if (
    !is.list(sd_phylo) ||
      is.null(sd_phylo$n_models) ||
      sd_phylo$n_models == 0L
  ) {
    return(NULL)
  }

  rows <- lapply(sd_phylo$dpars, function(dpar) {
    group <- unname(sd_phylo$group[[dpar]])
    target <- unname(sd_phylo$target_dpar[[dpar]])
    if (is.null(target) || is.na(target)) {
      target <- "mu"
    }
    group_levels <- sd_phylo$group_levels_list[[dpar]]
    observation_sd_row0 <- sd_phylo$observation_sd_row0_list[[dpar]]
    if (is.null(observation_sd_row0)) {
      observation_sd_row0 <- sd_phylo$observation_sd_row0
    }
    counts <- tabulate(
      observation_sd_row0 + 1L,
      nbins = length(group_levels)
    )
    min_count <- if (length(counts) > 0L) min(counts) else NA_integer_
    n_species <- length(group_levels)

    sd_values <- object$sdpars[[dpar]]
    finite_sd <- sd_values[is.finite(sd_values)]
    sd_min <- min_finite_or_na(finite_sd)
    sd_max <- max_finite_or_na(finite_sd)
    positive_sd <- finite_sd[finite_sd > 0]
    max_sd_ratio <- if (length(positive_sd) > 0L) {
      max(positive_sd) / min(positive_sd)
    } else {
      NA_real_
    }

    invalid_sd <- length(sd_values) == 0L ||
      length(finite_sd) != length(sd_values) ||
      any(sd_values <= 0, na.rm = TRUE)
    weak_replication <- is.finite(min_count) && min_count < 2L

    check_row(
      "phylo_direct_sd_model",
      if (invalid_sd) {
        "error"
      } else if (weak_replication) {
        "note"
      } else {
        "ok"
      },
      paste0(
        "dpar=",
        dpar,
        "; target=",
        target,
        "; group=",
        group,
        "; n_species=",
        n_species,
        "; min_species_n=",
        min_count,
        "; sd_range=[",
        format_check_number(sd_min),
        ",",
        format_check_number(sd_max),
        "]",
        "; max_sd_ratio=",
        format_check_number(max_sd_ratio)
      ),
      phylo_direct_sd_message(dpar, invalid_sd, weak_replication)
    )
  })

  do.call(rbind, rows)
}

phylo_direct_sd_message <- function(dpar, invalid_sd, weak_replication) {
  if (invalid_sd) {
    return(paste0(
      "The fitted ",
      dpar,
      " surface contains non-finite or non-positive values."
    ))
  }
  if (weak_replication) {
    return(paste(
      "At least one observed species has fewer than two fitted observations;",
      dpar,
      "recovery can be weak even when the fitted model converges."
    ))
  }
  paste(
    "The",
    dpar,
    "direct-SD model has replicated species and a finite",
    "positive fitted species-level SD surface."
  )
}

check_biv_phylo_mu_covariance <- function(object, rho_boundary) {
  if (
    !identical(object$model$model_type, "biv_gaussian") ||
      !has_phylo_mu_effect(object)
  ) {
    return(NULL)
  }

  phylo_mu <- object$model$structured$phylo_mu
  if (!identical(as.integer(phylo_mu$q), 2L)) {
    return(NULL)
  }

  rho <- object$corpars$phylo
  rho_finite <- length(rho) > 0L && all(is.finite(rho))
  rho_abs <- if (rho_finite) {
    max(abs(rho))
  } else {
    NA_real_
  }
  near_rho_boundary <- !rho_finite || rho_abs > rho_boundary

  index <- phylo_mu$observation_node_index
  counts <- tabulate(match(index, unique(index)))
  min_count <- if (length(counts) > 0L) {
    min(counts)
  } else {
    NA_integer_
  }
  n_species <- length(counts)
  weak_replication <- is.finite(min_count) && min_count < 2L

  sd_ratios <- bivariate_phylo_mu_sd_ratios(object)
  finite_sd_ratios <- sd_ratios[is.finite(sd_ratios)]
  min_sd_ratio <- if (length(finite_sd_ratios) > 0L) {
    min(finite_sd_ratios)
  } else {
    NA_real_
  }
  weak_sd <- length(sd_ratios) == 0L ||
    length(finite_sd_ratios) != length(sd_ratios) ||
    any(finite_sd_ratios < 0.05)
  same_group_covariance <- bivariate_phylo_mu_has_same_group_covariance(object)

  check_row(
    "biv_phylo_mu_covariance",
    if (near_rho_boundary) {
      "warning"
    } else if (weak_replication || weak_sd || same_group_covariance) {
      "note"
    } else {
      "ok"
    },
    paste0(
      "group=",
      phylo_mu$group,
      "; rho_abs=",
      format_check_number(rho_abs),
      "; boundary=",
      format_check_number(rho_boundary),
      "; n_species=",
      n_species,
      "; min_species_n=",
      min_count,
      "; min_sd_ratio=",
      format_check_number(min_sd_ratio),
      "; same_group_covariance=",
      tolower(as.character(same_group_covariance))
    ),
    bivariate_phylo_mu_diagnostic_message(
      near_rho_boundary,
      weak_replication,
      weak_sd,
      same_group_covariance
    )
  )
}

check_biv_structured_q4_covariance <- function(object, rho_boundary) {
  if (
    !identical(object$model$model_type, "biv_gaussian") ||
      !has_structured_mu_effect(object)
  ) {
    return(NULL)
  }

  phylo_mu <- object$model$structured$phylo_mu
  if (!identical(as.integer(phylo_mu$q), 4L)) {
    return(NULL)
  }
  structured_type <- structured_mu_type(phylo_mu)
  cor_key <- structured_mu_correlation_key(phylo_mu)
  type_title <- structured_q4_diagnostic_title(structured_type)
  count_label <- if (identical(structured_type, "phylo")) {
    "n_species"
  } else {
    "n_levels"
  }
  min_count_label <- if (identical(structured_type, "phylo")) {
    "min_species_n"
  } else {
    "min_level_n"
  }

  index <- phylo_mu$observation_node_index
  counts <- tabulate(match(index, unique(index)))
  min_count <- if (length(counts) > 0L) min(counts) else NA_integer_
  n_levels <- length(counts)
  weak_level_count <- n_levels < 8L
  weak_replication <- is.finite(min_count) && min_count < 2L

  sd_summaries <- bivariate_phylo_q4_sd_summaries(object, phylo_mu)
  correlations <- object$corpars[[cor_key]]
  max_abs_cor <- max_abs_finite_or_na(correlations)

  weak_location_sd <- is.finite(sd_summaries$min_location_sd_ratio) &&
    sd_summaries$min_location_sd_ratio < 0.05
  weak_scale_sd <- is.finite(sd_summaries$min_log_sigma_sd) &&
    sd_summaries$min_log_sigma_sd < 0.05
  near_rho_boundary <- !is.finite(max_abs_cor) || max_abs_cor > rho_boundary

  check_row(
    paste0("biv_", structured_type, "_q4_covariance"),
    if (near_rho_boundary) {
      "warning"
    } else if (
      weak_level_count ||
        weak_replication ||
        weak_location_sd ||
        weak_scale_sd
    ) {
      "note"
    } else {
      "ok"
    },
    paste0(
      "group=",
      phylo_mu$group,
      "; block=",
      paste(unique(phylo_mu_endpoint_blocks(phylo_mu)), collapse = "/"),
      "; covariance_mode=",
      phylo_mu_covariance_mode(phylo_mu),
      "; q=4",
      "; ",
      count_label,
      "=",
      n_levels,
      "; ",
      min_count_label,
      "=",
      min_count,
      "; min_location_sd_ratio=",
      format_check_number(sd_summaries$min_location_sd_ratio),
      "; min_log_sigma_sd=",
      format_check_number(sd_summaries$min_log_sigma_sd),
      "; max_abs_cor=",
      format_check_number(max_abs_cor),
      "; boundary=",
      format_check_number(rho_boundary)
    ),
    bivariate_phylo_q4_diagnostic_message(
      type_title,
      near_rho_boundary,
      weak_level_count,
      weak_replication,
      weak_location_sd,
      weak_scale_sd
    )
  )
}

bivariate_phylo_q4_sd_summaries <- function(object, phylo_mu) {
  sdpars <- object$sdpars$mu
  labels <- phylo_mu_sd_labels(phylo_mu, object$model$model_type)
  dpars <- phylo_mu_dpars(phylo_mu)
  sd_values <- unname(sdpars[match(labels, names(sdpars))])

  location <- dpars %in% c("mu1", "mu2")
  scale <- dpars %in% c("sigma1", "sigma2")
  sigma_values <- tryCatch(stats::sigma(object), error = function(e) e)
  if (!inherits(sigma_values, "error") && is.list(sigma_values)) {
    residual_scale <- c(
      mu1 = mean(sigma_values$sigma1, na.rm = TRUE),
      mu2 = mean(sigma_values$sigma2, na.rm = TRUE)
    )
    location_ratios <- sd_values[location] / residual_scale[dpars[location]]
  } else {
    location_ratios <- rep(NA_real_, sum(location))
  }

  list(
    min_location_sd_ratio = min_finite_or_na(location_ratios),
    min_log_sigma_sd = min_finite_or_na(sd_values[scale])
  )
}

bivariate_phylo_q4_diagnostic_message <- function(
  type_title,
  near_rho_boundary,
  weak_level_count,
  weak_replication,
  weak_location_sd,
  weak_scale_sd
) {
  if (near_rho_boundary) {
    return(paste(
      "At least one latent",
      tolower(type_title),
      "q4 correlation is close to +/-1;",
      "profile, simulate, or simplify before interpreting the structured correlations."
    ))
  }
  weak <- c(
    if (weak_level_count) {
      paste("few levels for a four-endpoint", tolower(type_title), "block")
    },
    if (weak_replication) {
      "at least one observed level has fewer than two fitted observations"
    },
    if (weak_location_sd) {
      paste(
        "at least one",
        tolower(type_title),
        "location SD is tiny relative to residual scale"
      )
    },
    if (weak_scale_sd) {
      paste("at least one", tolower(type_title), "log-sigma SD is tiny")
    }
  )
  if (length(weak) > 0L) {
    return(paste(
      type_title,
      "q4 location-scale covariance is fitted, but",
      paste(weak, collapse = "; "),
      "so interpret all six latent structured correlations cautiously."
    ))
  }
  paste(
    type_title,
    "q4 location-scale covariance has replicated levels, non-negligible fitted component SDs, and latent correlations away from the boundary."
  )
}

structured_q4_diagnostic_title <- function(structured_type) {
  switch(
    structured_type,
    phylo = "Phylogenetic",
    spatial = "Spatial",
    animal = "Animal-model",
    relmat = "relmat",
    structured_type
  )
}

bivariate_phylo_mu_has_same_group_covariance <- function(object) {
  blocks <- object$model$random$covariance_blocks
  if (
    is.null(blocks) ||
      is.null(blocks$blocks) ||
      is.null(blocks$members) ||
      nrow(blocks$blocks) == 0L ||
      nrow(blocks$members) == 0L
  ) {
    return(FALSE)
  }
  phylo_group <- object$model$structured$phylo_mu$group
  candidate_blocks <- blocks$blocks$block_id0[
    blocks$blocks$level == "group" &
      blocks$blocks$group == phylo_group &
      blocks$blocks$implemented
  ]
  if (length(candidate_blocks) == 0L) {
    return(FALSE)
  }
  any(vapply(
    candidate_blocks,
    function(block_id) {
      members <- blocks$members[blocks$members$block_id0 == block_id, ]
      all(c("mu1", "mu2") %in% members$dpar)
    },
    logical(1L)
  ))
}

bivariate_phylo_mu_sd_ratios <- function(object) {
  sdpars <- object$sdpars$mu
  if (is.null(sdpars) || length(sdpars) == 0L) {
    return(numeric())
  }
  phylo_label <- object$model$structured$phylo_mu$label
  phylo_names <- paste0(c("mu1:", "mu2:"), phylo_label)
  sd_values <- unname(sdpars[phylo_names])
  sigma_values <- tryCatch(stats::sigma(object), error = function(e) e)
  if (inherits(sigma_values, "error") || !is.list(sigma_values)) {
    return(rep(NA_real_, length(sd_values)))
  }
  residual_scale <- c(
    mu1 = mean(sigma_values$sigma1, na.rm = TRUE),
    mu2 = mean(sigma_values$sigma2, na.rm = TRUE)
  )
  sd_values / residual_scale
}

bivariate_phylo_mu_diagnostic_message <- function(
  near_rho_boundary,
  weak_replication,
  weak_sd,
  same_group_covariance = FALSE
) {
  if (near_rho_boundary && same_group_covariance) {
    return(paste(
      "The fitted phylogenetic mean-mean correlation is close to +/-1, and",
      "the model also includes an ordinary group-level covariance for the",
      "same grouping factor; compare simpler structured-effect models before",
      "interpreting separate phylogenetic and non-phylogenetic correlations."
    ))
  }
  if (near_rho_boundary && (weak_replication || weak_sd)) {
    return(paste(
      "The fitted phylogenetic mean-mean correlation is close to +/-1 and",
      "replication or phylogenetic SD evidence is weak; inspect profiles,",
      "species replication, or a simpler structured-effect model before",
      "interpreting this correlation."
    ))
  }
  if (near_rho_boundary) {
    return(paste(
      "The fitted phylogenetic mean-mean correlation is close to +/-1;",
      "inspect likelihood profiles or compare against a model without the",
      "bivariate phylogenetic covariance before interpreting it."
    ))
  }
  if (same_group_covariance && (weak_replication || weak_sd)) {
    return(paste(
      "The model also includes an ordinary group-level covariance for the same",
      "grouping factor, and replication or phylogenetic SD evidence is weak;",
      "inspect profiles or simpler comparison models before interpreting",
      "phylogenetic and non-phylogenetic species correlations as cleanly",
      "separated."
    ))
  }
  if (weak_replication && weak_sd) {
    return(paste(
      "At least one observed species has fewer than two fitted observations",
      "and at least one phylogenetic location SD is tiny relative to its",
      "matching residual scale; interpret the phylogenetic correlation",
      "cautiously."
    ))
  }
  if (weak_replication) {
    return(paste(
      "At least one observed species has fewer than two fitted observations;",
      "interpret the phylogenetic mean-mean correlation cautiously."
    ))
  }
  if (weak_sd) {
    return(paste(
      "At least one phylogenetic location SD is tiny relative to its matching",
      "residual scale; the phylogenetic mean-mean correlation may be weakly",
      "identified."
    ))
  }
  if (same_group_covariance) {
    return(paste(
      "The model also includes an ordinary group-level covariance for the same",
      "grouping factor; inspect profiles or simpler comparison models before",
      "interpreting phylogenetic and non-phylogenetic species correlations as",
      "cleanly separated."
    ))
  }
  "Bivariate phylogenetic location covariance has replicated species and non-negligible fitted SDs relative to residual scales."
}

format_check_number <- function(x) {
  formatC(x, digits = 4L, format = "fg", flag = "#")
}
