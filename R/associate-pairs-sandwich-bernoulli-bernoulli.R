# Developer-only candidate sandwich variance for literal Bernoulli x Bernoulli
# frozen-margin association fits.  Repeated families retain caller order:
# L = fit_1 and R = fit_2.  This is intentionally not a public uncertainty API.

drm_pair_bernoulli_bernoulli_sandwich <- function(
  fit_1,
  fit_2,
  association_fit,
  control = drm_pair_sandwich_control()
) {
  if (
    !inherits(association_fit, "drm_pair_association") ||
      !identical(association_fit$components$pair_class, "bernoulli_bernoulli")
  ) {
    cli::cli_abort(
      "The staged sandwich is defined only for literal Bernoulli x Bernoulli association fits."
    )
  }
  if (!association_fit$status %in% c("interior", "near_boundary")) {
    return(drm_pair_sandwich_unavailable("association_unresolved"))
  }

  # These are intentionally separate calls.  Repeated-family pairs must never
  # infer a side by set membership: L is fit_1 and R is fit_2.
  drm_pair_validate_fit(fit_1, "left Bernoulli margin")
  drm_pair_validate_fit(fit_2, "right Bernoulli margin")
  drm_pair_validate_shared_data(fit_1, fit_2)
  drm_pair_validate_bernoulli(fit_1)
  drm_pair_validate_bernoulli(fit_2)

  x_l <- as.matrix(fit_1$model$X$mu)
  x_r <- as.matrix(fit_2$model$X$mu)
  x_a <- as.matrix(association_fit$association_design$matrix)
  n <- nrow(x_a)
  if (!all(c(nrow(x_l), nrow(x_r)) == n)) {
    return(drm_pair_sandwich_unavailable("design_row_mismatch"))
  }
  beta_l <- unname(fit_1$coefficients$mu)
  beta_r <- unname(fit_2$coefficients$mu)
  alpha <- unname(association_fit$association_coefficients)
  if (
    length(beta_l) != ncol(x_l) ||
      length(beta_r) != ncol(x_r) ||
      length(alpha) != ncol(x_a)
  ) {
    return(drm_pair_sandwich_unavailable("coefficient_design_mismatch"))
  }

  lambda_l <- as.vector(x_l %*% beta_l)
  lambda_r <- as.vector(x_r %*% beta_r)
  p_l <- stats::plogis(lambda_l)
  p_r <- stats::plogis(lambda_r)
  a <- as.vector(x_a %*% alpha)
  if (!drm_pair_bernoulli_bernoulli_sandwich_frozen_matches(
    fit_1 = fit_1,
    fit_2 = fit_2,
    association_fit = association_fit,
    p_l = p_l,
    p_r = p_r,
    x_a = x_a
  )) {
    return(drm_pair_sandwich_unavailable("frozen_margin_mismatch"))
  }
  if (any(a <= -8 + 0.01 | a >= 8 - 0.01)) {
    return(drm_pair_sandwich_unavailable("association_boundary"))
  }

  components <- association_fit$components
  marginal <- drm_pair_bernoulli_bernoulli_sandwich_margin_blocks(
    y_l = components$binary_1_y,
    y_r = components$binary_2_y,
    p_l = p_l,
    p_r = p_r,
    x_l = x_l,
    x_r = x_r
  )
  association <- drm_pair_bernoulli_bernoulli_sandwich_association_blocks(
    y_l = components$binary_1_y,
    y_r = components$binary_2_y,
    lambda_l = lambda_l,
    lambda_r = lambda_r,
    a = a,
    x_l = x_l,
    x_r = x_r,
    x_a = x_a,
    control = control
  )
  if (!identical(association$status, "ok")) {
    return(association)
  }

  colnames(marginal$score_l) <- paste0("bernoulli_L_mu:", colnames(x_l))
  colnames(marginal$score_r) <- paste0("bernoulli_R_mu:", colnames(x_r))
  colnames(association$score_a) <- paste0("association:", colnames(x_a))
  assembled <- drm_pair_sandwich_assemble(
    margin_scores = list(marginal$score_l, marginal$score_r),
    margin_bread = list(marginal$bread_l, marginal$bread_r),
    association_score = association$score_a,
    association_bread = list(
      association$bread_al,
      association$bread_ar,
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

drm_pair_bernoulli_bernoulli_sandwich_frozen_matches <- function(
  fit_1,
  fit_2,
  association_fit,
  p_l,
  p_r,
  x_a
) {
  components <- association_fit$components
  margins <- association_fit$margins
  provenance <- association_fit$provenance
  expected_design <- tryCatch(
    drm_pair_association_design(
      association_fit$association,
      fit_1$data,
      "bernoulli_bernoulli"
    )$matrix,
    error = function(e) NULL
  )
  same <- function(x, y) isTRUE(all.equal(x, y, tolerance = 1e-8))
  identical(association_fit$margin_order,
    c(fit_1 = "bernoulli_1", fit_2 = "bernoulli_2")
  ) &&
    identical(association_fit$response_names, c(
      fit_1 = drm_pair_response_name(fit_1),
      fit_2 = drm_pair_response_name(fit_2)
    )) &&
    identical(components$binary_1_y, fit_1$model$y) &&
    identical(components$binary_2_y, fit_2$model$y) &&
    same(components$binary_1_p, p_l) &&
    same(components$binary_2_p, p_r) &&
    identical(margins$fit_1$response, fit_1$model$y) &&
    identical(margins$fit_2$response, fit_2$model$y) &&
    same(margins$fit_1$fitted$mu, p_l) &&
    same(margins$fit_2$fitted$mu, p_r) &&
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

drm_pair_bernoulli_bernoulli_sandwich_margin_blocks <- function(
  y_l,
  y_r,
  p_l,
  p_r,
  x_l,
  x_r
) {
  p_l <- as.vector(p_l)
  p_r <- as.vector(p_r)
  n <- length(y_l)
  list(
    score_l = x_l * (y_l - p_l),
    score_r = x_r * (y_r - p_r),
    bread_l = crossprod(x_l, x_l * (p_l * (1 - p_l))) / n,
    bread_r = crossprod(x_r, x_r * (p_r * (1 - p_r))) / n
  )
}

drm_pair_bernoulli_bernoulli_sandwich_association_blocks <- function(
  y_l,
  y_r,
  lambda_l,
  lambda_r,
  a,
  x_l,
  x_r,
  x_a,
  control
) {
  n <- length(a)
  p_l <- ncol(x_l)
  p_r <- ncol(x_r)
  p_a <- ncol(x_a)
  score_a <- matrix(NA_real_, n, p_a)
  bread_al <- matrix(0, p_a, p_l)
  bread_ar <- matrix(0, p_a, p_r)
  bread_aa <- matrix(0, p_a, p_a)
  diagnostics <- vector("list", n)
  for (i in seq_len(n)) {
    fn <- function(q) {
      drm_pair_bernoulli_bernoulli_sandwich_row_logprob(
        y_l = y_l[[i]],
        y_r = y_r[[i]],
        lambda_l = q[[2L]],
        lambda_r = q[[3L]],
        a = q[[1L]]
      )
    }
    derivative <- drm_pair_sandwich_stable_derivatives(
      fn,
      c(a[[i]], lambda_l[[i]], lambda_r[[i]]),
      control
    )
    if (!identical(derivative$status, "ok")) {
      return(drm_pair_sandwich_unavailable(paste0(
        "association_",
        derivative$reason
      )))
    }
    gradient <- derivative$gradient
    hessian <- derivative$hessian
    score_a[i, ] <- x_a[i, ] * gradient[[1L]]
    bread_al <- bread_al - tcrossprod(x_a[i, ], x_l[i, ]) * hessian[1L, 2L] / n
    bread_ar <- bread_ar - tcrossprod(x_a[i, ], x_r[i, ]) * hessian[1L, 3L] / n
    bread_aa <- bread_aa - tcrossprod(x_a[i, ]) * hessian[1L, 1L] / n
    diagnostics[[i]] <- derivative$diagnostics
  }
  list(
    status = "ok",
    score_a = score_a,
    bread_al = bread_al,
    bread_ar = bread_ar,
    bread_aa = bread_aa,
    derivative_diagnostics = diagnostics
  )
}

drm_pair_bernoulli_bernoulli_sandwich_row_logprob <- function(
  y_l,
  y_r,
  lambda_l,
  lambda_r,
  a
) {
  result <- drm_pair_bernoulli_rectangle_evaluation(
    y_1 = y_l,
    p_1 = stats::plogis(lambda_l),
    y_2 = y_r,
    p_2 = stats::plogis(lambda_r),
    eta = 0.999999 * tanh(a)
  )
  if (!is.finite(result$value) || result$value <= 0) {
    return(NA_real_)
  }
  log(result$value)
}
