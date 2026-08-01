# Prepare public uncertainty while both original margin fits are still
# available. The fitted association object otherwise retains immutable margin
# snapshots rather than the full TMB objects. A numerical failure is retained
# as an explicit status so the point estimate remains usable and public S3
# methods can fail informatively without manufacturing an interval.
drm_pair_prepare_alpha_inference <- function(fit_1, fit_2, association_fit) {
  result <- tryCatch(
    drm_pair_general_eta_sandwich(fit_1, fit_2, association_fit),
    error = function(e) drm_pair_sandwich_unavailable(
      paste0("adapter_error: ", conditionMessage(e))
    )
  )
  if (!identical(result$status, "ok")) {
    return(list(
      status = "unavailable",
      reason = result$reason,
      method = "two-stage Godambe-Wald",
      scale = "alpha"
    ))
  }
  covariance <- result$alpha_covariance
  coefficient_names <- drm_pair_alpha_coefficient_names(association_fit)
  dimnames(covariance) <- list(coefficient_names, coefficient_names)
  list(
    status = "available",
    reason = NA_character_,
    method = "two-stage Godambe-Wald",
    scale = "alpha",
    covariance = covariance,
    se = stats::setNames(sqrt(diag(covariance)), coefficient_names),
    n = nrow(association_fit$association_design$matrix),
    pair_class = association_fit$components$pair_class,
    coverage_tier = if (
      identical(association_fit$components$pair_class, "bernoulli_nbinom2") &&
        length(coefficient_names) == 1L &&
        identical(colnames(association_fit$association_design$matrix), "(Intercept)")
    ) "inference_ready_with_caveats" else "interval_feasible",
    validation_domain = "admitted fixed-effect complete-pair latent-normal association route"
  )
}

drm_pair_alpha_coefficient_names <- function(object) {
  terms <- names(object$association_coefficients)
  if (is.null(terms) || any(!nzchar(terms))) {
    terms <- colnames(object$association_design$matrix)
  }
  if (length(terms) == 1L && identical(terms, "(Intercept)")) {
    return("alpha")
  }
  paste0("alpha:", terms)
}

drm_pair_public_alpha_inference <- function(object) {
  if (!inherits(object, "drm_pair_association")) {
    cli::cli_abort("Association uncertainty requires a {.cls drm_pair_association} object.")
  }
  if (!object$status %in% c("interior", "near_boundary")) {
    cli::cli_abort(c(
      "Association uncertainty is unavailable because the alpha estimate is not interior.",
      i = "Inspect {.code object$diagnostics}; no boundary clamp or placeholder interval is returned."
    ))
  }
  inference <- object$alpha_inference
  if (is.null(inference)) {
    cli::cli_abort(c(
      "This association object predates stored two-stage uncertainty.",
      i = "Refit the two margins and reconstruct the association with the current drmTMB version."
    ))
  }
  if (!identical(inference$status, "available")) {
    reason <- if (is.null(inference$reason)) "unknown" else inference$reason
    cli::cli_abort(c(
      "The two-stage alpha covariance is unavailable for this fit.",
      i = "Diagnostic reason: {.val {reason}}. No placeholder interval is returned."
    ))
  }
  covariance <- inference$covariance
  p <- length(object$association_coefficients)
  if (
    !is.matrix(covariance) ||
      !identical(dim(covariance), c(p, p)) ||
      any(!is.finite(covariance)) ||
      any(diag(covariance) <= 0) ||
      any(!is.finite(inference$se)) ||
      any(inference$se <= 0)
  ) {
    cli::cli_abort("The stored two-stage alpha covariance is invalid; no interval is returned.")
  }
  inference
}

