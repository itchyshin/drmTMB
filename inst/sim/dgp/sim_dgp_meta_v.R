phase18_meta_v_conditions <- function(
  n_study = c(36L, 72L),
  known_v_type = c("vector", "dense"),
  sigma = c(0.15, 0.35),
  sampling_sd = c(0.12, 0.22),
  sampling_rho = c(0, 0.25),
  beta_mu_intercept = 0.20,
  beta_mu_x = 0.45
) {
  conditions <- expand.grid(
    n_study = as.integer(n_study),
    known_v_type = known_v_type,
    sigma = sigma,
    sampling_sd = sampling_sd,
    sampling_rho = sampling_rho,
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  conditions <- conditions[
    conditions$known_v_type == "dense" | conditions$sampling_rho == 0,
    ,
    drop = FALSE
  ]
  row.names(conditions) <- NULL
  conditions$beta_mu_intercept <- beta_mu_intercept
  conditions$beta_mu_x <- beta_mu_x
  conditions
}

phase18_dgp_meta_v <- function(
  n_study,
  known_v_type = c("vector", "dense"),
  beta_mu = c("(Intercept)" = 0.20, x = 0.45),
  sigma = 0.25,
  sampling_sd = 0.16,
  sampling_rho = 0,
  seed = NULL,
  cell_id = NA_character_,
  replicate = NA_integer_
) {
  assert_positive_whole_number(n_study, "n_study")
  known_v_type <- match.arg(known_v_type)
  beta_mu <- phase18_named_pair(beta_mu, c("(Intercept)", "x"), "beta_mu")
  assert_phase18_positive_number(sigma, "sigma")
  assert_phase18_positive_number(sampling_sd, "sampling_sd")
  assert_phase18_correlation(sampling_rho, "sampling_rho")
  if (known_v_type == "vector" && !identical(unname(sampling_rho), 0)) {
    stop(
      "`sampling_rho` must be 0 for vector known-V simulations.",
      call. = FALSE
    )
  }

  draw <- function() {
    x <- stats::rnorm(n_study)
    mu <- unname(beta_mu[["(Intercept)"]] + beta_mu[["x"]] * x)
    V <- phase18_make_meta_v(n_study, known_v_type, sampling_sd, sampling_rho)
    sampling_error <- phase18_draw_known_v_error(V)
    residual_error <- stats::rnorm(n_study, sd = sigma)
    yi <- mu + sampling_error + residual_error

    dat <- data.frame(
      yi = yi,
      x = x,
      mu = mu,
      sampling_var = if (is.matrix(V)) diag(V) else V,
      cell_id = cell_id,
      replicate = replicate,
      stringsAsFactors = FALSE
    )
    attr(dat, "truth") <- list(
      surface = "meta_v",
      beta_mu = beta_mu,
      sigma = sigma,
      n_study = n_study,
      known_v_type = known_v_type,
      sampling_sd = sampling_sd,
      sampling_rho = sampling_rho
    )
    attr(dat, "V") <- V
    dat
  }

  if (is.null(seed)) {
    draw()
  } else {
    phase18_with_seed(seed, draw)
  }
}

phase18_make_meta_v <- function(
  n_study,
  known_v_type,
  sampling_sd,
  sampling_rho
) {
  sd_i <- sampling_sd * exp(seq(-0.25, 0.25, length.out = n_study))
  if (known_v_type == "vector") {
    return(sd_i^2)
  }

  distance <- abs(outer(seq_len(n_study), seq_len(n_study), "-"))
  corr <- sampling_rho^distance
  diag(corr) <- 1
  outer(sd_i, sd_i) * corr
}

phase18_draw_known_v_error <- function(V) {
  if (!is.matrix(V)) {
    return(stats::rnorm(length(V), sd = sqrt(V)))
  }
  drop(t(chol(V)) %*% stats::rnorm(nrow(V)))
}
