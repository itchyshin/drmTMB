phase18_student_mu_ri_conditions <- function(
  n_group = c(32L, 44L),
  n_per_group = c(8L, 10L),
  beta_mu_intercept = 0.20,
  beta_mu_x = 0.48,
  beta_sigma_intercept = -0.42,
  beta_sigma_z = c(0, 0.20),
  beta_nu_intercept = log(c(5, 9)),
  sd_intercept = c(0.35, 0.55),
  rho_xz = c(0, 0.40)
) {
  base <- expand.grid(
    n_group = as.integer(n_group),
    n_per_group = as.integer(n_per_group),
    beta_sigma_intercept = beta_sigma_intercept,
    beta_sigma_z = beta_sigma_z,
    beta_nu_intercept = beta_nu_intercept,
    sd_intercept = sd_intercept,
    rho_xz = rho_xz,
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  base$beta_mu_intercept <- beta_mu_intercept
  base$beta_mu_x <- beta_mu_x
  base[c(
    "n_group",
    "n_per_group",
    "beta_mu_intercept",
    "beta_mu_x",
    "beta_sigma_intercept",
    "beta_sigma_z",
    "beta_nu_intercept",
    "sd_intercept",
    "rho_xz"
  )]
}

phase18_dgp_student_mu_ri <- function(
  n_group,
  n_per_group,
  beta_mu = c("(Intercept)" = 0.20, x = 0.48),
  beta_sigma = c("(Intercept)" = -0.42, z = 0.18),
  beta_nu = c("(Intercept)" = log(7)),
  sd = c("(1 | id)" = 0.45),
  rho_xz = 0,
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
  beta_nu <- phase18_student_mu_ri_beta_nu(beta_nu)
  sd <- phase18_student_mu_ri_sd(sd)
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

    mu <- unname(
      beta_mu[["(Intercept)"]] +
        beta_mu[["x"]] * x +
        u_id[id]
    )
    eta_sigma <- unname(
      beta_sigma[["(Intercept)"]] +
        beta_sigma[["z"]] * z
    )
    sigma <- exp(eta_sigma)
    eta_nu <- rep(unname(beta_nu[["(Intercept)"]]), n)
    nu <- 2 + exp(eta_nu)
    y <- mu + sigma * stats::rt(n, df = nu)

    dat <- data.frame(
      y = y,
      x = x,
      z = z,
      id = id,
      mu = mu,
      eta_sigma = eta_sigma,
      sigma = sigma,
      eta_nu = eta_nu,
      nu = nu,
      cell_id = cell_id,
      replicate = replicate,
      stringsAsFactors = FALSE
    )
    attr(dat, "truth") <- list(
      surface = "student_mu_random_intercept",
      beta_mu = beta_mu,
      beta_sigma = beta_sigma,
      beta_nu = beta_nu,
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

phase18_student_mu_ri_beta_nu <- function(beta_nu) {
  expected <- "(Intercept)"
  if (
    !is.numeric(beta_nu) ||
      length(beta_nu) != 1L ||
      !is.finite(beta_nu)
  ) {
    stop("`beta_nu` must be one finite number.", call. = FALSE)
  }
  current <- names(beta_nu)
  if (is.null(current) || !nzchar(current)) {
    names(beta_nu) <- expected
    return(beta_nu)
  }
  if (!identical(current, expected)) {
    stop(
      "`beta_nu` must be unnamed or named with ",
      expected,
      ".",
      call. = FALSE
    )
  }
  beta_nu
}

phase18_student_mu_ri_sd <- function(sd) {
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