drm_pair_warn_alpha_inference <- function(object) {
  n <- nrow(object$association_design$matrix)
  inference <- object$alpha_inference
  if (identical(object$status, "near_boundary")) {
    cli::cli_warn(c(
      "Association uncertainty is interval-feasible but the fitted association is near its numerical boundary.",
      i = "The covariance calculation passed; interpret the Wald interval cautiously and inspect {.code object$diagnostics}."
    ), class = "drmTMB_association_inference_warning")
  } else if (
    identical(inference$coverage_tier, "inference_ready_with_caveats") &&
      n < 480L
  ) {
    cli::cli_warn(c(
      "Association uncertainty is experimental for this lower-information fit (n = {n}).",
      i = "The original lower-information campaign had unavailable intervals in some cells; this fit passed its numerical covariance diagnostics.",
      i = "The retained high-information calibration campaign used n = 480 or 960."
    ), class = "drmTMB_association_inference_warning")
  } else if (identical(inference$coverage_tier, "inference_ready_with_caveats")) {
    cli::cli_warn(c(
      "Association uncertainty is inference-ready with caveats.",
      i = "Coverage was calibrated for a retained high-information Bernoulli x ordinary-NB2 intercept grid, not every prevalence, dispersion, or association strength."
    ), class = "drmTMB_association_inference_warning")
  } else {
    cli::cli_warn(c(
      "Association uncertainty is interval-feasible; coverage is not yet calibrated for this route.",
      i = "The two-stage Godambe covariance passed fit-specific diagnostics. Treat the Wald interval as experimental until a route-specific coverage campaign is completed."
    ), class = "drmTMB_association_inference_warning")
  }
  invisible(NULL)
}

# Internal router for the admitted fixed-effect, frozen-margin latent-normal
# association classes. Its Godambe alpha block supplies the public `vcov()` /
# `confint()` surface for every route whose fit-specific covariance diagnostics
# pass. Coverage calibration remains a separate, higher evidence tier.
drm_pair_general_eta_sandwich <- function(
  fit_1,
  fit_2,
  association_fit,
  control = drm_pair_sandwich_control()
) {
  if (!inherits(association_fit, "drm_pair_association")) {
    cli::cli_abort("The private staged sandwich needs a {.cls drm_pair_association} object.")
  }
  adapter <- switch(
    association_fit$components$pair_class,
    gaussian_bernoulli = drm_pair_gaussian_bernoulli_eta_sandwich,
    gaussian_nbinom2 = drm_pair_gaussian_nbinom2_eta_sandwich,
    bernoulli_bernoulli = drm_pair_bernoulli_bernoulli_sandwich,
    bernoulli_nbinom2 = drm_pair_staged_eta_sandwich,
    nbinom2_nbinom2 = drm_pair_nbinom2_nbinom2_sandwich,
    NULL
  )
  if (is.null(adapter)) {
    cli::cli_abort("No private staged-sandwich adapter exists for this association pair class.")
  }
  adapter(fit_1, fit_2, association_fit, control = control)
}

# Two-stage sandwich variance for the staged Bernoulli x NB2 association
# estimator. The alpha block is exposed publicly for both the constant and
# admitted fixed-effect association formulas; eta-scale delta intervals remain
# internal.

