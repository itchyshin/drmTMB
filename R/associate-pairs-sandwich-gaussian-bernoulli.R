# Developer-only candidate sandwich variance for the staged Gaussian x literal
# Bernoulli association estimator.  This remains deliberately unreachable from
# the public association object: it is a numerical diagnostic, not inference.

drm_pair_gaussian_bernoulli_eta_sandwich <- function(
  fit_1,
  fit_2,
  association_fit,
  control = drm_pair_sandwich_control()
) {
  if (
    !inherits(association_fit, "drm_pair_association") ||
      !identical(association_fit$components$pair_class, "gaussian_bernoulli")
  ) {
    cli::cli_abort(
      "The staged sandwich is defined only for Gaussian x literal-Bernoulli association fits."
    )
  }
  if (!association_fit$status %in% c("interior", "near_boundary")) {
    return(drm_pair_sandwich_unavailable("association_unresolved"))
  }

  fits <- list(fit_1, fit_2)
  types <- vapply(fits, function(x) x$model$model_type, character(1L))
  if (!setequal(types, c("gaussian", "binomial"))) {
    cli::cli_abort(
      "The staged sandwich needs the original Gaussian and literal-Bernoulli margin fits."
    )
  }
  gaussian_fit <- fits[[which(types == "gaussian")]]
  binary_fit <- fits[[which(types == "binomial")]]
  drm_pair_validate_fit(gaussian_fit, "Gaussian margin")
  drm_pair_validate_fit(binary_fit, "Bernoulli margin")
  drm_pair_validate_shared_data(gaussian_fit, binary_fit)
  drm_pair_validate_gaussian(gaussian_fit)
  drm_pair_validate_bernoulli(binary_fit)

  provenance <- drm_pair_gaussian_bernoulli_sandwich_provenance(
    fit_1, fit_2, association_fit
  )
  if (!isTRUE(provenance)) {
    return(drm_pair_sandwich_unavailable("provenance_mismatch"))
  }

  x_g <- as.matrix(gaussian_fit$model$X$mu)
  z_g <- as.matrix(gaussian_fit$model$X$sigma)
  x_b <- as.matrix(binary_fit$model$X$mu)
  x_a <- as.matrix(association_fit$association_design$matrix)
  n <- nrow(x_a)
  if (!all(c(nrow(x_g), nrow(z_g), nrow(x_b)) == n)) {
    return(drm_pair_sandwich_unavailable("design_row_mismatch"))
  }
  beta_g <- unname(gaussian_fit$coefficients$mu)
  gamma_g <- unname(gaussian_fit$coefficients$sigma)
  beta_b <- unname(binary_fit$coefficients$mu)
  alpha <- unname(association_fit$association_coefficients)
  if (
    length(beta_g) != ncol(x_g) ||
      length(gamma_g) != ncol(z_g) ||
      length(beta_b) != ncol(x_b) ||
      length(alpha) != ncol(x_a)
  ) {
    return(drm_pair_sandwich_unavailable("coefficient_design_mismatch"))
  }

  m <- as.vector(x_g %*% beta_g)
  tau <- as.vector(z_g %*% gamma_g)
  lambda <- as.vector(x_b %*% beta_b)
  a <- as.vector(x_a %*% alpha)
  sigma <- exp(tau)
  p <- stats::plogis(lambda)
  components <- association_fit$components
  if (
    !isTRUE(all.equal(gaussian_fit$model$y, components$gaussian_y)) ||
      !isTRUE(all.equal(binary_fit$model$y, components$binary_y)) ||
      !isTRUE(all.equal(m, components$gaussian_mu, tolerance = 1e-8)) ||
      !isTRUE(all.equal(sigma, components$gaussian_sigma, tolerance = 1e-8)) ||
      !isTRUE(all.equal(p, components$binary_p, tolerance = 1e-8))
  ) {
    return(drm_pair_sandwich_unavailable("frozen_margin_mismatch"))
  }
  if (any(a <= -8 + 0.01 | a >= 8 - 0.01)) {
    return(drm_pair_sandwich_unavailable("association_boundary"))
  }

  marginal <- drm_pair_gaussian_bernoulli_sandwich_margin_blocks(
    gaussian_y = components$gaussian_y,
    binary_y = components$binary_y,
    gaussian_mu = m,
    gaussian_sigma = sigma,
    binary_p = p,
    x_g = x_g,
    z_g = z_g,
    x_b = x_b
  )
  association <- drm_pair_gaussian_bernoulli_sandwich_association_blocks(
    gaussian_y = components$gaussian_y,
    binary_y = components$binary_y,
    m = m,
    tau = tau,
    lambda = lambda,
    a = a,
    x_g = x_g,
    z_g = z_g,
    x_b = x_b,
    x_a = x_a,
    control = control
  )
  if (!identical(association$status, "ok")) {
    return(association)
  }

  gaussian_score <- cbind(marginal$score_g_mu, marginal$score_g_sigma)
  colnames(gaussian_score) <- c(
    paste0("gaussian_mu:", colnames(x_g)),
    paste0("gaussian_sigma:", colnames(z_g))
  )
  colnames(marginal$score_b) <- paste0("bernoulli_mu:", colnames(x_b))
  colnames(association$score_a) <- paste0("association:", colnames(x_a))
  assembled <- drm_pair_sandwich_assemble(
    margin_scores = list(gaussian_score, marginal$score_b),
    margin_bread = list(
      rbind(
        cbind(marginal$bread_g_mm, marginal$bread_g_ms),
        cbind(t(marginal$bread_g_ms), marginal$bread_g_ss)
      ),
      marginal$bread_b
    ),
    association_score = association$score_a,
    association_bread = list(
      cbind(association$bread_ag_m, association$bread_ag_s),
      association$bread_ab,
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

# Check that the private calculation still refers to exactly the two frozen
# margin fits and their original association design.  These checks return an
# unavailable diagnostic rather than accepting a stale or edited association
# object as if it were a current stage-one result.
drm_pair_gaussian_bernoulli_sandwich_provenance <- function(
  fit_1,
  fit_2,
  association_fit
) {
  expected_design <- tryCatch(
    drm_pair_association_design(
      association_fit$association, fit_1$data, "gaussian_bernoulli"
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
  expected_roles <- c(
    fit_1 = if (identical(fit_1$model$model_type, "gaussian")) {
      "gaussian"
    } else {
      "bernoulli"
    },
    fit_2 = if (identical(fit_2$model$model_type, "gaussian")) {
      "gaussian"
    } else {
      "bernoulli"
    }
  )
  !is.null(expected_design) &&
    isTRUE(all.equal(
      association_fit$provenance$data_hash,
      drm_pair_fingerprint(fit_1$data)
    )) &&
    isTRUE(all.equal(
      association_fit$provenance$original_row,
      drm_pair_analysis_rows(fit_1)
    )) &&
    identical(association_fit$provenance$fit_hashes, expected_hashes) &&
    identical(association_fit$response_names, expected_names) &&
    identical(association_fit$margin_order, expected_roles) &&
    isTRUE(all.equal(
      association_fit$association_design$matrix, expected_design$matrix,
      tolerance = 0
    )) &&
    identical(
      colnames(association_fit$association_design$matrix),
      colnames(expected_design$matrix)
    ) &&
    identical(association_fit$association_design$varying, expected_design$varying) &&
    identical(association_fit$association_design$terms, expected_design$terms)
}

# Analytic marginal scores and observed negative Hessian for Gaussian
# (identity mu, log sigma) plus the canonical Bernoulli/logit block.
drm_pair_gaussian_bernoulli_sandwich_margin_blocks <- function(
  gaussian_y,
  binary_y,
  gaussian_mu,
  gaussian_sigma,
  binary_p,
  x_g,
  z_g,
  x_b
) {
  residual <- gaussian_y - gaussian_mu
  sigma2 <- gaussian_sigma^2
  z <- residual / gaussian_sigma
  score_g_mu_scalar <- residual / sigma2
  score_g_sigma_scalar <- z^2 - 1
  h_g_mm <- 1 / sigma2
  h_g_ms <- 2 * residual / sigma2
  h_g_ss <- 2 * z^2
  list(
    score_g_mu = x_g * score_g_mu_scalar,
    score_g_sigma = z_g * score_g_sigma_scalar,
    score_b = x_b * (binary_y - binary_p),
    bread_g_mm = crossprod(x_g, x_g * h_g_mm) / length(binary_p),
    bread_g_ms = crossprod(x_g, z_g * h_g_ms) / length(binary_p),
    bread_g_ss = crossprod(z_g, z_g * h_g_ss) / length(binary_p),
    bread_b = crossprod(x_b, x_b * (binary_p * (1 - binary_p))) /
      length(binary_p)
  )
}

# The derivative coordinates are (a, m, tau, lambda).  This keeps the common
# five-point service association-first while the adapter maps derivatives back
# to canonical output blocks (Gmu, Gsigma, B, alpha).
drm_pair_gaussian_bernoulli_sandwich_association_blocks <- function(
  gaussian_y,
  binary_y,
  m,
  tau,
  lambda,
  a,
  x_g,
  z_g,
  x_b,
  x_a,
  control
) {
  n <- length(a)
  p_g <- ncol(x_g)
  p_s <- ncol(z_g)
  p_b <- ncol(x_b)
  p_a <- ncol(x_a)
  score_a <- matrix(NA_real_, n, p_a)
  bread_ag_m <- matrix(0, p_a, p_g)
  bread_ag_s <- matrix(0, p_a, p_s)
  bread_ab <- matrix(0, p_a, p_b)
  bread_aa <- matrix(0, p_a, p_a)
  diagnostics <- vector("list", n)
  for (i in seq_len(n)) {
    fn <- function(q) {
      drm_pair_gaussian_bernoulli_sandwich_row_logprob(
        gaussian_y = gaussian_y[[i]],
        binary_y = binary_y[[i]],
        m = q[[2L]],
        tau = q[[3L]],
        lambda = q[[4L]],
        a = q[[1L]]
      )
    }
    q <- c(a[[i]], m[[i]], tau[[i]], lambda[[i]])
    derivative <- drm_pair_sandwich_stable_derivatives(fn, q, control)
    if (!identical(derivative$status, "ok")) {
      return(drm_pair_sandwich_unavailable(paste0(
        "association_", derivative$reason
      )))
    }
    gradient <- derivative$gradient
    hessian <- derivative$hessian
    score_a[i, ] <- x_a[i, ] * gradient[[1L]]
    bread_ag_m <- bread_ag_m -
      tcrossprod(x_a[i, ], x_g[i, ]) * hessian[1L, 2L] / n
    bread_ag_s <- bread_ag_s -
      tcrossprod(x_a[i, ], z_g[i, ]) * hessian[1L, 3L] / n
    bread_ab <- bread_ab -
      tcrossprod(x_a[i, ], x_b[i, ]) * hessian[1L, 4L] / n
    bread_aa <- bread_aa - tcrossprod(x_a[i, ]) * hessian[1L, 1L] / n
    diagnostics[[i]] <- derivative$diagnostics
  }
  list(
    status = "ok",
    score_a = score_a,
    bread_ag_m = bread_ag_m,
    bread_ag_s = bread_ag_s,
    bread_ab = bread_ab,
    bread_aa = bread_aa,
    derivative_diagnostics = diagnostics
  )
}

# Deliberately delegate to the admitted Gaussian x Bernoulli likelihood so the
# private adapter cannot drift to a subtly different threshold convention.
drm_pair_gaussian_bernoulli_sandwich_row_logprob <- function(
  gaussian_y,
  binary_y,
  m,
  tau,
  lambda,
  a
) {
  value <- drm_pair_gaussian_bernoulli_loglik(
    a,
    list(
      gaussian_y = gaussian_y,
      binary_y = binary_y,
      gaussian_mu = m,
      gaussian_sigma = exp(tau),
      binary_p = stats::plogis(lambda)
    )
  )
  if (is.finite(value)) value else NA_real_
}
