phase18_bounded_response_mu_ri_conditions <- function(
  family = c("beta", "beta_binomial"),
  n_group = c(32L, 48L),
  n_per_group = c(8L, 10L),
  trial_min = c(12L, 20L),
  trial_max = c(20L, 32L),
  beta_mu_intercept = -0.25,
  beta_mu_x = 0.60,
  beta_sigma_intercept = c(-0.95, -0.70),
  beta_sigma_z = c(0, 0.18),
  sd_intercept = c(0.35, 0.55),
  rho_xz = c(0, 0.40)
) {
  family <- phase18_bounded_response_mu_ri_family(
    family,
    several.ok = TRUE
  )
  if (length(trial_min) != length(trial_max)) {
    stop(
      "`trial_min` and `trial_max` must have the same length.",
      call. = FALSE
    )
  }
  trial_min <- as.integer(trial_min)
  trial_max <- as.integer(trial_max)
  bad_trials <- is.na(trial_min) |
    is.na(trial_max) |
    trial_min < 1L |
    trial_max < trial_min
  if (any(bad_trials)) {
    stop(
      "`trial_min` and `trial_max` must define positive integer ranges.",
      call. = FALSE
    )
  }

  base <- expand.grid(
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

  pieces <- list()
  if ("beta" %in% family) {
    beta_rows <- base
    beta_rows$family <- "beta"
    beta_rows$trial_min <- NA_integer_
    beta_rows$trial_max <- NA_integer_
    pieces$beta <- beta_rows
  }
  if ("beta_binomial" %in% family) {
    trial_bands <- data.frame(
      trial_min = trial_min,
      trial_max = trial_max
    )
    beta_binomial_rows <- merge(
      base,
      trial_bands,
      all = TRUE,
      sort = FALSE
    )
    beta_binomial_rows$family <- "beta_binomial"
    pieces$beta_binomial <- beta_binomial_rows
  }

  out <- do.call(rbind, pieces)
  row.names(out) <- NULL
  out[c(
    "family",
    "n_group",
    "n_per_group",
    "trial_min",
    "trial_max",
    "beta_mu_intercept",
    "beta_mu_x",
    "beta_sigma_intercept",
    "beta_sigma_z",
    "sd_intercept",
    "rho_xz"
  )]
}

phase18_dgp_bounded_response_mu_ri <- function(
  n_group,
  n_per_group,
  family = c("beta", "beta_binomial"),
  beta_mu = c("(Intercept)" = -0.25, x = 0.60),
  beta_sigma = c("(Intercept)" = -0.95, z = 0.18),
  sd = c("(1 | id)" = 0.45),
  rho_xz = 0,
  trial_min = 12L,
  trial_max = 20L,
  seed = NULL,
  cell_id = NA_character_,
  replicate = NA_integer_
) {
  assert_positive_whole_number(n_group, "n_group")
  assert_positive_whole_number(n_per_group, "n_per_group")
  family <- phase18_bounded_response_mu_ri_family(family)
  beta_mu <- phase18_named_pair(beta_mu, c("(Intercept)", "x"), "beta_mu")
  beta_sigma <- phase18_named_pair(
    beta_sigma,
    c("(Intercept)", "z"),
    "beta_sigma"
  )
  sd <- phase18_bounded_response_mu_ri_sd(sd)
  assert_phase18_correlation(rho_xz, "rho_xz")
  if (identical(family, "beta_binomial")) {
    phase18_assert_trial_range(trial_min, trial_max)
  }

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
    mu <- stats::plogis(eta_mu)
    sigma <- exp(eta_sigma)
    phi <- 1 / sigma^2
    alpha <- mu * phi
    beta_shape <- (1 - mu) * phi

    if (identical(family, "beta")) {
      dat <- data.frame(
        prop = stats::rbeta(n, shape1 = alpha, shape2 = beta_shape),
        x = x,
        z = z,
        id = id,
        eta_mu = eta_mu,
        eta_sigma = eta_sigma,
        mu = mu,
        sigma = sigma,
        phi = phi,
        alpha = alpha,
        beta_shape = beta_shape,
        family = family,
        cell_id = cell_id,
        replicate = replicate,
        stringsAsFactors = FALSE
      )
    } else {
      trials <- sample(seq.int(trial_min, trial_max), n, replace = TRUE)
      latent_p <- stats::rbeta(n, shape1 = alpha, shape2 = beta_shape)
      success <- stats::rbinom(n, size = trials, prob = latent_p)
      failure <- trials - success
      dat <- data.frame(
        success = success,
        failure = failure,
        trials = trials,
        observed_prop = success / trials,
        latent_p = latent_p,
        x = x,
        z = z,
        id = id,
        eta_mu = eta_mu,
        eta_sigma = eta_sigma,
        mu = mu,
        sigma = sigma,
        phi = phi,
        alpha = alpha,
        beta_shape = beta_shape,
        family = family,
        cell_id = cell_id,
        replicate = replicate,
        stringsAsFactors = FALSE
      )
    }
    attr(dat, "truth") <- list(
      surface = "bounded_response_mu_random_intercept",
      family = family,
      beta_mu = beta_mu,
      beta_sigma = beta_sigma,
      sd = sd,
      n_group = n_group,
      n_per_group = n_per_group,
      rho_xz = rho_xz,
      trial_min = if (identical(family, "beta_binomial")) {
        trial_min
      } else {
        NA_integer_
      },
      trial_max = if (identical(family, "beta_binomial")) {
        trial_max
      } else {
        NA_integer_
      }
    )
    dat
  }

  if (is.null(seed)) {
    draw()
  } else {
    phase18_with_seed(seed, draw)
  }
}

phase18_bounded_response_mu_ri_family <- function(
  family,
  several.ok = FALSE
) {
  choices <- c("beta", "beta_binomial")
  if (
    !is.character(family) ||
      length(family) == 0L ||
      anyNA(family) ||
      any(!nzchar(family)) ||
      any(!family %in% choices)
  ) {
    stop(
      "`family` must be ",
      if (several.ok) "one or more of " else "one of ",
      paste(choices, collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  if (!several.ok && length(family) != 1L) {
    stop(
      "`family` must be one of ",
      paste(choices, collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  unique(family)
}

phase18_bounded_response_mu_ri_sd <- function(sd) {
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