drm_pair_staged_eta_sandwich <- function(
  fit_1,
  fit_2,
  association_fit,
  control = drm_pair_sandwich_control()
) {
  if (
    !inherits(association_fit, "drm_pair_association") ||
      !identical(association_fit$components$pair_class, "bernoulli_nbinom2")
  ) {
    cli::cli_abort(
      "The staged sandwich is defined only for Bernoulli x ordinary-NB2 association fits."
    )
  }
  if (!association_fit$status %in% c("interior", "near_boundary")) {
    return(drm_pair_sandwich_unavailable("association_unresolved"))
  }
  fits <- list(fit_1, fit_2)
  types <- vapply(fits, function(x) x$model$model_type, character(1L))
  if (!setequal(types, c("binomial", "nbinom2"))) {
    cli::cli_abort(
      "The staged sandwich needs the original Bernoulli and ordinary-NB2 margin fits."
    )
  }
  binary_fit <- fits[[which(types == "binomial")]]
  nbinom2_fit <- fits[[which(types == "nbinom2")]]
  drm_pair_validate_fit(binary_fit, "binary margin")
  drm_pair_validate_fit(nbinom2_fit, "NB2 margin")
  drm_pair_validate_shared_data(binary_fit, nbinom2_fit)
  drm_pair_validate_bernoulli(binary_fit)
  drm_pair_validate_nbinom2(nbinom2_fit)
  if (!isTRUE(drm_pair_bernoulli_nbinom2_sandwich_provenance(
    fit_1, fit_2, association_fit
  ))) {
    return(drm_pair_sandwich_unavailable("provenance_mismatch"))
  }

  x_b <- as.matrix(binary_fit$model$X$mu)
  x_n <- as.matrix(nbinom2_fit$model$X$mu)
  z_n <- as.matrix(nbinom2_fit$model$X$sigma)
  x_a <- as.matrix(association_fit$association_design$matrix)
  n <- nrow(x_a)
  if (!all(c(nrow(x_b), nrow(x_n), nrow(z_n)) == n)) {
    return(drm_pair_sandwich_unavailable("design_row_mismatch"))
  }
  beta_b <- unname(binary_fit$coefficients$mu)
  beta_n <- unname(nbinom2_fit$coefficients$mu)
  gamma_n <- unname(nbinom2_fit$coefficients$sigma)
  alpha <- unname(association_fit$association_coefficients)
  if (
    length(beta_b) != ncol(x_b) ||
      length(beta_n) != ncol(x_n) ||
      length(gamma_n) != ncol(z_n) ||
      length(alpha) != ncol(x_a)
  ) {
    return(drm_pair_sandwich_unavailable("coefficient_design_mismatch"))
  }

  lambda_b <- as.vector(x_b %*% beta_b)
  xi_n <- as.vector(x_n %*% beta_n)
  tau_n <- as.vector(z_n %*% gamma_n)
  a <- as.vector(x_a %*% alpha)
  p <- stats::plogis(lambda_b)
  mu <- exp(xi_n)
  sigma <- exp(tau_n)
  components <- association_fit$components
  if (
    !identical(binary_fit$model$y, components$binary_y) ||
      !identical(nbinom2_fit$model$y, components$nbinom2_y) ||
    !isTRUE(all.equal(p, components$binary_p, tolerance = 1e-8)) ||
      !isTRUE(all.equal(mu, components$nbinom2_mu, tolerance = 1e-8)) ||
      !isTRUE(all.equal(sigma, components$nbinom2_sigma, tolerance = 1e-8))
  ) {
    return(drm_pair_sandwich_unavailable("frozen_margin_mismatch"))
  }
  if (any(a <= -8 + 0.01 | a >= 8 - 0.01)) {
    return(drm_pair_sandwich_unavailable("association_boundary"))
  }

  marginal <- drm_pair_sandwich_margin_blocks(
    binary_y = components$binary_y,
    nbinom2_y = components$nbinom2_y,
    p = p,
    mu = mu,
    sigma = sigma,
    x_b = x_b,
    x_n = x_n,
    z_n = z_n
  )
  association <- drm_pair_sandwich_association_blocks(
    binary_y = components$binary_y,
    nbinom2_y = components$nbinom2_y,
    lambda_b = lambda_b,
    xi_n = xi_n,
    tau_n = tau_n,
    a = a,
    x_b = x_b,
    x_n = x_n,
    z_n = z_n,
    x_a = x_a,
    control = control
  )
  if (!identical(association$status, "ok")) {
    return(association)
  }

  nbinom2_score <- cbind(marginal$score_n, marginal$score_s)
  colnames(marginal$score_b) <- paste0("bernoulli_mu:", colnames(x_b))
  colnames(nbinom2_score) <- c(
    paste0("nbinom2_mu:", colnames(x_n)),
    paste0("nbinom2_sigma:", colnames(z_n))
  )
  colnames(association$score_a) <- paste0("association:", colnames(x_a))
  assembled <- drm_pair_sandwich_assemble(
    margin_scores = list(marginal$score_b, nbinom2_score),
    margin_bread = list(
      marginal$bread_b,
      rbind(
        cbind(marginal$bread_nn, marginal$bread_ns),
        cbind(t(marginal$bread_ns), marginal$bread_ss)
      )
    ),
    association_score = association$score_a,
    association_bread = list(
      association$bread_ab,
      cbind(association$bread_an, association$bread_as),
      association$bread_aa
    ),
    association_design = x_a,
    association_linear_predictor = a,
    control = control
  )
  if (!identical(assembled$status, "ok")) {
    return(assembled)
  }
  assembled$derivative_diagnostics <- association$derivative_diagnostics
  assembled
}

