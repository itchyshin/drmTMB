phase18_truncated_nbinom2_mu_ri_conditions <- function(
  n_group = c(36L, 48L),
  n_per_group = c(8L, 10L),
  beta_mu_intercept = 0.35,
  beta_mu_x = -0.28,
  beta_sigma_intercept = -0.65,
  beta_sigma_z = c(0, 0.15),
  sd_intercept = c(0.30, 0.45)
) {
  conditions <- expand.grid(
    n_group = as.integer(n_group),
    n_per_group = as.integer(n_per_group),
    beta_sigma_intercept = beta_sigma_intercept,
    beta_sigma_z = beta_sigma_z,
    sd_intercept = sd_intercept,
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  conditions$beta_mu_intercept <- beta_mu_intercept
  conditions$beta_mu_x <- beta_mu_x
  conditions[c(
    "n_group",
    "n_per_group",
    "beta_mu_intercept",
    "beta_mu_x",
    "beta_sigma_intercept",
    "beta_sigma_z",
    "sd_intercept"
  )]
}

phase18_dgp_truncated_nbinom2_mu_ri <- function(
  n_group,
  n_per_group,
  beta_mu = c("(Intercept)" = 0.35, x = -0.28),
  beta_sigma = c("(Intercept)" = -0.65, z = 0.15),
  sd = c("(1 | id)" = 0.35),
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
  sd <- phase18_truncated_nbinom2_mu_ri_sd(sd)

  draw <- function() {
    n <- n_group * n_per_group
    id <- factor(rep(seq_len(n_group), each = n_per_group))
    x <- rep(seq(-1, 1, length.out = n_per_group), times = n_group) +
      stats::rnorm(n, sd = 0.05)
    z <- stats::rnorm(n)
    u_id <- stats::rnorm(n_group, sd = sd[["(1 | id)"]])
    u_id <- u_id - mean(u_id)
    names(u_id) <- levels(id)

    eta_mu <- unname(
      beta_mu[["(Intercept)"]] +
        beta_mu[["x"]] * x +
        u_id[id]
    )
    eta_sigma <- unname(
      beta_sigma[["(Intercept)"]] +
        beta_sigma[["z"]] * z
    )
    mu <- exp(eta_mu)
    sigma <- exp(eta_sigma)
    size <- 1 / sigma^2
    p0 <- stats::dnbinom(0, size = size, mu = mu)
    count <- as.integer(stats::qnbinom(
      p0 + stats::runif(n) * (1 - p0),
      size = size,
      mu = mu
    ))
    count[count < 1L] <- 1L

    dat <- data.frame(
      count = count,
      x = x,
      z = z,
      id = id,
      eta_mu = eta_mu,
      mu = mu,
      eta_sigma = eta_sigma,
      sigma = sigma,
      p0 = p0,
      fitted_mean = mu / (1 - p0),
      cell_id = cell_id,
      replicate = replicate,
      stringsAsFactors = FALSE
    )
    attr(dat, "truth") <- list(
      surface = "truncated_nbinom2_mu_random_intercept",
      beta_mu = beta_mu,
      beta_sigma = beta_sigma,
      sd = sd,
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

phase18_truncated_nbinom2_mu_ri_sd <- function(sd) {
  expected <- "(1 | id)"
  if (
    !is.numeric(sd) ||
      length(sd) != 1L ||
      !is.finite(sd) ||
      sd <= 0
  ) {
    stop("`sd` must be one positive finite number.", call. = FALSE)
  }
  current <- names(sd)
  if (is.null(current) || !nzchar(current)) {
    names(sd) <- expected
    return(sd)
  }
  if (!identical(current, expected)) {
    stop("`sd` must be unnamed or named with ", expected, ".", call. = FALSE)
  }
  sd
}
