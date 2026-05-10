#' Check convergence and diagnostic flags for a drmTMB fit
#'
#' `check_drm()` runs a compact set of model-fit diagnostics. It is intended as
#' a first-pass guardrail before interpreting distributional models, especially
#' fits with random effects, known sampling covariance, phylogenetic location
#' effects, or bivariate residual correlation `rho12`.
#'
#' The current checks cover optimizer convergence, finite objective values,
#' fixed-parameter gradients, Hessian status from [TMB::sdreport()], dropped
#' rows, positive scale parameters, bivariate residual-correlation `rho12`
#' values near the boundary, Student-t `nu` boundary behaviour, known sampling
#' covariance summaries, random-effect replication, and random-slope design
#' variation. If the fit was stored with
#' `drm_control(keep_tmb_object = FALSE)`, the fixed-gradient check is reported
#' as a note because the TMB automatic-differentiation object is not available.
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
check_drm.drmTMB <- function(object, gradient_tolerance = 1e-3,
                             rho_boundary = 0.98, ...) {
  dots <- list(...)
  if (length(dots) > 0L) {
    cli::cli_abort(
      "{.arg ...} is reserved for future {.fn check_drm} diagnostic options."
    )
  }
  validate_check_scalar(gradient_tolerance, "gradient_tolerance", lower = 0)
  validate_check_scalar(rho_boundary, "rho_boundary", lower = 0, upper = 1)

  rows <- list(
    check_optimizer_convergence(object),
    check_finite_objective(object),
    check_fixed_gradient(object, gradient_tolerance = gradient_tolerance),
    check_hessian(object),
    check_dropped_rows(object),
    check_scale_positive(object),
    check_rho12_boundary(object, rho_boundary = rho_boundary),
    check_student_nu(object),
    check_known_v(object),
    check_random_effect_replication(object, "mu"),
    check_random_effect_replication(object, "sigma"),
    check_random_effect_design(object, "mu"),
    check_random_effect_design(object, "sigma"),
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
  if (!is.numeric(x) || length(x) != 1L || is.na(x) || !is.finite(x) ||
      x <= lower || x >= upper) {
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

check_finite_objective <- function(object) {
  values <- c(object$opt$objective, object$logLik)
  ok <- all(is.finite(values))
  check_row(
    "finite_objective",
    if (ok) "ok" else "error",
    format_check_number(object$opt$objective),
    if (ok) "Objective and log-likelihood are finite." else "Objective or log-likelihood is not finite."
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
  ok <- length(scale_values) > 0L && all(is.finite(scale_values)) &&
    all(scale_values > 0)
  check_row(
    "positive_scale",
    if (ok) "ok" else "error",
    paste0("min=", format_check_number(min(scale_values, na.rm = TRUE))),
    if (ok) "All fitted scale values are finite and positive." else "At least one fitted scale value is non-positive or non-finite."
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
      paste0("All fitted residual correlations have absolute value <= ", rho_boundary, ".")
    } else {
      paste0("At least one fitted residual correlation is close to +/-1 using boundary ", rho_boundary, ".")
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
    "range=[", format_check_number(min_nu),
    ",", format_check_number(max_nu), "]"
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
    eig <- eigen((object$model$V_known + t(object$model$V_known)) / 2,
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
        "type=matrix; n=", length(eig),
        "; rank=", rank,
        "; cond=", format_check_number(condition)
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
      "type=", known_type,
      "; n=", length(known_diag),
      "; range=[", format_check_number(min(known_diag, na.rm = TRUE)),
      ",", format_check_number(max(known_diag, na.rm = TRUE)), "]"
    ),
    if (ok) {
      "Known sampling covariance is recorded through meta_known_V(V = V)."
    } else {
      "Known sampling variances contain non-finite or negative values."
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
  min_counts <- vapply(seq_len(re$n_terms), function(k) {
    min(tabulate(re$index[, k], nbins = re$n_re)[re$index[, k]])
  }, integer(1))
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
  slope_terms <- which(!vapply(re$labels, random_effect_label_is_intercept, logical(1)))
  correlated_ranks <- random_effect_correlated_block_ranks(re)
  if (length(slope_terms) == 0L && length(correlated_ranks) == 0L) {
    return(NULL)
  }

  unique_counts <- vapply(slope_terms, function(k) {
    min(vapply(split(re$value[, k], re$index[, k]), random_effect_unique_n, integer(1)))
  }, integer(1))
  names(unique_counts) <- re$labels[slope_terms]

  values <- character()
  if (length(unique_counts) > 0L) {
    values <- c(values, paste0(
      "min_unique=",
      paste(names(unique_counts), unique_counts, sep = "=", collapse = "; ")
    ))
  }
  if (length(correlated_ranks) > 0L) {
    values <- c(values, paste0(
      "min_rank=",
      paste(names(correlated_ranks), correlated_ranks, sep = "=", collapse = "; ")
    ))
  }

  weak_unique <- length(unique_counts) > 0L && any(unique_counts < 2L)
  weak_rank <- length(correlated_ranks) > 0L &&
    any(as.integer(sub("/.*", "", correlated_ranks)) <
      as.integer(sub(".*/", "", correlated_ranks)))
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
  term_cor_id <- vapply(seq_len(re$n_terms), function(k) {
    ids <- unique(re$re_cor_id0[re$term_id0 == k - 1L])
    ids <- ids[ids >= 0L]
    if (length(ids) == 0L) -1L else ids[[1L]]
  }, integer(1))
  out <- character()
  for (cor_id in unique(term_cor_id[term_cor_id >= 0L])) {
    cols <- which(term_cor_id == cor_id)
    group_id <- re$index[, cols[[1L]]]
    ranks <- vapply(split(seq_along(group_id), group_id), function(row) {
      qr(re$value[row, cols, drop = FALSE])$rank
    }, integer(1))
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