# Verify the immutable association snapshot before any numerical derivative is
# evaluated. Mixed-family roles remain canonical for the calculation, while
# provenance retains the original caller-side fit order.
drm_pair_bernoulli_nbinom2_sandwich_provenance <- function(
  fit_1,
  fit_2,
  association_fit
) {
  expected_design <- tryCatch(
    drm_pair_association_design(
      association_fit$association, fit_1$data, "bernoulli_nbinom2"
    ),
    error = function(...) NULL
  )
  expected_hashes <- c(
    fit_1 = drm_pair_fingerprint(drm_pair_margin_snapshot(fit_1)),
    fit_2 = drm_pair_fingerprint(drm_pair_margin_snapshot(fit_2))
  )
  expected_names <- c(
    fit_1 = drm_pair_response_name(fit_1),
    fit_2 = drm_pair_response_name(fit_2)
  )
  expected_snapshots <- list(
    fit_1 = drm_pair_margin_snapshot(fit_1),
    fit_2 = drm_pair_margin_snapshot(fit_2)
  )
  expected_roles <- c(
    fit_1 = if (identical(fit_1$model$model_type, "binomial")) {
      "bernoulli"
    } else {
      "nbinom2"
    },
    fit_2 = if (identical(fit_2$model$model_type, "binomial")) {
      "bernoulli"
    } else {
      "nbinom2"
    }
  )
  !is.null(expected_design) &&
    identical(association_fit$provenance$row_id, seq_len(nrow(fit_1$data))) &&
    identical(
      association_fit$provenance$original_row,
      drm_pair_analysis_rows(fit_1)
    ) &&
    identical(
      association_fit$provenance$data_hash,
      drm_pair_fingerprint(fit_1$data)
    ) &&
    identical(association_fit$provenance$fit_hashes, expected_hashes) &&
    identical(association_fit$margins, expected_snapshots) &&
    identical(association_fit$response_names, expected_names) &&
    identical(association_fit$margin_order, expected_roles) &&
    identical(
      association_fit$association_design$matrix,
      expected_design$matrix
    ) &&
    identical(
      colnames(association_fit$association_design$matrix),
      colnames(expected_design$matrix)
    ) &&
    identical(association_fit$association_design$varying, expected_design$varying) &&
    identical(association_fit$association_design$terms, expected_design$terms) &&
    identical(association_fit$association_design$contrasts, expected_design$contrasts) &&
    identical(association_fit$association_design$xlevels, expected_design$xlevels) &&
    identical(association_fit$association_design$column_names, expected_design$column_names) &&
    identical(association_fit$association_design$fingerprint, expected_design$fingerprint)
}

# Assemble the private Godambe estimate for a two-margin staged association
# estimator.  The adapters supply score and derivative blocks in the canonical
# family-role order.  Here theta = (psi_1, psi_2, alpha): its row-average bread
# is lower block triangular, but its meat retains every paired-row score cross
# product without centring.
drm_pair_sandwich_assemble <- function(
  margin_scores,
  margin_bread,
  association_score,
  association_bread,
  association_design,
  association_linear_predictor,
  control
) {
  n <- nrow(association_score)
  score_blocks <- c(margin_scores, list(association_score))
  scores <- do.call(cbind, score_blocks)
  block_sizes <- vapply(score_blocks, ncol, integer(1L))
  block_ends <- cumsum(block_sizes)
  block_starts <- c(1L, utils::head(block_ends, -1L) + 1L)
  block_indices <- Map(seq.int, block_starts, block_ends)
  p_total <- sum(block_sizes)
  bread <- matrix(0, p_total, p_total)
  bread[block_indices[[1L]], block_indices[[1L]]] <- margin_bread[[1L]]
  bread[block_indices[[2L]], block_indices[[2L]]] <- margin_bread[[2L]]
  bread[block_indices[[3L]], block_indices[[1L]]] <- association_bread[[1L]]
  bread[block_indices[[3L]], block_indices[[2L]]] <- association_bread[[2L]]
  bread[block_indices[[3L]], block_indices[[3L]]] <- association_bread[[3L]]
  dimnames(bread) <- list(colnames(scores), colnames(scores))
  meat <- crossprod(scores) / n
  # The margin equations do not depend on alpha.  Only the association score
  # differentiates with respect to fitted margin parameters.
  if (
    any(!is.finite(bread)) ||
      any(!is.finite(meat)) ||
      max(abs(meat - t(meat))) > control$symmetry_tolerance ||
      rcond(bread) <= control$rcond_min
  ) {
    return(drm_pair_sandwich_unavailable("bread_or_meat_unstable"))
  }
  inverse_bread <- tryCatch(solve(bread), error = function(e) e)
  if (inherits(inverse_bread, "error")) {
    return(drm_pair_sandwich_unavailable("bread_solve_failure"))
  }
  covariance <- (inverse_bread %*% meat %*% t(inverse_bread)) / n
  covariance <- (covariance + t(covariance)) / 2
  dimnames(covariance) <- list(colnames(scores), colnames(scores))
  if (
    any(!is.finite(covariance)) ||
      any(diag(covariance) <= 0) ||
      max(abs(covariance - t(covariance))) > control$symmetry_tolerance
  ) {
    return(drm_pair_sandwich_unavailable("covariance_unstable"))
  }
  association_index <- block_indices[[3L]]
  alpha_covariance <- covariance[association_index, association_index, drop = FALSE]
  eta_gradient <- 0.999999 / cosh(association_linear_predictor)^2
  eta_variance <- eta_gradient^2 * rowSums(
    (association_design %*% alpha_covariance) * association_design
  )
  if (any(!is.finite(eta_variance)) || any(eta_variance <= 0)) {
    return(drm_pair_sandwich_unavailable("eta_delta_unstable"))
  }
  list(
    status = "ok",
    covariance = covariance,
    alpha_covariance = alpha_covariance,
    alpha_se = sqrt(diag(alpha_covariance)),
    eta = 0.999999 * tanh(association_linear_predictor),
    eta_se = sqrt(eta_variance),
    scores = scores,
    bread = bread,
    meat = meat,
    control = control
  )
}

