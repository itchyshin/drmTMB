# Internal numerical kernels for the experimental MSPL binomial-GLMM route.
#
# These helpers intentionally have no public API and do not fit a model.  They
# implement the two penalty terms in Sterzinger & Kosmidis (2023), equations
# (4)--(5), on inputs supplied by a future fitting adapter.  In particular,
# `mspl_jeffreys()` is the fixed-effect GLM penalty and does not include
# random effects in its information matrix.  It accepts a `link` argument as
# internal scaffolding for a future link-general MSPL adapter, but the public
# MSPL entry point (`drm_validate_mspl_request()` in R/mspl-estimator.R)
# still rejects every link except logit.

mspl_failure <- function(code, message, ...) {
  structure(
    c(list(ok = FALSE, code = code, message = message), list(...)),
    class = "drm_mspl_numerical_failure"
  )
}

mspl_scalar_or_vector <- function(x, n, name, integer = FALSE, positive = FALSE) {
  if (!is.numeric(x) || length(x) == 0L) {
    return(mspl_failure("invalid_input", paste0(name, " must be numeric.")))
  }
  if (length(x) == 1L) {
    x <- rep.int(x, n)
  }
  if (length(x) != n || any(!is.finite(x))) {
    return(mspl_failure(
      "invalid_input",
      paste0(name, " must be finite and have length one or nrow(X).")
    ))
  }
  if (integer && any(x < 0 | x != floor(x))) {
    return(mspl_failure(
      "invalid_input",
      paste0(name, " must contain non-negative integers.")
    ))
  }
  if (positive && any(x <= 0)) {
    return(mspl_failure("invalid_input", paste0(name, " must be positive.")))
  }
  structure(list(ok = TRUE, value = as.numeric(x)), class = "drm_mspl_input")
}

# Numerically stable log(1 + exp(x)).  This preserves the logit information
# calculation when plogis(eta) is rounded to zero or one.
mspl_softplus <- function(x) {
  pmax(x, 0) + log1p(exp(-abs(x)))
}

# Binomial working weight, log scale, for a general link mu = g^{-1}(eta):
#   w = n * (dmu/deta)^2 / (mu * (1 - mu))
#   log w = log(n) + 2*log|dmu/deta| - log(mu) - log(1 - mu)
# These are the EXPECTED (Fisher) information weights, not the observed
# information; the two coincide only for the canonical logit link.  Every
# branch is a closed form on the log scale so that mu and 1 - mu are never
# formed as probabilities and subtracted or multiplied together, which would
# give 0/0 for cloglog at eta >~ 6.6 and for probit at |eta| >~ 38.
mspl_log_weight <- function(eta, n_trials, link = "logit") {
  switch(
    link,
    logit = log(n_trials) - mspl_softplus(eta) - mspl_softplus(-eta),
    probit = log(n_trials) + 2 * stats::dnorm(eta, log = TRUE) -
      stats::pnorm(eta, log.p = TRUE) -
      stats::pnorm(eta, lower.tail = FALSE, log.p = TRUE),
    cloglog = log(n_trials) + 2 * eta - exp(eta) - mspl_log_cloglog_mu(eta),
    cli::cli_abort("Unsupported link {.val {link}} for the MSPL Jeffreys weight.")
  )
}

# log(mu) for cloglog, i.e. log(1 - exp(-exp(eta))), correct in BOTH tails.
#
# The direct form log(-expm1(-exp(eta))) is right as eta -> +Inf but WRONG as
# eta -> -Inf: exp(eta) underflows to exactly 0 below eta = -745.13, so
# -expm1(-0) is 0 and log(0) is -Inf, which makes the Jeffreys weight
# log(n) + 2*eta - exp(eta) - (-Inf) = +Inf -- the WRONG SIGN of infinity for a
# weight that is tending to zero (w -> n*mu -> 0).  Measured: eta = -745 gives
# -745.56 (correct), eta = -746 gives +Inf.
#
# The series fixes it. For small x = exp(eta),
#   1 - exp(-x) = x*(1 - x/2 + x^2/6 - ...)  =>  log mu = eta + log1p(-x/2 + ...)
# so log w -> log(n) + eta, which is the correct limit.  A finiteness guard
# downstream currently converts the +Inf into a failure rather than corrupting a
# fit, but it would become the dominant weight in max() if that guard were ever
# relaxed, so fix it at the source.  (Noether, Phase B review.)
# Branch with indexing rather than ifelse(): ifelse() evaluates BOTH arms over
# the whole vector, so the series arm would run at large positive eta where
# -x/2 is hugely negative and log1p() returns NaN with a warning. The result
# would still be correct (the NaN lands in the discarded arm), but warning-free
# code is worth more than the brevity.
mspl_log_cloglog_mu <- function(eta) {
  x <- exp(eta)
  out <- numeric(length(eta))
  small <- x < 1e-8
  out[small] <- eta[small] + log1p(-x[small] / 2)
  out[!small] <- log(-expm1(-x[!small]))
  out
}

