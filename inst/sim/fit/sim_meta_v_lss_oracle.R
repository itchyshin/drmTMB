# Independent marginal-Gaussian oracle for the `meta_V()` L/LS/LSS/LSSS
# simulation designs.  It deliberately constructs the observation covariance
# in R rather than consulting fitted TMB random effects: known sampling
# covariance, residual scale, and each direct-SD random-intercept layer are
# additive on the covariance scale.

meta_v_lss_oracle_loglik <- function(
  y,
  X_mu,
  beta_mu,
  V,
  X_sigma,
  beta_sigma,
  study = NULL,
  X_sd_study = NULL,
  beta_sd_study = NULL,
  effect = NULL,
  X_sd_effect = NULL,
  beta_sd_effect = NULL
) {
  y <- meta_v_lss_oracle_numeric(y, "y")
  n <- length(y)
  X_mu <- meta_v_lss_oracle_matrix(X_mu, "X_mu", n_row = n)
  beta_mu <- meta_v_lss_oracle_numeric(beta_mu, "beta_mu")
  if (ncol(X_mu) != length(beta_mu)) {
    stop("`X_mu` columns must match the length of `beta_mu`.", call. = FALSE)
  }

  X_sigma <- meta_v_lss_oracle_matrix(X_sigma, "X_sigma", n_row = n)
  beta_sigma <- meta_v_lss_oracle_numeric(beta_sigma, "beta_sigma")
  if (ncol(X_sigma) != length(beta_sigma)) {
    stop("`X_sigma` columns must match the length of `beta_sigma`.", call. = FALSE)
  }
  # `beta_sigma` is the unconstrained log-SD coefficient vector, matching the
  # fitted TMB parameterization.  The response-scale residual SD is positive.
  sigma <- exp(drop(X_sigma %*% beta_sigma))
  if (any(!is.finite(sigma))) {
    stop("The residual-scale model produced non-finite standard deviations.", call. = FALSE)
  }
  covariance <- meta_v_lss_oracle_known_v(V, n) + diag(sigma^2, n)

  covariance <- covariance + meta_v_lss_oracle_group_covariance(
    group = study,
    X_sd = X_sd_study,
    beta_sd = beta_sd_study,
    layer = "study",
    n = n
  )
  covariance <- covariance + meta_v_lss_oracle_group_covariance(
    group = effect,
    X_sd = X_sd_effect,
    beta_sd = beta_sd_effect,
    layer = "effect",
    n = n
  )

  R <- tryCatch(
    chol(covariance),
    error = function(e) NULL
  )
  if (is.null(R)) {
    stop("The model-implied covariance is not positive definite.", call. = FALSE)
  }
  residual <- y - drop(X_mu %*% beta_mu)
  whitened <- forwardsolve(t(R), residual)
  -0.5 * (
    n * log(2 * pi) + 2 * sum(log(diag(R))) + sum(whitened^2)
  )
}

meta_v_lss_oracle_known_v <- function(V, n) {
  if (is.numeric(V) && is.null(dim(V))) {
    if (length(V) != n || any(!is.finite(V)) || any(V < 0)) {
      stop("Vector `V` must have one finite non-negative variance per row.", call. = FALSE)
    }
    return(diag(V, n))
  }
  V <- meta_v_lss_oracle_matrix(V, "V", n_row = n, n_col = n)
  if (!isTRUE(all.equal(V, t(V), tolerance = 1e-10, check.attributes = FALSE))) {
    stop("Matrix `V` must be symmetric.", call. = FALSE)
  }
  V
}

meta_v_lss_oracle_group_covariance <- function(
  group,
  X_sd,
  beta_sd,
  layer,
  n
) {
  supplied <- c(!is.null(group), !is.null(X_sd), !is.null(beta_sd))
  if (!any(supplied)) {
    return(matrix(0, n, n))
  }
  if (!all(supplied)) {
    stop(
      sprintf(
        "`%s`, `X_sd_%s`, and `beta_sd_%s` must be supplied together.",
        layer, layer, layer
      ),
      call. = FALSE
    )
  }
  if (length(group) != n || anyNA(group)) {
    stop(sprintf("`%s` must be a complete vector with one value per row.", layer), call. = FALSE)
  }
  group <- factor(group)
  X_sd <- meta_v_lss_oracle_matrix(
    X_sd,
    sprintf("X_sd_%s", layer),
    n_row = nlevels(group)
  )
  beta_sd <- meta_v_lss_oracle_numeric(beta_sd, sprintf("beta_sd_%s", layer))
  if (ncol(X_sd) != length(beta_sd)) {
    stop(
      sprintf("`X_sd_%s` columns must match `beta_sd_%s`.", layer, layer),
      call. = FALSE
    )
  }
  group_sd <- exp(drop(X_sd %*% beta_sd))
  if (any(!is.finite(group_sd)) || any(group_sd <= 0)) {
    stop(sprintf("The direct-SD `%s` layer produced non-finite scales.", layer), call. = FALSE)
  }
  Z <- stats::model.matrix(~ 0 + group)
  Z %*% diag(group_sd^2, nrow = length(group_sd)) %*% t(Z)
}

meta_v_lss_oracle_matrix <- function(x, name, n_row = NULL, n_col = NULL) {
  if (!is.matrix(x) || !is.numeric(x) || any(!is.finite(x))) {
    stop(sprintf("`%s` must be a finite numeric matrix.", name), call. = FALSE)
  }
  if (!is.null(n_row) && nrow(x) != n_row) {
    stop(sprintf("`%s` must have %d rows.", name, n_row), call. = FALSE)
  }
  if (!is.null(n_col) && ncol(x) != n_col) {
    stop(sprintf("`%s` must have %d columns.", name, n_col), call. = FALSE)
  }
  x
}

meta_v_lss_oracle_numeric <- function(x, name) {
  if (!is.numeric(x) || !length(x) || any(!is.finite(x))) {
    stop(sprintf("`%s` must be a non-empty finite numeric vector.", name), call. = FALSE)
  }
  as.numeric(x)
}
