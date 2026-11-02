#!/usr/bin/env Rscript
# Engine-neutral classification of diagnostic fields for one already-fitted S7
# target.  It deliberately records unavailable rather than reaching into an
# undocumented covariance representation for constrained coordinates.

r071_s7_delta_derivative <- function(target) {
  eta <- as.numeric(target$link_estimate[[1L]])
  if (!is.finite(eta)) return(NA_real_)
  switch(
    as.character(target$transformation[[1L]]),
    linear_predictor = 1,
    exp = exp(eta),
    plogis = stats::plogis(eta) * stats::plogis(-eta),
    tanh = 0.999999 * (1 - tanh(eta)^2),
    rho12_tanh = 0.999999 * (1 - tanh(eta)^2),
    NA_real_
  )
}

r071_s7_target_variance <- function(fit, target, engine) {
  parameter <- as.character(target$tmb_parameter[[1L]])
  index <- as.integer(target$index[[1L]])
  if (!nzchar(parameter) || is.na(index) || index < 1L) return(NA_real_)
  if (identical(engine, "tmb")) {
    covariance <- fit$sdr$cov.fixed
    positions <- which(names(fit$opt$par) == parameter)
    if (!is.matrix(covariance) || length(positions) < index || positions[[index]] > nrow(covariance)) {
      return(NA_real_)
    }
    return(covariance[positions[[index]], positions[[index]]])
  }
  covariance <- fit$vcov
  position <- match(parameter, rownames(covariance))
  if (!is.matrix(covariance) || is.na(position) || position > nrow(covariance)) return(NA_real_)
  covariance[position, position]
}

r071_s7_fit_diagnostics <- function(fit, target, engine = c("tmb", "julia")) {
  engine <- match.arg(engine)
  if (!is.data.frame(target) || nrow(target) != 1L ||
      !all(c("tmb_parameter", "index", "link_estimate", "transformation") %in% names(target))) {
    stop("S7 fit diagnostics need one complete profile target row", call. = FALSE)
  }
  variance <- r071_s7_target_variance(fit, target, engine)
  derivative <- r071_s7_delta_derivative(target)
  std_error <- if (is.finite(variance) && variance >= 0 && is.finite(derivative)) {
    abs(derivative) * sqrt(variance)
  } else {
    NA_real_
  }
  std_error_status <- if (is.finite(std_error)) {
    "finite"
  } else if (is.finite(variance) && variance < 0) {
    "nonfinite"
  } else {
    "unavailable"
  }
  convergence <- fit$opt$convergence
  convergence_status <- if (length(convergence) != 1L || is.na(convergence)) {
    "unavailable"
  } else if (identical(as.integer(convergence), 0L)) {
    "converged"
  } else {
    "not_converged"
  }
  gradient <- if (identical(engine, "tmb")) {
    if (length(fit$gradient_max_component) == 1L) {
      fit$gradient_max_component
    } else if (length(fit$gradient)) {
      max(abs(fit$gradient))
    } else {
      NA_real_
    }
  } else {
    value <- fit$diagnostics$gradient
    if (length(value)) max(abs(value)) else NA_real_
  }
  gradient <- as.numeric(gradient)[[1L]]
  gradient_status <- if (is.finite(gradient) && gradient >= 0) "finite" else "unavailable"
  hessian_status <- if (!identical(engine, "tmb")) {
    "unavailable"
  } else if (is.null(fit$sdr$pdHess)) {
    "unavailable"
  } else if (isTRUE(fit$sdr$pdHess)) {
    "positive_definite"
  } else {
    "nonpositive"
  }
  list(
    std_error = std_error, std_error_status = std_error_status,
    convergence_status = convergence_status, gradient_max_abs = gradient,
    gradient_status = gradient_status, hessian_status = hessian_status
  )
}