# Inverse link mu = g^{-1}(eta), closed form and unclamped, matching the
# weight branches above exactly (never stats::make.link() or
# binomial()$linkinv, which clamp mu into [eps, 1 - eps]).
mspl_link_mu <- function(eta, link = "logit") {
  switch(
    link,
    logit = stats::plogis(eta),
    probit = stats::pnorm(eta),
    cloglog = -expm1(-exp(eta)),
    cli::cli_abort("Unsupported link {.val {link}} for the MSPL inverse link.")
  )
}

mspl_c_n <- function(p, n_eff) {
  if (
    !is.numeric(p) || length(p) != 1L || !is.finite(p) || p < 1 ||
      p != floor(p) || !is.numeric(n_eff) || length(n_eff) != 1L ||
      !is.finite(n_eff) || n_eff <= 0
  ) {
    return(mspl_failure(
      "invalid_scaling",
      "p must be a positive integer and n_eff must be positive and finite."
    ))
  }
  structure(
    list(ok = TRUE, p = as.integer(p), n_eff = as.numeric(n_eff),
         c_n = 2 * sqrt(p / n_eff)),
    class = "drm_mspl_scaling"
  )
}

# Compute the fixed-effect Jeffreys term for a binomial GLM.  `trials` and
# `frequency` are integer multiplicities: each row contributes
# `trials * frequency` Bernoulli observations.  The returned
# `information_scaled` and `log_weight_scale` are a lossless log-scale
# representation of X' W X, preventing underflow for extreme eta.  `link`
# defaults to "logit"; other links are internal scaffolding only (see the
# file-level comment above) and are not reachable from the public MSPL entry
# point today.
mspl_jeffreys <- function(
  X, beta, offset = 0, trials = 1L, frequency = 1L, link = "logit",
  rank_tol = sqrt(.Machine$double.eps)
) {
  if (!is.matrix(X) || !is.numeric(X) || nrow(X) == 0L || ncol(X) == 0L ||
      any(!is.finite(X))) {
    return(mspl_failure(
      "invalid_design", "X must be a non-empty finite numeric matrix."
    ))
  }
  n <- nrow(X)
  p <- ncol(X)
  if (!is.numeric(beta) || length(beta) != p || any(!is.finite(beta))) {
    return(mspl_failure(
      "invalid_beta", "beta must be a finite numeric vector of length ncol(X)."
    ))
  }
  if (!is.numeric(rank_tol) || length(rank_tol) != 1L || !is.finite(rank_tol) ||
      rank_tol <= 0) {
    return(mspl_failure("invalid_tolerance", "rank_tol must be positive and finite."))
  }
  offset <- mspl_scalar_or_vector(offset, n, "offset")
  trials <- mspl_scalar_or_vector(trials, n, "trials", integer = TRUE, positive = TRUE)
  frequency <- mspl_scalar_or_vector(
    frequency, n, "frequency", integer = TRUE, positive = TRUE
  )
  if (!offset$ok) return(offset)
  if (!trials$ok) return(trials)
  if (!frequency$ok) return(frequency)

  eta <- drop(X %*% beta) + offset$value
  if (any(!is.finite(eta))) {
    return(mspl_failure(
      "non_finite_predictor", "X %*% beta + offset is not finite."
    ))
  }
  n_trials <- trials$value * frequency$value
  n_eff <- sum(n_trials)
  scaling <- mspl_c_n(p, n_eff)
  mu <- mspl_link_mu(eta, link)
  # log w = log(n) + 2*log|dmu/deta| - log(mu) - log(1-mu), the EXPECTED
  # (Fisher) binomial working weight; see mspl_log_weight() above.  For
  # logit this is -softplus(eta) - softplus(-eta), evaluated without
  # subtracting probabilities that may already have rounded to 0/1.
  #
  # Paired site: src/drmTMB.cpp:4966-4969 carries the same logit-only weight
  # (using logspace_add instead of mspl_softplus).  The two must be
  # generalised together in the arc that opens the MSPL entry point to other
  # links; today they cannot diverge in practice because
  # drm_validate_mspl_request() (R/mspl-estimator.R:179-184) rejects every
  # non-logit link before a model is ever built.
  log_weight <- mspl_log_weight(eta, n_trials, link)
  if (any(!is.finite(log_weight))) {
    return(mspl_failure(
      "non_finite_log_weight",
      "The binomial working weight is not finite for one or more observations.",
      p = p, n_eff = n_eff, c_n = scaling$c_n, eta = eta, mu = mu,
      log_weight = log_weight
    ))
  }
  log_weight_scale <- max(log_weight)
  weight_scaled <- exp(log_weight - log_weight_scale)
  information_scaled <- crossprod(X, X * weight_scaled)
  information_scaled <- (information_scaled + t(information_scaled)) / 2
  chol_scaled <- tryCatch(chol(information_scaled), error = function(e) NULL)
  diagnostics <- mspl_numerical_diagnostics(
    information_scaled, rank_tol = rank_tol, chol_factor = chol_scaled
  )
  if (!diagnostics$full_rank) {
    return(mspl_failure(
      "rank_deficient_information",
      "The scaled fixed-effect information matrix is not numerically full rank.",
      p = p, n_eff = n_eff, c_n = scaling$c_n, eta = eta,
      mu = mu, log_weight = log_weight,
      information_scaled = information_scaled, diagnostics = diagnostics
    ))
  }
  log_determinant <- 2 * sum(log(diag(chol_scaled))) + p * log_weight_scale
  half_logdet <- log_determinant / 2
  if (!is.finite(half_logdet)) {
    return(mspl_failure(
      "non_finite_logdet", "The Jeffreys half log-determinant is not finite.",
      p = p, n_eff = n_eff, c_n = scaling$c_n, diagnostics = diagnostics
    ))
  }
  structure(
    list(
      ok = TRUE,
      p = p,
      n_eff = n_eff,
      c_n = scaling$c_n,
      eta = eta,
      mu = mu,
      log_weight = log_weight,
      log_weight_scale = log_weight_scale,
      weight_scaled = weight_scaled,
      information_scaled = information_scaled,
      half_logdet = half_logdet,
      diagnostics = diagnostics
    ),
    class = "drm_mspl_jeffreys"
  )
}

