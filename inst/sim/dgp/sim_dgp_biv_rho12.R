phase18_biv_rho12_conditions <- function(
  n = c(180L, 540L),
  delta0 = atanh(c(-0.35, 0.35)),
  delta1 = c(0, 0.35),
  sigma_ratio = c(0.7, 1.4),
  rho_xw = c(0, 0.5),
  beta_mu1_intercept = 0.25,
  beta_mu1_x = 0.50,
  beta_mu2_intercept = -0.10,
  beta_mu2_x = -0.35,
  beta_sigma1_intercept = log(0.55),
  beta_sigma1_z = 0.15,
  beta_sigma2_z = -0.12
) {
  conditions <- expand.grid(
    n = as.integer(n),
    delta0 = delta0,
    delta1 = delta1,
    sigma_ratio = sigma_ratio,
    rho_xw = rho_xw,
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  conditions$beta_mu1_intercept <- beta_mu1_intercept
  conditions$beta_mu1_x <- beta_mu1_x
  conditions$beta_mu2_intercept <- beta_mu2_intercept
  conditions$beta_mu2_x <- beta_mu2_x
  conditions$beta_sigma1_intercept <- beta_sigma1_intercept
  conditions$beta_sigma1_z <- beta_sigma1_z
  conditions$beta_sigma2_z <- beta_sigma2_z
  conditions
}

phase18_dgp_biv_rho12 <- function(
  n,
  beta_mu1 = c("(Intercept)" = 0.25, x = 0.50),
  beta_mu2 = c("(Intercept)" = -0.10, x = -0.35),
  beta_sigma1 = c("(Intercept)" = log(0.55), z1 = 0.15),
  beta_sigma2 = c("(Intercept)" = log(0.65), z2 = -0.12),
  beta_rho12 = c("(Intercept)" = atanh(0.35), w = 0.35),
  rho_xw = 0,
  seed = NULL,
  cell_id = NA_character_,
  replicate = NA_integer_
) {
  assert_positive_whole_number(n, "n")
  beta_mu1 <- phase18_named_pair(
    beta_mu1,
    c("(Intercept)", "x"),
    "beta_mu1"
  )
  beta_mu2 <- phase18_named_pair(
    beta_mu2,
    c("(Intercept)", "x"),
    "beta_mu2"
  )
  beta_sigma1 <- phase18_named_pair(
    beta_sigma1,
    c("(Intercept)", "z1"),
    "beta_sigma1"
  )
  beta_sigma2 <- phase18_named_pair(
    beta_sigma2,
    c("(Intercept)", "z2"),
    "beta_sigma2"
  )
  beta_rho12 <- phase18_named_pair(
    beta_rho12,
    c("(Intercept)", "w"),
    "beta_rho12"
  )
  assert_phase18_correlation(rho_xw, "rho_xw")

  draw <- function() {
    x <- stats::rnorm(n)
    w_noise <- stats::rnorm(n)
    w <- rho_xw * x + sqrt(1 - rho_xw^2) * w_noise
    z1 <- stats::rnorm(n)
    z2 <- stats::rnorm(n)

    mu1 <- unname(beta_mu1[["(Intercept)"]] + beta_mu1[["x"]] * x)
    mu2 <- unname(beta_mu2[["(Intercept)"]] + beta_mu2[["x"]] * x)
    log_sigma1 <- unname(
      beta_sigma1[["(Intercept)"]] + beta_sigma1[["z1"]] * z1
    )
    log_sigma2 <- unname(
      beta_sigma2[["(Intercept)"]] + beta_sigma2[["z2"]] * z2
    )
    sigma1 <- exp(log_sigma1)
    sigma2 <- exp(log_sigma2)
    eta_rho12 <- unname(
      beta_rho12[["(Intercept)"]] + beta_rho12[["w"]] * w
    )
    rho12 <- 0.99999999 * tanh(eta_rho12)

    e1 <- stats::rnorm(n)
    e2 <- rho12 * e1 + sqrt(1 - rho12^2) * stats::rnorm(n)
    dat <- data.frame(
      y1 = mu1 + sigma1 * e1,
      y2 = mu2 + sigma2 * e2,
      x = x,
      z1 = z1,
      z2 = z2,
      w = w,
      mu1 = mu1,
      mu2 = mu2,
      sigma1 = sigma1,
      sigma2 = sigma2,
      rho12 = rho12,
      residual_covariance = rho12 * sigma1 * sigma2,
      cell_id = cell_id,
      replicate = replicate,
      stringsAsFactors = FALSE
    )
    attr(dat, "truth") <- list(
      surface = "biv_rho12",
      beta_mu1 = beta_mu1,
      beta_mu2 = beta_mu2,
      beta_sigma1 = beta_sigma1,
      beta_sigma2 = beta_sigma2,
      beta_rho12 = beta_rho12,
      n = n,
      rho_xw = rho_xw
    )
    dat
  }

  if (is.null(seed)) {
    draw()
  } else {
    phase18_with_seed(seed, draw)
  }
}
