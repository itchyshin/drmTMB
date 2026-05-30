phase18_biv_gaussian_mu_slope_conditions <- function(
  n_id = c(36L),
  n_each = c(6L),
  beta_mu1_intercept = 0.15,
  beta_mu1_x = 0.45,
  beta_mu2_intercept = -0.20,
  beta_mu2_x = -0.35,
  sigma1 = 0.35,
  sigma2 = 0.40,
  sd_slope1 = 0.55,
  sd_slope2 = 0.48,
  rho_slope = 0.50,
  residual_rho = 0.15
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
  conditions$sd_slope1 <- sd_slope1
  conditions$sd_slope2 <- sd_slope2
  conditions$rho_slope <- rho_slope
  conditions$residual_rho <- residual_rho
  conditions
}

phase18_dgp_biv_gaussian_mu_slope <- function(
  n_id,
  n_each,
  beta_mu1 = c("(Intercept)" = 0.15, x = 0.45),
  beta_mu2 = c("(Intercept)" = -0.20, x = -0.35),
  sigma = c(sigma1 = 0.35, sigma2 = 0.40),
  sd_mu = c(
    "mu1:(0 + x | p | id)" = 0.55,
    "mu2:(0 + x | p | id)" = 0.48
  ),
  rho_slope = 0.50,
  residual_rho = 0.15,
  seed = NULL,
  cell_id = NA_character_,
  replicate = NA_integer_
) {
  assert_positive_whole_number(n_id, "n_id")
  assert_positive_whole_number(n_each, "n_each")
  beta_mu1 <- phase18_named_pair(beta_mu1, c("(Intercept)", "x"), "beta_mu1")
  beta_mu2 <- phase18_named_pair(beta_mu2, c("(Intercept)", "x"), "beta_mu2")
  sigma <- phase18_named_pair(sigma, c("sigma1", "sigma2"), "sigma")
  if (any(sigma <= 0)) {
    stop("`sigma` values must be positive.", call. = FALSE)
  }
  sd_mu <- phase18_named_pair(
    sd_mu,
    c("mu1:(0 + x | p | id)", "mu2:(0 + x | p | id)"),
    "sd_mu"
  )
  if (any(sd_mu <= 0)) {
    stop("`sd_mu` values must be positive.", call. = FALSE)
  }
  assert_phase18_correlation(rho_slope, "rho_slope")
  assert_phase18_correlation(residual_rho, "residual_rho")

  draw <- function() {
    id <- factor(rep(seq_len(n_id), each = n_each))
    n <- length(id)
    x <- rep(seq(-1, 1, length.out = n_each), times = n_id)

    u1 <- stats::rnorm(n_id)
    u2 <- rho_slope * u1 + sqrt(1 - rho_slope^2) * stats::rnorm(n_id)
    b1 <- sd_mu[["mu1:(0 + x | p | id)"]] * u1
    b2 <- sd_mu[["mu2:(0 + x | p | id)"]] * u2

    e1 <- stats::rnorm(n)
    e2 <- residual_rho * e1 + sqrt(1 - residual_rho^2) * stats::rnorm(n)
    mu1 <- unname(beta_mu1[["(Intercept)"]] + beta_mu1[["x"]] * x + b1[id] * x)
    mu2 <- unname(beta_mu2[["(Intercept)"]] + beta_mu2[["x"]] * x + b2[id] * x)

    dat <- data.frame(
      y1 = mu1 + sigma[["sigma1"]] * e1,
      y2 = mu2 + sigma[["sigma2"]] * e2,
      x = x,
      id = id,
      mu1 = mu1,
      mu2 = mu2,
      sigma1 = sigma[["sigma1"]],
      sigma2 = sigma[["sigma2"]],
      cell_id = cell_id,
      replicate = replicate,
      stringsAsFactors = FALSE
    )
    attr(dat, "truth") <- list(
      surface = "biv_gaussian_mu_slope",
      beta_mu1 = beta_mu1,
      beta_mu2 = beta_mu2,
      sigma = sigma,
      sd_mu = sd_mu,
      rho_slope = c("cor(mu1:x,mu2:x | p | id)" = rho_slope),
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
