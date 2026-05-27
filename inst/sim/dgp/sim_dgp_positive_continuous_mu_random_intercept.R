phase18_positive_continuous_mu_ri_conditions <- function(
  family = c("lognormal", "gamma"),
  n_group = c(32L, 44L),
  n_per_group = c(8L, 10L),
  beta_mu_intercept = 0.20,
  beta_mu_x = 0.45,
  beta_sigma_intercept = c(-0.75, -0.45),
  beta_sigma_z = c(0, 0.25),
  sd_intercept = c(0.35, 0.55),
  rho_xz = c(0, 0.40)
) {
  family <- phase18_positive_continuous_fe_family(
    family,
    several.ok = TRUE
  )
  base <- expand.grid(
    family = family,
    n_group = as.integer(n_group),
    n_per_group = as.integer(n_per_group),
    beta_sigma_intercept = beta_sigma_intercept,
    beta_sigma_z = beta_sigma_z,
    sd_intercept = sd_intercept,
    rho_xz = rho_xz,
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  base$beta_mu_intercept <- beta_mu_intercept
  base$beta_mu_x <- beta_mu_x
  base[c(
    "family",
    "n_group",
    "n_per_group",
    "beta_mu_intercept",
    "beta_mu_x",
    "beta_sigma_intercept",
    "beta_sigma_z",
    "sd_intercept",
    "rho_xz"
  )]
}

phase18_dgp_positive_continuous_mu_ri <- function(
  n_group,
  n_per_group,
  family = c("lognormal", "gamma"),
  beta_mu = c("(Intercept)" = 0.20, x = 0.45),
  beta_sigma = c("(Intercept)" = -0.75, z = 0.25),
  sd = c("(1 | id)" = 0.45),
  rho_xz = 0,
  seed = NULL,
  cell_id = NA_character_,
  replicate = NA_integer_
) {
  assert_positive_whole_number(n_group, "n_group")
  assert_positive_whole_number(n_per_group, "n_per_group")
  family <- phase18_positive_continuous_fe_family(family)
  beta_mu <- phase18_named_pair(beta_mu, c("(Intercept)", "x"), "beta_mu")
  beta_sigma <- phase18_named_pair(
    beta_sigma,
    c("(Intercept)", "z"),
    "beta_sigma"
  )
  sd <- phase18_positive_continuous_mu_ri_sd(sd)
  assert_phase18_correlation(rho_xz, "rho_xz")

  draw <- function() {
    n <- n_group * n_per_group
    id <- factor(rep(seq_len(n_group), each = n_per_group))
    x <- stats::rnorm(n)
    z_noise <- stats::rnorm(n)
    z <- rho_xz * x + sqrt(1 - rho_xz^2) * z_noise
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
    sigma <- exp(eta_sigma)

    if (identical(family, "lognormal")) {
      mu <- eta_mu
      response_mean <- exp(mu + 0.5 * sigma^2)
      y <- stats::rlnorm(n, meanlog = mu, sdlog = sigma)
    } else {
      mu <- exp(eta_mu)
      response_mean <- mu
      y <- stats::rgamma(n, shape = 1 / sigma^2, scale = mu * sigma^2)
    }

    dat <- data.frame(
      y = y,
      x = x,
      z = z,
      id = id,
      eta_mu = eta_mu,
      eta_sigma = eta_sigma,
      mu = mu,
      sigma = sigma,
      response_mean = response_mean,
      family = family,
      cell_id = cell_id,
      replicate = replicate,
      stringsAsFactors = FALSE
    )
    attr(dat, "truth") <- list(
      surface = "positive_continuous_mu_random_intercept",
      family = family,
      beta_mu = beta_mu,
      beta_sigma = beta_sigma,
      sd = sd,
      n_group = n_group,
      n_per_group = n_per_group,
      rho_xz = rho_xz
    )
    dat
  }

  if (is.null(seed)) {
    draw()
  } else {
    phase18_with_seed(seed, draw)
  }
}

phase18_positive_continuous_mu_ri_sd <- function(sd) {
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
