phase18_biv_gaussian_q2_scale_slope_conditions <- function(
  n_id = c(48L),
  n_each = c(12L),
  beta_mu1_intercept = 0.20,
  beta_mu1_x = 0.45,
  beta_mu2_intercept = -0.10,
  beta_mu2_x = -0.35,
  sigma1 = 0.38,
  sigma2 = 0.52,
  beta_sigma1_x = 0.10,
  beta_sigma2_x = -0.08,
  sd_sigma1 = 0.28,
  sd_sigma2 = 0.34,
  cor_sigma1_sigma2 = 0.45,
  residual_rho = 0.20
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
  conditions$sd_sigma1 <- sd_sigma1
  conditions$sd_sigma2 <- sd_sigma2
  conditions$cor_sigma1_sigma2 <- cor_sigma1_sigma2
  conditions$residual_rho <- residual_rho
  conditions
}

phase18_biv_gaussian_q2_scale_slope_sd_names <- function() {
  c(
    "sigma1:(0 + x | p | id)",
    "sigma2:(0 + x | p | id)"
  )
}

phase18_biv_gaussian_q2_scale_slope_cor_name <- function() {
  "cor(sigma1:x,sigma2:x | p | id)"
}

phase18_dgp_biv_gaussian_q2_scale_slope <- function(
  n_id,
  n_each,
  beta_mu1 = c("(Intercept)" = 0.20, x = 0.45),
  beta_mu2 = c("(Intercept)" = -0.10, x = -0.35),
  beta_sigma1 = c("(Intercept)" = log(0.38), x = 0.10),
  beta_sigma2 = c("(Intercept)" = log(0.52), x = -0.08),
  sd_sigma = c(
    "sigma1:(0 + x | p | id)" = 0.28,
    "sigma2:(0 + x | p | id)" = 0.34
  ),
  cor_sigma = 0.45,
  residual_rho = 0.20,
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
  sd_sigma <- phase18_named_pair(
    sd_sigma,
    phase18_biv_gaussian_q2_scale_slope_sd_names(),
    "sd_sigma"
  )
  if (any(sd_sigma <= 0)) {
    stop("`sd_sigma` values must be positive.", call. = FALSE)
  }
  assert_phase18_correlation(cor_sigma, "cor_sigma")
  assert_phase18_correlation(residual_rho, "residual_rho")

  corr <- matrix(c(1, cor_sigma, cor_sigma, 1), 2L, 2L)
  cor_sigma <- stats::setNames(
    cor_sigma,
    phase18_biv_gaussian_q2_scale_slope_cor_name()
  )

  draw <- function() {
    id <- factor(rep(seq_len(n_id), each = n_each))
    n <- length(id)
    x_base <- seq(-1, 1, length.out = n_each)
    x <- rep(x_base, times = n_id)

    random_normal <- matrix(stats::rnorm(n_id * 2L), n_id, 2L)
    b <- sweep(random_normal %*% chol(corr), 2L, sd_sigma, `*`)

    log_sigma1 <- beta_sigma1[["(Intercept)"]] +
      beta_sigma1[["x"]] * x +
      b[id, 1L] * x
    log_sigma2 <- beta_sigma2[["(Intercept)"]] +
      beta_sigma2[["x"]] * x +
      b[id, 2L] * x
    sigma1_obs <- exp(log_sigma1)
    sigma2_obs <- exp(log_sigma2)

    e1 <- stats::rnorm(n)
    e2 <- residual_rho * e1 + sqrt(1 - residual_rho^2) * stats::rnorm(n)
    mu1 <- unname(beta_mu1[["(Intercept)"]] + beta_mu1[["x"]] * x)
    mu2 <- unname(beta_mu2[["(Intercept)"]] + beta_mu2[["x"]] * x)

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
      surface = "biv_gaussian_q2_scale_slope",
      beta_mu1 = beta_mu1,
      beta_mu2 = beta_mu2,
      beta_sigma1 = beta_sigma1,
      beta_sigma2 = beta_sigma2,
      sd_sigma = sd_sigma,
      cor_sigma = cor_sigma,
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
