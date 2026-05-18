phase18_poisson_mu_re_conditions <- function(
  n_group = c(36L, 48L),
  n_per_group = c(9L, 12L),
  sd_intercept = 0.40,
  sd_x = 0.30,
  beta_mu_intercept = 0.30,
  beta_mu_x = -0.25
) {
  conditions <- expand.grid(
    n_group = as.integer(n_group),
    n_per_group = as.integer(n_per_group),
    sd_intercept = sd_intercept,
    sd_x = sd_x,
    beta_mu_intercept = beta_mu_intercept,
    beta_mu_x = beta_mu_x,
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  conditions
}

phase18_dgp_poisson_mu_re <- function(
  n_group,
  n_per_group,
  beta_mu = c("(Intercept)" = 0.30, x = -0.25),
  sd = c("(Intercept)" = 0.40, x = 0.30),
  seed = NULL,
  cell_id = NA_character_,
  replicate = NA_integer_
) {
  assert_positive_whole_number(n_group, "n_group")
  assert_positive_whole_number(n_per_group, "n_per_group")
  beta_mu <- phase18_named_pair(beta_mu, c("(Intercept)", "x"), "beta_mu")
  sd <- phase18_named_pair(sd, c("(Intercept)", "x"), "sd")
  if (any(sd <= 0)) {
    stop("`sd` values must be positive.", call. = FALSE)
  }

  draw <- function() {
    n <- n_group * n_per_group
    id <- factor(rep(seq_len(n_group), each = n_per_group))
    x <- rep(seq(-1, 1, length.out = n_per_group), times = n_group)
    b0 <- stats::rnorm(n_group, sd = sd[["(Intercept)"]])
    bx <- stats::rnorm(n_group, sd = sd[["x"]])

    eta <- unname(
      beta_mu[["(Intercept)"]] +
        beta_mu[["x"]] * x +
        b0[id] +
        bx[id] * x
    )
    mu <- exp(eta)
    count <- stats::rpois(n, lambda = mu)

    dat <- data.frame(
      count = count,
      x = x,
      id = id,
      eta_mu = eta,
      mu = mu,
      cell_id = cell_id,
      replicate = replicate,
      stringsAsFactors = FALSE
    )
    attr(dat, "truth") <- list(
      surface = "poisson_mu_random_effect",
      beta_mu = beta_mu,
      sd = stats::setNames(sd, c("(1 | id)", "(0 + x | id)")),
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