drm_pair_sandwich_control <- function() {
  # The rectangle kernel contains adaptive quadrature.  A 1e-2 link-scale
  # stencil is deliberately larger than machine-scale perturbations, and the
  # half-step comparison below still rejects numerically unstable rows.
  list(
    step = 1e-2,
    derivative_relative_tolerance = 1e-3,
    derivative_absolute_tolerance = 1e-6,
    rcond_min = 1e-10,
    symmetry_tolerance = 1e-8
  )
}

drm_pair_sandwich_unavailable <- function(reason) {
  list(status = "unavailable", reason = reason)
}

drm_pair_sandwich_margin_blocks <- function(
  binary_y,
  nbinom2_y,
  p,
  mu,
  sigma,
  x_b,
  x_n,
  z_n
) {
  r <- sigma^(-2)
  score_b_scalar <- binary_y - p
  score_n_scalar <- r * (nbinom2_y - mu) / (r + mu)
  d <- digamma(nbinom2_y + r) -
    digamma(r) +
    log(r) +
    1 -
    log(r + mu) -
    (r + nbinom2_y) / (r + mu)
  score_s_scalar <- -2 * r * d
  d_dr <- trigamma(nbinom2_y + r) -
    trigamma(r) +
    1 / r -
    1 / (r + mu) +
    (nbinom2_y - mu) / (r + mu)^2
  h_nn <- r * mu * (r + nbinom2_y) / (r + mu)^2
  h_ns <- 2 * r * mu * (nbinom2_y - mu) / (r + mu)^2
  h_ss <- -4 * r * d - 4 * r^2 * d_dr
  list(
    score_b = x_b * score_b_scalar,
    score_n = x_n * score_n_scalar,
    score_s = z_n * score_s_scalar,
    bread_b = crossprod(x_b, x_b * (p * (1 - p))) / length(p),
    bread_nn = crossprod(x_n, x_n * h_nn) / length(p),
    bread_ns = crossprod(x_n, z_n * h_ns) / length(p),
    bread_ss = crossprod(z_n, z_n * h_ss) / length(p)
  )
}

drm_pair_sandwich_association_blocks <- function(
  binary_y,
  nbinom2_y,
  lambda_b,
  xi_n,
  tau_n,
  a,
  x_b,
  x_n,
  z_n,
  x_a,
  control
) {
  n <- length(a)
  p_b <- ncol(x_b)
  p_n <- ncol(x_n)
  p_s <- ncol(z_n)
  p_a <- ncol(x_a)
  score_a <- matrix(NA_real_, n, p_a)
  bread_ab <- matrix(0, p_a, p_b)
  bread_an <- matrix(0, p_a, p_n)
  bread_as <- matrix(0, p_a, p_s)
  bread_aa <- matrix(0, p_a, p_a)
  diagnostics <- vector("list", n)
  for (i in seq_len(n)) {
    fn <- function(q) {
      drm_pair_sandwich_row_logprob(
        binary_y[[i]],
        nbinom2_y[[i]],
        q[[2L]],
        q[[3L]],
        q[[4L]],
        q[[1L]]
      )
    }
    q <- c(a[[i]], lambda_b[[i]], xi_n[[i]], tau_n[[i]])
    derivative <- drm_pair_sandwich_stable_derivatives(fn, q, control)
    if (!identical(derivative$status, "ok")) {
      return(drm_pair_sandwich_unavailable(paste0(
        "association_",
        derivative$reason
      )))
    }
    gradient <- derivative$gradient
    hessian <- derivative$hessian
    score_a[i, ] <- x_a[i, ] * gradient[[1L]]
    bread_ab <- bread_ab - tcrossprod(x_a[i, ], x_b[i, ]) * hessian[1L, 2L] / n
    bread_an <- bread_an - tcrossprod(x_a[i, ], x_n[i, ]) * hessian[1L, 3L] / n
    bread_as <- bread_as - tcrossprod(x_a[i, ], z_n[i, ]) * hessian[1L, 4L] / n
    bread_aa <- bread_aa - tcrossprod(x_a[i, ]) * hessian[1L, 1L] / n
    diagnostics[[i]] <- derivative$diagnostics
  }
  list(
    status = "ok",
    score_a = score_a,
    bread_ab = bread_ab,
    bread_an = bread_an,
    bread_as = bread_as,
    bread_aa = bread_aa,
    derivative_diagnostics = diagnostics
  )
}

