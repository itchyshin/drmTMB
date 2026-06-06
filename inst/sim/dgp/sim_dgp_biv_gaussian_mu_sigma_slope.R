phase18_biv_gaussian_mu_sigma_slope_conditions <- function(
  n_id = c(72L),
  n_each = c(10L),
  beta_mu1_intercept = 0.15,
  beta_mu1_x = 0.42,
  beta_mu2_intercept = -0.12,
  beta_mu2_x = -0.28,
  sigma1 = 0.45,
  sigma2 = 0.55,
  beta_sigma1_x = 0.10,
  beta_sigma2_x = -0.05,
  sd_mu1 = 0.42,
  sd_sigma1 = 0.26,
  cor_mu1_sigma1 = 0.38,
  residual_rho = 0.18
) {
  conditions <- expand.grid(
    n_id = as.integer(n_id),
    n_each = as.integer(n_each),
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  conditions$beta_mu1_intercept <- beta_mu1_intercept
  conditions$beta_mu1_x <- beta_mu1_x
  conditions$beta_mu2_intercept <- beta_mu2_intercept
  conditions$beta_mu2_x <- beta_mu2_x
  conditions$sigma1 <- sigma1
  conditions$sigma2 <- sigma2
  conditions$beta_sigma1_x <- beta_sigma1_x
  conditions$beta_sigma2_x <- beta_sigma2_x
  conditions$sd_mu1 <- sd_mu1
  conditions$sd_sigma1 <- sd_sigma1
  conditions$cor_mu1_sigma1 <- cor_mu1_sigma1
  conditions$residual_rho <- residual_rho
  conditions
}

phase18_biv_gaussian_mu_sigma_slope_sd_mu_name <- function() {
  "mu1:(0 + x | p | id)"
}

phase18_biv_gaussian_mu_sigma_slope_sd_sigma_name <- function() {
  "sigma1:(0 + x | p | id)"
}

phase18_biv_gaussian_mu_sigma_slope_cor_name <- function() {
  "cor(mu1:x,sigma1:x | p | id)"
}

phase18_dgp_biv_gaussian_mu_sigma_slope <- function(
  n_id,
  n_each,
  beta_mu1 = c("(Intercept)" = 0.15, x = 0.42),
  beta_mu2 = c("(Intercept)" = -0.12, x = -0.28),
  beta_sigma1 = c("(Intercept)" = log(0.45), x = 0.10),
  beta_sigma2 = c("(Intercept)" = log(0.55), x = -0.05),
  sd_mu = c("mu1:(0 + x | p | id)" = 0.42),
  sd_sigma = c("sigma1:(0 + x | p | id)" = 0.26),
  cor_mu_sigma = 0.38,
  residual_rho = 0.18,
  seed = NULL,
  cell_id = NA_character_,
  replicate = NA_integer_
) {
  assert_positive_whole_number(n_id, "n_id")
  assert_positive_whole_number(n_each, "n_each")
  beta_mu1 <- phase18_named_pair(beta_mu1, c("(Intercept)", "x"), "beta_mu1")
  beta_mu2 <- phase18_named_pair(beta_mu2, c("(Intercept)", "x"), "beta_mu2")
  beta_sigma1 <- phase18_named_pair(
    beta_sigma1,
    c("(Intercept)", "x"),
    "beta_sigma1"
  )
  beta_sigma2 <- phase18_named_pair(
    beta_sigma2,
    c("(Intercept)", "x"),
    "beta_sigma2"
  )
  if (!is.numeric(sd_mu) || length(sd_mu) != 1L || !is.finite(sd_mu)) {
    stop("`sd_mu` must be a finite numeric vector of length 1.", call. = FALSE)
  }
  if (!is.numeric(sd_sigma) || length(sd_sigma) != 1L || !is.finite(sd_sigma)) {
    stop(
      "`sd_sigma` must be a finite numeric vector of length 1.",
      call. = FALSE
    )
  }
  if (is.null(names(sd_mu)) || !nzchar(names(sd_mu)[[1L]])) {
    names(sd_mu) <- phase18_biv_gaussian_mu_sigma_slope_sd_mu_name()
  }
  if (is.null(names(sd_sigma)) || !nzchar(names(sd_sigma)[[1L]])) {
    names(sd_sigma) <- phase18_biv_gaussian_mu_sigma_slope_sd_sigma_name()
  }
  if (
    !identical(names(sd_mu), phase18_biv_gaussian_mu_sigma_slope_sd_mu_name())
  ) {
    stop(
      "`sd_mu` must be unnamed or named ",
      phase18_biv_gaussian_mu_sigma_slope_sd_mu_name(),
      ".",
      call. = FALSE
    )
  }
  if (
    !identical(
      names(sd_sigma),
      phase18_biv_gaussian_mu_sigma_slope_sd_sigma_name()
    )
  ) {
    stop(
      "`sd_sigma` must be unnamed or named ",
      phase18_biv_gaussian_mu_sigma_slope_sd_sigma_name(),
      ".",
      call. = FALSE
    )
  }
  if (sd_mu <= 0) {
    stop("`sd_mu` value must be positive.", call. = FALSE)
  }
  if (sd_sigma <= 0) {
    stop("`sd_sigma` value must be positive.", call. = FALSE)
  }
  assert_phase18_correlation(cor_mu_sigma, "cor_mu_sigma")
  assert_phase18_correlation(residual_rho, "residual_rho")

  corr <- matrix(c(1, cor_mu_sigma, cor_mu_sigma, 1), 2L, 2L)
  cor_mu_sigma <- stats::setNames(
    cor_mu_sigma,
    phase18_biv_gaussian_mu_sigma_slope_cor_name()
  )

  draw <- function() {
    id <- factor(rep(seq_len(n_id), each = n_each))
    n <- length(id)
    x_base <- seq(-1.25, 1.25, length.out = n_each)
    x <- rep(x_base, times = n_id)

    random_normal <- matrix(stats::rnorm(n_id * 2L), n_id, 2L)
    b <- random_normal %*% chol(corr)
    b_mu1 <- unname(sd_mu[[1L]] * b[, 1L])
    b_sigma1 <- unname(sd_sigma[[1L]] * b[, 2L])

    mu1 <- beta_mu1[["(Intercept)"]] +
      beta_mu1[["x"]] * x +
      b_mu1[id] * x
    mu2 <- beta_mu2[["(Intercept)"]] + beta_mu2[["x"]] * x
    log_sigma1 <- beta_sigma1[["(Intercept)"]] +
      beta_sigma1[["x"]] * x +
      b_sigma1[id] * x
    log_sigma2 <- beta_sigma2[["(Intercept)"]] + beta_sigma2[["x"]] * x
    sigma1_obs <- exp(log_sigma1)
    sigma2_obs <- exp(log_sigma2)

    e1 <- stats::rnorm(n)
    e2 <- residual_rho * e1 + sqrt(1 - residual_rho^2) * stats::rnorm(n)

    dat <- data.frame(
      y1 = mu1 + sigma1_obs * e1,
      y2 = mu2 + sigma2_obs * e2,
      x = x,
      id = id,
      mu1 = mu1,
      mu2 = mu2,
      sigma1 = sigma1_obs,
      sigma2 = sigma2_obs,
      cell_id = cell_id,
      replicate = replicate,
      stringsAsFactors = FALSE
    )
    attr(dat, "truth") <- list(
      surface = "biv_gaussian_mu_sigma_slope",
      beta_mu1 = beta_mu1,
      beta_mu2 = beta_mu2,
      beta_sigma1 = beta_sigma1,
      beta_sigma2 = beta_sigma2,
      sd_mu = sd_mu,
      sd_sigma = sd_sigma,
      cor_mu_sigma = cor_mu_sigma,
      residual_rho = c(rho12 = residual_rho),
      n_id = n_id,
      n_each = n_each
    )
    dat
  }

  if (is.null(seed)) {
    draw()
  } else {
    phase18_with_seed(seed, draw)
  }
}