# Paper-sign convention: D(x) is non-positive.  Its derivative is continuous
# at +/- 1 and has magnitude at most one.
mspl_negative_huber <- function(x, gradient = FALSE) {
  if (!is.numeric(x) || any(!is.finite(x))) {
    stop("x must be a finite numeric vector.", call. = FALSE)
  }
  abs_x <- abs(x)
  value <- ifelse(abs_x <= 1, -0.5 * x^2, -abs_x + 0.5)
  if (!gradient) return(value)
  grad <- ifelse(abs_x <= 1, -x, -sign(x))
  list(value = value, gradient = grad)
}

mspl_huber_cost <- function(x, gradient = FALSE) {
  out <- mspl_negative_huber(x, gradient = gradient)
  if (!gradient) return(-out)
  list(value = -out$value, gradient = -out$gradient)
}

mspl_safe_exp <- function(x, name) {
  max_log <- log(.Machine$double.xmax)
  if (!is.numeric(x) || any(!is.finite(x)) || any(x > max_log)) {
    return(mspl_failure(
      "non_finite_cholesky", paste0(name, " cannot be represented finitely.")
    ))
  }
  structure(list(ok = TRUE, value = exp(x)), class = "drm_mspl_input")
}

mspl_sech <- function(x) {
  z <- exp(-abs(x))
  2 * z / (1 + z^2)
}