drm_pair_sandwich_row_logprob <- function(
  binary_y,
  nbinom2_y,
  lambda_b,
  xi_n,
  tau_n,
  a
) {
  result <- drm_pair_bernoulli_nbinom2_rectangle_probability(
    binary_y = binary_y,
    binary_p = stats::plogis(lambda_b),
    nbinom2_y = nbinom2_y,
    nbinom2_mu = exp(xi_n),
    nbinom2_sigma = exp(tau_n),
    eta = 0.999999 * tanh(a)
  )
  if (!identical(result$status, "ok")) {
    return(NA_real_)
  }
  result$log_probability
}

drm_pair_sandwich_stable_derivatives <- function(fn, q, control) {
  first <- drm_pair_sandwich_derivatives(fn, q, control$step)
  second <- drm_pair_sandwich_derivatives(fn, q, control$step / 2)
  if (
    any(!is.finite(first$gradient)) ||
      any(!is.finite(first$hessian)) ||
      any(!is.finite(second$gradient)) ||
      any(!is.finite(second$hessian))
  ) {
    return(list(status = "unavailable", reason = "nonfinite_derivative"))
  }
  difference <- max(abs(c(
    first$gradient - second$gradient,
    first$hessian - second$hessian
  )))
  scale <- max(
    1,
    abs(c(first$gradient, first$hessian, second$gradient, second$hessian))
  )
  if (
    difference >
      control$derivative_absolute_tolerance +
        control$derivative_relative_tolerance * scale
  ) {
    return(list(status = "unavailable", reason = "step_unstable"))
  }
  list(
    status = "ok",
    gradient = second$gradient,
    hessian = second$hessian,
    diagnostics = list(max_step_difference = difference, scale = scale)
  )
}

drm_pair_sandwich_derivatives <- function(fn, q, h) {
  p <- length(q)
  gradient <- numeric(p)
  for (j in seq_len(p)) {
    e <- rep(0, p)
    e[[j]] <- h
    gradient[[j]] <- (-fn(q + 2 * e) +
      8 * fn(q + e) -
      8 * fn(q - e) +
      fn(q - 2 * e)) /
      (12 * h)
  }
  hessian <- matrix(NA_real_, p, p)
  for (j in seq_len(p)) {
    e <- rep(0, p)
    e[[j]] <- h
    g_plus2 <- drm_pair_sandwich_gradient(fn, q + 2 * e, h)
    g_plus <- drm_pair_sandwich_gradient(fn, q + e, h)
    g_minus <- drm_pair_sandwich_gradient(fn, q - e, h)
    g_minus2 <- drm_pair_sandwich_gradient(fn, q - 2 * e, h)
    hessian[, j] <- (-g_plus2 + 8 * g_plus - 8 * g_minus + g_minus2) / (12 * h)
  }
  list(gradient = gradient, hessian = (hessian + t(hessian)) / 2)
}

drm_pair_sandwich_gradient <- function(fn, q, h) {
  p <- length(q)
  out <- numeric(p)
  for (j in seq_len(p)) {
    e <- rep(0, p)
    e[[j]] <- h
    out[[j]] <- (-fn(q + 2 * e) +
      8 * fn(q + e) -
      8 * fn(q - e) +
      fn(q - 2 * e)) /
      (12 * h)
  }
  out
}
