phase18_gaussian_sigma_rs_conditions <- function(
  n_group = c(32L, 48L),
  n_per_group = c(8L, 10L),
  sd_sigma_w = 0.34,
  beta_mu_intercept = 0.20,
  beta_mu_x = 0.60,
  beta_sigma_intercept = log(0.55),
  beta_sigma_z = 0.24
) {
  conditions <- expand.grid(
    n_group = as.integer(n_group),
    n_per_group = as.integer(n_per_group),
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  conditions$sd_sigma_w <- sd_sigma_w
  conditions$beta_mu_intercept <- beta_mu_intercept
  conditions$beta_mu_x <- beta_mu_x
  conditions$beta_sigma_intercept <- beta_sigma_intercept
  conditions$beta_sigma_z <- beta_sigma_z
  conditions
}

phase18_dgp_gaussian_sigma_rs <- function(
  n_group,
  n_per_group,
  beta_mu = c("(Intercept)" = 0.20, x = 0.60),
  beta_sigma = c("(Intercept)" = log(0.55), z = 0.24),
  sd_sigma_w = 0.34,
  seed = NULL,
  cell_id = NA_character_,
  replicate = NA_integer_
) {
  assert_positive_whole_number(n_group, "n_group")
  assert_positive_whole_number(n_per_group, "n_per_group")
  beta_mu <- phase18_named_pair(beta_mu, c("(Intercept)", "x"), "beta_mu")
  beta_sigma <- phase18_named_pair(
    beta_sigma,
    c("(Intercept)", "z"),
    "beta_sigma"
  )
  assert_phase18_positive_number(sd_sigma_w, "sd_sigma_w")

  draw <- function() {
    n <- n_group * n_per_group
    id <- factor(rep(seq_len(n_group), each = n_per_group))
    x <- stats::rnorm(n)
    z <- stats::rnorm(n)
    w <- rep(seq(-1, 1, length.out = n_per_group), times = n_group) +
      stats::rnorm(n, sd = 0.06)
    a_w <- stats::rnorm(n_group, sd = sd_sigma_w)
    a_w <- a_w - mean(a_w)

    mu <- unname(beta_mu[["(Intercept)"]] + beta_mu[["x"]] * x)
    log_sigma <- unname(
      beta_sigma[["(Intercept)"]] +
        beta_sigma[["z"]] * z +
        a_w[id] * w
    )
    sigma <- exp(log_sigma)
    y <- stats::rnorm(n, mean = mu, sd = sigma)

    dat <- data.frame(
      y = y,
      x = x,
      z = z,
      w = w,
      id = id,
      mu = mu,
      sigma = sigma,
      log_sigma = log_sigma,
      cell_id = cell_id,
      replicate = replicate,
      stringsAsFactors = FALSE
    )
    attr(dat, "truth") <- list(
      surface = "gaussian_sigma_random_slope",
      beta_mu = beta_mu,
      beta_sigma = beta_sigma,
      sd_sigma = c("(0 + w | id)" = sd_sigma_w),
      n_group = n_group,
      n_per_group = n_per_group
    )
    dat
  }

  if (is.null(seed)) {
    draw()
  } else {
    phase18_with_seed(seed, draw)
  }
}
