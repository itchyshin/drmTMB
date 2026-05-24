phase18_nbinom2_sigma_re_conditions <- function(
  n_group = c(32L, 48L),
  n_per_group = c(12L, 18L),
  mean_count = c(2.0, 4.0),
  sigma_baseline = c(0.45, 0.80),
  sd_sigma_intercept = c(0.25, 0.45),
  beta_mu_x = -0.18,
  beta_sigma_z = 0.16
) {
  conditions <- expand.grid(
    n_group = as.integer(n_group),
    n_per_group = as.integer(n_per_group),
    mean_count = mean_count,
    sigma_baseline = sigma_baseline,
    sd_sigma_intercept = sd_sigma_intercept,
    beta_mu_x = beta_mu_x,
    beta_sigma_z = beta_sigma_z,
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  conditions
}

phase18_dgp_nbinom2_sigma_re <- function(
  n_group,
  n_per_group,
  beta_mu = c("(Intercept)" = log(2.5), x = -0.18),
  beta_sigma = c("(Intercept)" = log(0.55), z = 0.16),
  sd_sigma = c("(1 | id)" = 0.35),
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
  if (
    !is.numeric(sd_sigma) ||
      length(sd_sigma) != 1L ||
      !is.finite(sd_sigma) ||
      sd_sigma <= 0
  ) {
    stop("`sd_sigma` must be one positive finite number.", call. = FALSE)
  }
  names(sd_sigma) <- "(1 | id)"

  draw <- function() {
    n <- n_group * n_per_group
    id <- factor(rep(seq_len(n_group), each = n_per_group))
    x <- rep(seq(-1, 1, length.out = n_per_group), times = n_group)
    z <- rep(seq(-0.8, 0.8, length.out = n_per_group), times = n_group)
    a_sigma <- stats::rnorm(n_group, sd = sd_sigma[["(1 | id)"]])

    eta_mu <- unname(beta_mu[["(Intercept)"]] + beta_mu[["x"]] * x)
    eta_sigma <- unname(
      beta_sigma[["(Intercept)"]] +
        beta_sigma[["z"]] * z +
        a_sigma[id]
    )
    mu <- exp(eta_mu)
    sigma <- exp(eta_sigma)
    count <- as.integer(stats::rnbinom(n, size = 1 / sigma^2, mu = mu))

    dat <- data.frame(
      count = count,
      x = x,
      z = z,
      id = id,
      eta_mu = eta_mu,
      eta_sigma = eta_sigma,
      mu = mu,
      sigma = sigma,
      cell_id = cell_id,
      replicate = replicate,
      stringsAsFactors = FALSE
    )
    attr(dat, "truth") <- list(
      surface = "nbinom2_sigma_random_effect",
      beta_mu = beta_mu,
      beta_sigma = beta_sigma,
      sd = sd_sigma,
      n_group = n_group,
      n_per_group = n_per_group,
      mean_count = exp(beta_mu[["(Intercept)"]]),
      sigma_baseline = exp(beta_sigma[["(Intercept)"]])
    )
    dat
  }

  if (is.null(seed)) {
    draw()
  } else {
    phase18_with_seed(seed, draw)
  }
}