mspl_logsech <- function(x) {
  log(2) - abs(x) - log1p(exp(-2 * abs(x)))
}

# q = 1 covariance map.  psi is log(l_11), so Sigma = exp(2 * psi).
mspl_cholesky_q1 <- function(psi) {
  if (!is.numeric(psi) || length(psi) != 1L || !is.finite(psi)) {
    return(mspl_failure("invalid_cholesky_coordinate", "q1 requires one finite log-SD."))
  }
  sd <- mspl_safe_exp(psi, "The q1 SD")
  if (!sd$ok) return(sd)
  variance <- sd$value^2
  if (!is.finite(variance)) {
    return(mspl_failure("non_finite_covariance", "The q1 covariance is not finite."))
  }
  structure(
    list(
      ok = TRUE, q = 1L, coordinates = c(log_sd_1 = psi),
      penalty_coordinates = c(log_l11 = psi),
      cholesky = matrix(sd$value, 1L, 1L), covariance = matrix(variance, 1L, 1L),
      correlation = matrix(1, 1L, 1L),
      jacobian_covariance = matrix(2 * variance, 1L, 1L,
                                   dimnames = list("var_1", "log_sd_1"))
    ),
    class = "drm_mspl_cholesky"
  )
}

# q = 2 covariance map in marginal log-SD / Fisher-z coordinates.  The lower
# Cholesky factor is [s1, 0; s2*tanh(a), s2*sech(a)].  Computing sech directly
# avoids catastrophic cancellation in sqrt(1 - tanh(a)^2).
mspl_cholesky_q2 <- function(psi) {
  if (!is.numeric(psi) || length(psi) != 3L || any(!is.finite(psi))) {
    return(mspl_failure(
      "invalid_cholesky_coordinate",
      "q2 requires c(log_sd_1, log_sd_2, eta_rho), all finite."
    ))
  }
  sd <- mspl_safe_exp(psi[1:2], "A q2 marginal SD")
  if (!sd$ok) return(sd)
  sd1 <- sd$value[[1L]]
  sd2 <- sd$value[[2L]]
  rho <- tanh(psi[[3L]])
  sech <- mspl_sech(psi[[3L]])
  covariance <- matrix(
    c(sd1^2, sd1 * sd2 * rho, sd1 * sd2 * rho, sd2^2), 2L, 2L,
    dimnames = list(c("1", "2"), c("1", "2"))
  )
  if (any(!is.finite(covariance))) {
    return(mspl_failure("non_finite_covariance", "The q2 covariance is not finite."))
  }
  cholesky <- matrix(c(sd1, 0, sd2 * rho, sd2 * sech), 2L, 2L, byrow = TRUE)
  jacobian <- rbind(
    var_1 = c(2 * covariance[1L, 1L], 0, 0),
    cov_12 = c(covariance[1L, 2L], covariance[1L, 2L], sd1 * sd2 * sech^2),
    var_2 = c(0, 2 * covariance[2L, 2L], 0)
  )
  colnames(jacobian) <- c("log_sd_1", "log_sd_2", "eta_rho")
  structure(
    list(
      ok = TRUE, q = 2L,
      coordinates = stats::setNames(psi, c("log_sd_1", "log_sd_2", "eta_rho")),
      # Equation (5) acts on lower-Cholesky coordinates, not directly on the
      # marginal-SD/Fisher-z parameterization used for stable reconstruction.
      penalty_coordinates = c(
        log_l11 = psi[[1L]],
        log_l22 = psi[[2L]] + mspl_logsech(psi[[3L]]),
        l21 = sd2 * rho
      ),
      cholesky = cholesky, covariance = covariance,
      correlation = matrix(c(1, rho, rho, 1), 2L, 2L),
      sech = sech, jacobian_covariance = jacobian
    ),
    class = "drm_mspl_cholesky"
  )
}

