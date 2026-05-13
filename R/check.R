#' Check convergence and diagnostic flags for a drmTMB fit
#'
#' `check_drm()` runs a compact set of model-fit diagnostics. It is intended as
#' a first-pass guardrail before interpreting distributional models, especially
#' fits with random effects, known sampling covariance, phylogenetic location
#' effects, or bivariate residual correlation `rho12`.
#'
#' The current checks cover optimizer convergence, finite objective values,
#' optimizer evaluation counts, fixed-parameter gradients, Hessian status from
#' [TMB::sdreport()], finite fixed-effect standard errors, dropped rows,
#' positive scale parameters, random-effect standard deviations near the lower
#' boundary, bivariate residual-correlation `rho12` values near the boundary,
#' Student-t `nu` boundary behaviour, known sampling covariance summaries, dense
#' fixed-effect design size, random-effect replication, and random-slope design
#' variation. If a univariate Gaussian fit includes a matched labelled
#' `mu`/`sigma` random-intercept covariance block, `check_drm()` also reports
#' group replication and whether either component is tiny relative to its
#' interpretation scale. If a bivariate Gaussian fit includes a matched
#' labelled `mu1`/`mu2` random-intercept covariance block, `check_drm()` reports
#' group replication and whether either group-level SD is tiny relative to the
#' matching residual scale. For a matched labelled `sigma1`/`sigma2` block, it
#' reports group replication and whether either log-`sigma` random-effect SD is
#' tiny. If the fit was stored with `drm_control(keep_tmb_object = FALSE)`, the
#' fixed-gradient check is reported as a note because the TMB
#' automatic-differentiation object is not available.
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
#' @param rho_boundary Absolute residual correlation value above which a
#'   bivariate Gaussian fit receives a warning.
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
    check_hessian(object),
    check_standard_errors_finite(object),
    check_dropped_rows(object),
    check_scale_positive(object),
    check_random_effect_sd_boundary(object, sd_boundary = sd_boundary),
    check_rho12_boundary(object, rho_boundary = rho_boundary),
    check_student_nu(object),
    check_known_v(object),
    check_fixed_effect_design_size(object),
    check_random_effect_replication(object, "mu"),
    check_random_effect_replication(object, "sigma"),
    check_random_effect_design(object, "mu"),
    check_random_effect_design(object, "sigma"),
    check_mu_sigma_random_effect_covariance(object),
    check_biv_mu_sigma_random_effect_covariance(object),
    check_biv_mu_random_effect_covariance(object),
    check_biv_sigma_random_effect_covariance(object),
    check_phylo_replication(object)
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
  ok <- max_abs <= gradient_tolerance
  check_row(
    "fixed_gradient",
    if (ok) "ok" else "warning",
    format_check_number(max_abs),
    if (ok) {
      paste0("Maximum absolute fixed gradient is <= ", gradient_tolerance, ".")
    } else {
      paste0("Maximum absolute fixed gradient is > ", gradient_tolerance, ".")
    }
  )
}

check_hessian <- function(object) {
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

check_standard_errors_finite <- function(object) {
  vcov <- tryCatch(stats::vcov(object), error = function(e) e)
  if (inherits(vcov, "error")) {
    return(check_row(
      "standard_errors_finite",
      "warning",
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
    eig <- eigen(
      (object$model$V_known + t(object$model$V_known)) / 2,
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
    status <- if (!ok) {
      "error"
    } else if (rank < length(eig) || condition > 1e8) {
      "note"
    } else {
      "ok"
    }
    return(check_row(
      "known_sampling_covariance",
      status,
      paste0(
        "type=matrix; n=",
        length(eig),
        "; rank=",
        rank,
        "; cond=",
        format_check_number(condition)
      ),
      if (identical(status, "note")) {
        "Known sampling covariance is recorded; inspect rank or conditioning if estimates are unstable."
      } else if (identical(status, "ok")) {
        "Known sampling covariance is recorded as a dense matrix with finite non-negative diagonal."
      } else {
        "Known sampling covariance has a non-finite or negative diagonal entry."
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

check_fixed_effect_design_size <- function(object) {
  X <- object$model$X
  if (is.null(X) || length(X) == 0L) {
    return(NULL)
  }
  sizes_mb <- vapply(
    X,
    function(x) {
      as.numeric(utils::object.size(x)) / 1024^2
    },
    numeric(1)
  )
  cols <- vapply(
    X,
    function(x) {
      if (is.null(dim(x))) {
        return(0L)
      }
      ncol(x)
    },
    integer(1)
  )
  total_mb <- sum(sizes_mb)
  max_cols <- max(cols, 0L)
  largest <- names(sizes_mb)[[which.max(sizes_mb)]]
  if (is.null(largest) || is.na(largest) || !nzchar(largest)) {
    largest <- "unnamed"
  }
  note <- total_mb >= 25 || max_cols >= 30L
  value <- paste0(
    "total_mb=",
    format_check_number(total_mb),
    "; max_cols=",
    max_cols,
    "; largest=",
    largest
  )
  check_row(
    "fixed_effect_design_size",
    if (note) "note" else "ok",
    value,
    if (note) {
      paste(
        "Dense fixed-effect design matrices are large enough to inspect;",
        "high-cardinality factors or interactions may dominate memory before TMB optimization."
      )
    } else {
      "Dense fixed-effect design matrices are modest for this fit."
    }
  )
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

check_mu_sigma_random_effect_covariance <- function(object) {
  if (!identical(object$model$model_type, "gaussian")) {
    return(NULL)
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

  sigma_terms <- unique(re_sigma$term_id0[sigma_rows] + 1L)
  mu_rows <- re_mu_sigma$sigma_cross_mu_index0[sigma_rows] + 1L
  mu_terms <- unique(re_mu$term_id0[mu_rows] + 1L)
  if (length(sigma_terms) != 1L || length(mu_terms) != 1L) {
    return(check_row(
      "mu_sigma_random_effect_covariance",
      "note",
      paste0("n_cors=", re_mu_sigma$n_cors),
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

  sigma_terms <- unique(re_sigma$term_id0[sigma_rows] + 1L)
  mu_rows <- re_mu_sigma$sigma_cross_mu_index0[sigma_rows] + 1L
  mu_terms <- unique(re_mu$term_id0[mu_rows] + 1L)
  if (length(sigma_terms) != 1L || length(mu_terms) != 1L) {
    return(check_row(
      "biv_mu_sigma_random_effect_covariance",
      "note",
      paste0("n_cors=", re_mu_sigma$n_cors),
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

format_check_number <- function(x) {
  formatC(x, digits = 4L, format = "fg", flag = "#")
}
