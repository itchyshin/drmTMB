# Developer-only candidate sandwich variance for literal ordinary-NB2 x
# ordinary-NB2 frozen-margin association fits.  Repeated families retain
# caller order: L = fit_1 and R = fit_2.  This is intentionally not a public
# uncertainty API.

drm_pair_nbinom2_nbinom2_sandwich <- function(
  fit_1,
  fit_2,
  association_fit,
  control = drm_pair_sandwich_control()
) {
  if (
    !inherits(association_fit, "drm_pair_association") ||
      !identical(association_fit$components$pair_class, "nbinom2_nbinom2")
  ) {
    cli::cli_abort(
      "The staged sandwich is defined only for literal ordinary-NB2 x ordinary-NB2 association fits."
    )
  }
  if (!association_fit$status %in% c("interior", "near_boundary")) {
    return(drm_pair_sandwich_unavailable("association_unresolved"))
  }

  # Do not infer repeated-family sides from a set: fit_1 is L and fit_2 is R.
  drm_pair_validate_fit(fit_1, "left ordinary-NB2 margin")
  drm_pair_validate_fit(fit_2, "right ordinary-NB2 margin")
  drm_pair_validate_shared_data(fit_1, fit_2)
  drm_pair_validate_nbinom2(fit_1)
  drm_pair_validate_nbinom2(fit_2)

  x_l <- as.matrix(fit_1$model$X$mu)
  z_l <- as.matrix(fit_1$model$X$sigma)
  x_r <- as.matrix(fit_2$model$X$mu)
  z_r <- as.matrix(fit_2$model$X$sigma)
  x_a <- as.matrix(association_fit$association_design$matrix)
  n <- nrow(x_a)
  if (!all(c(nrow(x_l), nrow(z_l), nrow(x_r), nrow(z_r)) == n)) {
    return(drm_pair_sandwich_unavailable("design_row_mismatch"))
  }
  beta_l <- unname(fit_1$coefficients$mu)
  gamma_l <- unname(fit_1$coefficients$sigma)
  beta_r <- unname(fit_2$coefficients$mu)
  gamma_r <- unname(fit_2$coefficients$sigma)
  alpha <- unname(association_fit$association_coefficients)
  if (
    length(beta_l) != ncol(x_l) ||
      length(gamma_l) != ncol(z_l) ||
      length(beta_r) != ncol(x_r) ||
      length(gamma_r) != ncol(z_r) ||
      length(alpha) != ncol(x_a)
  ) {
    return(drm_pair_sandwich_unavailable("coefficient_design_mismatch"))
  }

  xi_l <- as.vector(x_l %*% beta_l)
  tau_l <- as.vector(z_l %*% gamma_l)
  xi_r <- as.vector(x_r %*% beta_r)
  tau_r <- as.vector(z_r %*% gamma_r)
  a <- as.vector(x_a %*% alpha)
  mu_l <- exp(xi_l)
  sigma_l <- exp(tau_l)
  mu_r <- exp(xi_r)
  sigma_r <- exp(tau_r)
  if (!drm_pair_nbinom2_nbinom2_sandwich_frozen_matches(
    fit_1 = fit_1,
    fit_2 = fit_2,
    association_fit = association_fit,
    mu_l = mu_l,
    sigma_l = sigma_l,
    mu_r = mu_r,
    sigma_r = sigma_r,
    x_a = x_a
  )) {
    return(drm_pair_sandwich_unavailable("frozen_margin_mismatch"))
  }
  if (any(a <= -8 + 0.01 | a >= 8 - 0.01)) {
    return(drm_pair_sandwich_unavailable("association_boundary"))
  }

  components <- association_fit$components
  marginal_l <- drm_pair_nbinom2_nbinom2_sandwich_margin_block(
    y = components$nbinom2_y_1,
    mu = mu_l,
    sigma = sigma_l,
    x = x_l,
    z = z_l
  )
  marginal_r <- drm_pair_nbinom2_nbinom2_sandwich_margin_block(
    y = components$nbinom2_y_2,
    mu = mu_r,
    sigma = sigma_r,
    x = x_r,
    z = z_r
  )
  association <- drm_pair_nbinom2_nbinom2_sandwich_association_blocks(
    y_l = components$nbinom2_y_1,
    y_r = components$nbinom2_y_2,
    xi_l = xi_l,
    tau_l = tau_l,
    xi_r = xi_r,
    tau_r = tau_r,
    a = a,
    x_l = x_l,
    z_l = z_l,
    x_r = x_r,
    z_r = z_r,
    x_a = x_a,
    control = control
  )
  if (!identical(association$status, "ok")) {
    return(association)
  }

  score_l <- cbind(marginal_l$score_mu, marginal_l$score_sigma)
  score_r <- cbind(marginal_r$score_mu, marginal_r$score_sigma)
  colnames(score_l) <- c(
    paste0("nbinom2_L_mu:", colnames(x_l)),
    paste0("nbinom2_L_sigma:", colnames(z_l))
  )
  colnames(score_r) <- c(
    paste0("nbinom2_R_mu:", colnames(x_r)),
    paste0("nbinom2_R_sigma:", colnames(z_r))
  )
  colnames(association$score_a) <- paste0("association:", colnames(x_a))
  assembled <- drm_pair_sandwich_assemble(
    margin_scores = list(score_l, score_r),
    margin_bread = list(
      drm_pair_nbinom2_nbinom2_sandwich_bread(marginal_l),
      drm_pair_nbinom2_nbinom2_sandwich_bread(marginal_r)
    ),
    association_score = association$score_a,
    association_bread = list(
      cbind(association$bread_al_mu, association$bread_al_sigma),
      cbind(association$bread_ar_mu, association$bread_ar_sigma),
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

drm_pair_nbinom2_nbinom2_sandwich_frozen_matches <- function(
  fit_1,
  fit_2,
  association_fit,
  mu_l,
  sigma_l,
  mu_r,
  sigma_r,
  x_a
) {
  components <- association_fit$components
  margins <- association_fit$margins
  provenance <- association_fit$provenance
  expected_design <- tryCatch(
    drm_pair_association_design(
      association_fit$association, fit_1$data, "nbinom2_nbinom2"
    )$matrix,
    error = function(e) NULL
  )
  same <- function(x, y) isTRUE(all.equal(x, y, tolerance = 1e-8))
  identical(association_fit$margin_order,
    c(fit_1 = "nbinom2_1", fit_2 = "nbinom2_2")
  ) &&
    identical(association_fit$response_names, c(
      fit_1 = drm_pair_response_name(fit_1),
      fit_2 = drm_pair_response_name(fit_2)
    )) &&
    identical(components$nbinom2_y_1, fit_1$model$y) &&
    identical(components$nbinom2_y_2, fit_2$model$y) &&
    same(components$nbinom2_mu_1, mu_l) &&
    same(components$nbinom2_sigma_1, sigma_l) &&
    same(components$nbinom2_mu_2, mu_r) &&
    same(components$nbinom2_sigma_2, sigma_r) &&
    identical(margins$fit_1$response, fit_1$model$y) &&
    identical(margins$fit_2$response, fit_2$model$y) &&
    same(margins$fit_1$fitted$mu, mu_l) &&
    same(margins$fit_1$fitted$sigma, sigma_l) &&
    same(margins$fit_2$fitted$mu, mu_r) &&
    same(margins$fit_2$fitted$sigma, sigma_r) &&
    identical(margins$fit_1$response_name, drm_pair_response_name(fit_1)) &&
    identical(margins$fit_2$response_name, drm_pair_response_name(fit_2)) &&
    identical(margins$fit_1$original_row, drm_pair_analysis_rows(fit_1)) &&
    identical(margins$fit_2$original_row, drm_pair_analysis_rows(fit_2)) &&
    identical(margins$fit_1$data_hash, drm_pair_fingerprint(fit_1$data)) &&
    identical(margins$fit_2$data_hash, drm_pair_fingerprint(fit_2$data)) &&
    identical(provenance$row_id, seq_len(nrow(fit_1$data))) &&
    identical(provenance$original_row, drm_pair_analysis_rows(fit_1)) &&
    identical(provenance$data_hash, drm_pair_fingerprint(fit_1$data)) &&
    identical(provenance$fit_hashes, c(
      fit_1 = drm_pair_fingerprint(margins$fit_1),
      fit_2 = drm_pair_fingerprint(margins$fit_2)
    )) &&
    !is.null(expected_design) &&
    identical(colnames(x_a), colnames(expected_design)) &&
    same(x_a, expected_design)
}

# Ordinary-NB2 margin scores and observed negative Hessian in the local
# coordinates xi = log(mu), tau = log(sigma).  This deliberately stays local
# to the repeated-NB2 adapter until the private engine's fixture is frozen.
drm_pair_nbinom2_nbinom2_sandwich_margin_block <- function(y, mu, sigma, x, z) {
  y <- as.vector(y)
  mu <- as.vector(mu)
  sigma <- as.vector(sigma)
  r <- sigma^(-2)
  score_mu_scalar <- r * (y - mu) / (r + mu)
  d <- digamma(y + r) - digamma(r) + log(r) + 1 - log(r + mu) -
    (r + y) / (r + mu)
  score_sigma_scalar <- -2 * r * d
  d_dr <- trigamma(y + r) - trigamma(r) + 1 / r - 1 / (r + mu) +
    (y - mu) / (r + mu)^2
  h_mu_mu <- r * mu * (r + y) / (r + mu)^2
  h_mu_sigma <- 2 * r * mu * (y - mu) / (r + mu)^2
  h_sigma_sigma <- -4 * r * d - 4 * r^2 * d_dr
  n <- length(y)
  list(
    score_mu = x * score_mu_scalar,
    score_sigma = z * score_sigma_scalar,
    bread_mu_mu = crossprod(x, x * h_mu_mu) / n,
    bread_mu_sigma = crossprod(x, z * h_mu_sigma) / n,
    bread_sigma_sigma = crossprod(z, z * h_sigma_sigma) / n
  )
}

drm_pair_nbinom2_nbinom2_sandwich_bread <- function(block) {
  rbind(
    cbind(block$bread_mu_mu, block$bread_mu_sigma),
    cbind(t(block$bread_mu_sigma), block$bread_sigma_sigma)
  )
}

# The derivative coordinates are (a, xi_L, tau_L, xi_R, tau_R), with the
# association coordinate first.  The stable common finite-difference service
# maps its mixed curvature into the literal L/R margin blocks below.
drm_pair_nbinom2_nbinom2_sandwich_association_blocks <- function(
  y_l,
  y_r,
  xi_l,
  tau_l,
  xi_r,
  tau_r,
  a,
  x_l,
  z_l,
  x_r,
  z_r,
  x_a,
  control
) {
  n <- length(a)
  score_a <- matrix(NA_real_, n, ncol(x_a))
  bread_al_mu <- matrix(0, ncol(x_a), ncol(x_l))
  bread_al_sigma <- matrix(0, ncol(x_a), ncol(z_l))
  bread_ar_mu <- matrix(0, ncol(x_a), ncol(x_r))
  bread_ar_sigma <- matrix(0, ncol(x_a), ncol(z_r))
  bread_aa <- matrix(0, ncol(x_a), ncol(x_a))
  diagnostics <- vector("list", n)
  for (i in seq_len(n)) {
    fn <- function(q) {
      drm_pair_nbinom2_nbinom2_sandwich_row_logprob(
        y_l = y_l[[i]],
        y_r = y_r[[i]],
        xi_l = q[[2L]],
        tau_l = q[[3L]],
        xi_r = q[[4L]],
        tau_r = q[[5L]],
        a = q[[1L]]
      )
    }
    derivative <- drm_pair_sandwich_stable_derivatives(
      fn, c(a[[i]], xi_l[[i]], tau_l[[i]], xi_r[[i]], tau_r[[i]]), control
    )
    if (!identical(derivative$status, "ok")) {
      return(drm_pair_sandwich_unavailable(paste0(
        "association_", derivative$reason
      )))
    }
    gradient <- derivative$gradient
    hessian <- derivative$hessian
    score_a[i, ] <- x_a[i, ] * gradient[[1L]]
    bread_al_mu <- bread_al_mu - tcrossprod(x_a[i, ], x_l[i, ]) *
      hessian[1L, 2L] / n
    bread_al_sigma <- bread_al_sigma - tcrossprod(x_a[i, ], z_l[i, ]) *
      hessian[1L, 3L] / n
    bread_ar_mu <- bread_ar_mu - tcrossprod(x_a[i, ], x_r[i, ]) *
      hessian[1L, 4L] / n
    bread_ar_sigma <- bread_ar_sigma - tcrossprod(x_a[i, ], z_r[i, ]) *
      hessian[1L, 5L] / n
    bread_aa <- bread_aa - tcrossprod(x_a[i, ]) * hessian[1L, 1L] / n
    diagnostics[[i]] <- derivative$diagnostics
  }
  list(
    status = "ok",
    score_a = score_a,
    bread_al_mu = bread_al_mu,
    bread_al_sigma = bread_al_sigma,
    bread_ar_mu = bread_ar_mu,
    bread_ar_sigma = bread_ar_sigma,
    bread_aa = bread_aa,
    derivative_diagnostics = diagnostics
  )
}

# Production association likelihood delegates directly to the admitted NB2
# rectangle routine, retaining its tail-safe endpoint and quadrature policy.
drm_pair_nbinom2_nbinom2_sandwich_row_logprob <- function(
  y_l,
  y_r,
  xi_l,
  tau_l,
  xi_r,
  tau_r,
  a
) {
  result <- drm_pair_nbinom2_nbinom2_rectangle_probability(
    y_1 = y_l,
    mu_1 = exp(xi_l),
    sigma_1 = exp(tau_l),
    y_2 = y_r,
    mu_2 = exp(xi_r),
    sigma_2 = exp(tau_r),
    eta = 0.999999 * tanh(a)
  )
  if (!identical(result$status, "ok")) NA_real_ else result$log_probability
}