mspl_penalty_components <- function(
  X, beta, variance, q = NULL, offset = 0, trials = 1L, frequency = 1L,
  link = "logit",
  rank_tol = sqrt(.Machine$double.eps)
) {
  # `link` is threaded explicitly. This function previously took no link and so
  # silently inherited mspl_jeffreys()'s logit default, which made the COMPOSITE
  # reference logit-only even after the leaves (mspl_jeffreys, mspl_log_weight)
  # were made link-general -- a caller that named nothing about links and
  # therefore matched no search for them. (Noether, doc 253 derivation.)
  jeffreys <- mspl_jeffreys(
    X = X, beta = beta, offset = offset, trials = trials,
    frequency = frequency, link = link, rank_tol = rank_tol
  )
  if (!jeffreys$ok) return(jeffreys)
  if (inherits(variance, "drm_mspl_cholesky")) {
    if (!is.null(q) && (!is.numeric(q) || length(q) != 1L || q != variance$q)) {
      return(mspl_failure(
        "incompatible_q", "q does not match the supplied Cholesky map."
      ))
    }
    variance_map <- variance
  } else if (is.null(q) || !is.numeric(q) || length(q) != 1L || !(q %in% 1:2)) {
    return(mspl_failure(
      "missing_q", "Supply q = 1 or q = 2, or pass an mspl Cholesky map."
    ))
  } else {
    variance_map <- if (q == 1L) mspl_cholesky_q1(variance) else mspl_cholesky_q2(variance)
  }
  if (!variance_map$ok) return(variance_map)
  # Equation (5) acts on lower-Cholesky coordinates log(l_ii), l_ij.  In q2
  # these are derived from the stable marginal-SD/Fisher-z map, never the raw
  # c(log_sd_1, log_sd_2, eta_rho) optimisation coordinates.
  huber <- mspl_negative_huber(variance_map$penalty_coordinates, gradient = TRUE)
  variance_negative_huber <- sum(huber$value)
  jeffreys_bonus <- jeffreys$half_logdet
  log_objective_bonus <- jeffreys$c_n * (jeffreys_bonus + variance_negative_huber)
  structure(
    list(
      ok = TRUE, p = jeffreys$p, n_eff = jeffreys$n_eff, c_n = jeffreys$c_n,
      jeffreys_bonus = jeffreys_bonus,
      variance_negative_huber = variance_negative_huber,
      # This is d P_v / d {log(L_ii), L_ij}; an optimizer in marginal-SD /
      # Fisher-z coordinates must apply the q-specific chain rule itself.
      variance_gradient_cholesky = huber$gradient,
      variance_map = variance_map,
      log_objective_bonus = log_objective_bonus,
      nll_penalty = -log_objective_bonus,
      jeffreys = jeffreys
    ),
    class = "drm_mspl_penalty"
  )
}

# This routine deliberately reports only numerical facts.  An adapter may use
# them in its own policy, but this kernel makes no eligibility or promotion
# decision.
mspl_numerical_diagnostics <- function(information, rank_tol = sqrt(.Machine$double.eps), chol_factor = NULL) {
  if (!is.matrix(information) || nrow(information) != ncol(information) ||
      nrow(information) == 0L || !is.numeric(information)) {
    return(list(status = "invalid_information", finite = FALSE, full_rank = FALSE))
  }
  symmetric <- isTRUE(all.equal(information, t(information), tolerance = 100 * .Machine$double.eps))
  finite <- all(is.finite(information))
  if (!finite || !symmetric) {
    return(list(
      status = if (finite) "non_symmetric_information" else "non_finite_information",
      finite = finite, symmetric = symmetric, full_rank = FALSE,
      rank = NA_integer_, condition_number = NA_real_
    ))
  }
  values <- eigen(information, symmetric = TRUE, only.values = TRUE)$values
  scale <- max(abs(values), 1)
  rank <- sum(values > rank_tol * scale)
  full_rank <- rank == nrow(information) && min(values) > 0
  condition_number <- if (full_rank) max(values) / min(values) else Inf
  if (is.null(chol_factor) && full_rank) {
    chol_factor <- tryCatch(chol(information), error = function(e) NULL)
  }
  list(
    status = if (full_rank && !is.null(chol_factor)) "ok" else "rank_deficient",
    finite = TRUE, symmetric = TRUE, full_rank = full_rank, rank = as.integer(rank),
    rank_tolerance = rank_tol, eigenvalues = values,
    condition_number = condition_number,
    min_abs_chol_diagonal = if (is.null(chol_factor)) NA_real_ else min(abs(diag(chol_factor)))
  )
}
