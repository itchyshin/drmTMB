# Developer-only candidate sandwich variance for the staged Gaussian x
# ordinary-NB2 association estimator.  It deliberately has no public entry
# point: it is a numerical diagnostic, not user-facing inference.

drm_pair_gaussian_nbinom2_eta_sandwich <- function(
  fit_1,
  fit_2,
  association_fit,
  control = drm_pair_sandwich_control()
) {
  if (
    !inherits(association_fit, "drm_pair_association") ||
      !identical(association_fit$components$pair_class, "gaussian_nbinom2")
  ) {
    cli::cli_abort(
      "The staged sandwich is defined only for Gaussian x ordinary-NB2 association fits."
    )
  }
  if (!association_fit$status %in% c("interior", "near_boundary")) {
    return(drm_pair_sandwich_unavailable("association_unresolved"))
  }

  fits <- list(fit_1, fit_2)
  types <- vapply(fits, function(x) x$model$model_type, character(1L))
  if (!setequal(types, c("gaussian", "nbinom2"))) {
    cli::cli_abort(
      "The staged sandwich needs the original Gaussian and ordinary-NB2 margin fits."
    )
  }
  gaussian_fit <- fits[[which(types == "gaussian")]]
  nbinom2_fit <- fits[[which(types == "nbinom2")]]
  drm_pair_validate_fit(gaussian_fit, "Gaussian margin")
  drm_pair_validate_fit(nbinom2_fit, "NB2 margin")
  drm_pair_validate_shared_data(gaussian_fit, nbinom2_fit)
  drm_pair_validate_gaussian(gaussian_fit)
  drm_pair_validate_nbinom2(nbinom2_fit)

  provenance <- drm_pair_gaussian_nbinom2_sandwich_provenance(
    fit_1, fit_2, association_fit
  )
  if (!isTRUE(provenance)) {
    return(drm_pair_sandwich_unavailable("provenance_mismatch"))
  }

  x_g <- as.matrix(gaussian_fit$model$X$mu)
  z_g <- as.matrix(gaussian_fit$model$X$sigma)
  x_n <- as.matrix(nbinom2_fit$model$X$mu)
  z_n <- as.matrix(nbinom2_fit$model$X$sigma)
  x_a <- as.matrix(association_fit$association_design$matrix)
  n <- nrow(x_a)
  if (!all(c(nrow(x_g), nrow(z_g), nrow(x_n), nrow(z_n)) == n)) {
    return(drm_pair_sandwich_unavailable("design_row_mismatch"))
  }
  beta_g <- unname(gaussian_fit$coefficients$mu)
  gamma_g <- unname(gaussian_fit$coefficients$sigma)
  beta_n <- unname(nbinom2_fit$coefficients$mu)
  gamma_n <- unname(nbinom2_fit$coefficients$sigma)
  alpha <- unname(association_fit$association_coefficients)
  if (
    length(beta_g) != ncol(x_g) ||
      length(gamma_g) != ncol(z_g) ||
      length(beta_n) != ncol(x_n) ||
      length(gamma_n) != ncol(z_n) ||
      length(alpha) != ncol(x_a)
  ) {
    return(drm_pair_sandwich_unavailable("coefficient_design_mismatch"))
  }

  m <- as.vector(x_g %*% beta_g)
  tau_g <- as.vector(z_g %*% gamma_g)
  xi_n <- as.vector(x_n %*% beta_n)
  tau_n <- as.vector(z_n %*% gamma_n)
  a <- as.vector(x_a %*% alpha)
  sigma_g <- exp(tau_g)
  mu_n <- exp(xi_n)
  sigma_n <- exp(tau_n)
  components <- association_fit$components
  if (
    !isTRUE(all.equal(gaussian_fit$model$y, components$gaussian_y)) ||
      !isTRUE(all.equal(nbinom2_fit$model$y, components$nbinom2_y)) ||
      !isTRUE(all.equal(m, components$gaussian_mu, tolerance = 1e-8)) ||
      !isTRUE(all.equal(sigma_g, components$gaussian_sigma, tolerance = 1e-8)) ||
      !isTRUE(all.equal(mu_n, components$nbinom2_mu, tolerance = 1e-8)) ||
      !isTRUE(all.equal(sigma_n, components$nbinom2_sigma, tolerance = 1e-8))
  ) {
    return(drm_pair_sandwich_unavailable("frozen_margin_mismatch"))
  }
  if (any(a <= -8 + 0.01 | a >= 8 - 0.01)) {
    return(drm_pair_sandwich_unavailable("association_boundary"))
  }

  marginal <- drm_pair_gaussian_nbinom2_sandwich_margin_blocks(
    gaussian_y = components$gaussian_y,
    nbinom2_y = components$nbinom2_y,
    gaussian_mu = m,
    gaussian_sigma = sigma_g,
    nbinom2_mu = mu_n,
    nbinom2_sigma = sigma_n,
    x_g = x_g,
    z_g = z_g,
    x_n = x_n,
    z_n = z_n
  )
  association <- drm_pair_gaussian_nbinom2_sandwich_association_blocks(
    gaussian_y = components$gaussian_y,
    nbinom2_y = components$nbinom2_y,
    m = m,
    tau_g = tau_g,
    xi_n = xi_n,
    tau_n = tau_n,
    a = a,
    x_g = x_g,
    z_g = z_g,
    x_n = x_n,
    z_n = z_n,
    x_a = x_a,
    control = control
  )
  if (!identical(association$status, "ok")) {
    return(association)
  }

  gaussian_score <- cbind(marginal$score_g_mu, marginal$score_g_sigma)
  nbinom2_score <- cbind(marginal$score_n_mu, marginal$score_n_sigma)
  colnames(gaussian_score) <- c(
    paste0("gaussian_mu:", colnames(x_g)),
    paste0("gaussian_sigma:", colnames(z_g))
  )
  colnames(nbinom2_score) <- c(
    paste0("nbinom2_mu:", colnames(x_n)),
    paste0("nbinom2_sigma:", colnames(z_n))
  )
  colnames(association$score_a) <- paste0("association:", colnames(x_a))
  assembled <- drm_pair_sandwich_assemble(
    margin_scores = list(gaussian_score, nbinom2_score),
    margin_bread = list(
      rbind(
        cbind(marginal$bread_g_mm, marginal$bread_g_ms),
        cbind(t(marginal$bread_g_ms), marginal$bread_g_ss)
      ),
      rbind(
        cbind(marginal$bread_n_mm, marginal$bread_n_ms),
        cbind(t(marginal$bread_n_ms), marginal$bread_n_ss)
      )
    ),
    association_score = association$score_a,
    association_bread = list(
      cbind(association$bread_ag_m, association$bread_ag_s),
      cbind(association$bread_an_m, association$bread_an_s),
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

# Reject association objects whose rows, frozen margins, response roles, or
# association design have been edited since the two stage-one fits were made.
drm_pair_gaussian_nbinom2_sandwich_provenance <- function(
  fit_1,
  fit_2,
  association_fit
) {
  expected_design <- tryCatch(
    drm_pair_association_design(
      association_fit$association, fit_1$data, "gaussian_nbinom2"
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
      "nbinom2"
    },
    fit_2 = if (identical(fit_2$model$model_type, "gaussian")) {
      "gaussian"
    } else {
      "nbinom2"
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

# Analytic marginal scores and observed negative Hessian for the canonical
# (Gaussian mu, Gaussian log-sigma, NB2 log-mu, NB2 log-sigma) margin blocks.
drm_pair_gaussian_nbinom2_sandwich_margin_blocks <- function(
  gaussian_y,
  nbinom2_y,
  gaussian_mu,
  gaussian_sigma,
  nbinom2_mu,
  nbinom2_sigma,
  x_g,
  z_g,
  x_n,
  z_n
) {
  n <- length(nbinom2_y)
  residual <- gaussian_y - gaussian_mu
  sigma2_g <- gaussian_sigma^2
  standardized_g <- residual / gaussian_sigma
  r <- nbinom2_sigma^(-2)
  d <- digamma(nbinom2_y + r) -
    digamma(r) +
    log(r) + 1 -
    log(r + nbinom2_mu) -
    (r + nbinom2_y) / (r + nbinom2_mu)
  d_dr <- trigamma(nbinom2_y + r) -
    trigamma(r) +
    1 / r -
    1 / (r + nbinom2_mu) +
    (nbinom2_y - nbinom2_mu) / (r + nbinom2_mu)^2
  score_n_mu_scalar <- r * (nbinom2_y - nbinom2_mu) / (r + nbinom2_mu)
  score_n_sigma_scalar <- -2 * r * d
  h_n_mm <- r * nbinom2_mu * (r + nbinom2_y) / (r + nbinom2_mu)^2
  h_n_ms <- 2 * r * nbinom2_mu * (nbinom2_y - nbinom2_mu) / (r + nbinom2_mu)^2
  h_n_ss <- -4 * r * d - 4 * r^2 * d_dr
  list(
    score_g_mu = x_g * (residual / sigma2_g),
    score_g_sigma = z_g * (standardized_g^2 - 1),
    score_n_mu = x_n * score_n_mu_scalar,
    score_n_sigma = z_n * score_n_sigma_scalar,
    bread_g_mm = crossprod(x_g, x_g / sigma2_g) / n,
    bread_g_ms = crossprod(x_g, z_g * (2 * residual / sigma2_g)) / n,
    bread_g_ss = crossprod(z_g, z_g * (2 * standardized_g^2)) / n,
    bread_n_mm = crossprod(x_n, x_n * h_n_mm) / n,
    bread_n_ms = crossprod(x_n, z_n * h_n_ms) / n,
    bread_n_ss = crossprod(z_n, z_n * h_n_ss) / n
  )
}

# Association derivative coordinates are (a, Gaussian mu, Gaussian log-sigma,
# NB2 log-mu, NB2 log-sigma).  The private adapter maps them back to the
# canonical parameter block order before calling the shared assembler.
drm_pair_gaussian_nbinom2_sandwich_association_blocks <- function(
  gaussian_y,
  nbinom2_y,
  m,
  tau_g,
  xi_n,
  tau_n,
  a,
  x_g,
  z_g,
  x_n,
  z_n,
  x_a,
  control
) {
  n <- length(a)
  p_g <- ncol(x_g)
  p_sg <- ncol(z_g)
  p_n <- ncol(x_n)
  p_sn <- ncol(z_n)
  p_a <- ncol(x_a)
  score_a <- matrix(NA_real_, n, p_a)
  bread_ag_m <- matrix(0, p_a, p_g)
  bread_ag_s <- matrix(0, p_a, p_sg)
  bread_an_m <- matrix(0, p_a, p_n)
  bread_an_s <- matrix(0, p_a, p_sn)
  bread_aa <- matrix(0, p_a, p_a)
  diagnostics <- vector("list", n)
  for (i in seq_len(n)) {
    fn <- function(q) {
      drm_pair_gaussian_nbinom2_sandwich_row_logprob(
        gaussian_y = gaussian_y[[i]],
        nbinom2_y = nbinom2_y[[i]],
        m = q[[2L]],
        tau_g = q[[3L]],
        xi_n = q[[4L]],
        tau_n = q[[5L]],
        a = q[[1L]]
      )
    }
    q <- c(a[[i]], m[[i]], tau_g[[i]], xi_n[[i]], tau_n[[i]])
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
    bread_an_m <- bread_an_m -
      tcrossprod(x_a[i, ], x_n[i, ]) * hessian[1L, 4L] / n
    bread_an_s <- bread_an_s -
      tcrossprod(x_a[i, ], z_n[i, ]) * hessian[1L, 5L] / n
    bread_aa <- bread_aa - tcrossprod(x_a[i, ]) * hessian[1L, 1L] / n
    diagnostics[[i]] <- derivative$diagnostics
  }
  list(
    status = "ok",
    score_a = score_a,
    bread_ag_m = bread_ag_m,
    bread_ag_s = bread_ag_s,
    bread_an_m = bread_an_m,
    bread_an_s = bread_an_s,
    bread_aa = bread_aa,
    derivative_diagnostics = diagnostics
  )
}

# Delegate the paired-row kernel to the admitted Gaussian x ordinary-NB2
# likelihood so the private derivative calculation cannot adopt a different
# tail/interval convention.
drm_pair_gaussian_nbinom2_sandwich_row_logprob <- function(
  gaussian_y,
  nbinom2_y,
  m,
  tau_g,
  xi_n,
  tau_n,
  a
) {
  value <- drm_pair_gaussian_nbinom2_loglik(
    a,
    list(
      gaussian_y = gaussian_y,
      nbinom2_y = nbinom2_y,
      gaussian_mu = m,
      gaussian_sigma = exp(tau_g),
      nbinom2_mu = exp(xi_n),
      nbinom2_sigma = exp(tau_n)
    )
  )
  if (is.finite(value)) value else NA_real_
}
