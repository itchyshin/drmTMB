phase18_biv_gaussian_q8_endpoint_conditions <- function(
  n_id = c(48L),
  n_each = c(10L),
  beta_mu1_intercept = 0.12,
  beta_mu1_x = 0.28,
  beta_mu2_intercept = -0.10,
  beta_mu2_x = -0.22,
  sigma1 = 0.42,
  sigma2 = 0.48,
  beta_sigma1_x = 0.05,
  beta_sigma2_x = -0.04,
  sd_mu1_intercept = 0.34,
  sd_mu1_x = 0.16,
  sd_mu2_intercept = 0.36,
  sd_mu2_x = 0.15,
  sd_sigma1_intercept = 0.16,
  sd_sigma1_x = 0.07,
  sd_sigma2_intercept = 0.17,
  sd_sigma2_x = 0.06,
  cor_base = 0.02,
  cor_mu_intercept = 0.12,
  cor_mu_x = 0.10,
  cor_sigma_intercept = 0.09,
  cor_sigma_x = 0.08,
  cor_mu1_sigma1_intercept = -0.06,
  cor_mu1_sigma1_x = 0.05,
  residual_rho = 0.08
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
  conditions$beta_sigma1_x <- beta_sigma1_x
  conditions$beta_sigma2_x <- beta_sigma2_x
  conditions$sd_mu1_intercept <- sd_mu1_intercept
  conditions$sd_mu1_x <- sd_mu1_x
  conditions$sd_mu2_intercept <- sd_mu2_intercept
  conditions$sd_mu2_x <- sd_mu2_x
  conditions$sd_sigma1_intercept <- sd_sigma1_intercept
  conditions$sd_sigma1_x <- sd_sigma1_x
  conditions$sd_sigma2_intercept <- sd_sigma2_intercept
  conditions$sd_sigma2_x <- sd_sigma2_x
  conditions$cor_base <- cor_base
  conditions$cor_mu_intercept <- cor_mu_intercept
  conditions$cor_mu_x <- cor_mu_x
  conditions$cor_sigma_intercept <- cor_sigma_intercept
  conditions$cor_sigma_x <- cor_sigma_x
  conditions$cor_mu1_sigma1_intercept <- cor_mu1_sigma1_intercept
  conditions$cor_mu1_sigma1_x <- cor_mu1_sigma1_x
  conditions$residual_rho <- residual_rho
  conditions
}

phase18_biv_gaussian_q8_endpoint_sd_mu_names <- function() {
  c(
    "mu1:(1 + x | p | id):(Intercept)",
    "mu1:(1 + x | p | id):x",
    "mu2:(1 + x | p | id):(Intercept)",
    "mu2:(1 + x | p | id):x"
  )
}

phase18_biv_gaussian_q8_endpoint_sd_sigma_names <- function() {
  c(
    "sigma1:(1 + x | p | id):(Intercept)",
    "sigma1:(1 + x | p | id):x",
    "sigma2:(1 + x | p | id):(Intercept)",
    "sigma2:(1 + x | p | id):x"
  )
}

phase18_biv_gaussian_q8_endpoint_member_dpars <- function() {
  c("mu1", "mu1", "mu2", "mu2", "sigma1", "sigma1", "sigma2", "sigma2")
}

phase18_biv_gaussian_q8_endpoint_member_coefs <- function() {
  rep(c("(Intercept)", "x"), times = 4L)
}

phase18_biv_gaussian_q8_endpoint_cor_label <- function(
  from_dpar,
  from_coef,
  to_dpar,
  to_coef
) {
  paste0(
    "cor(",
    from_dpar,
    ":",
    from_coef,
    ",",
    to_dpar,
    ":",
    to_coef,
    " | p | id)"
  )
}

phase18_biv_gaussian_q8_endpoint_cor_names <- function() {
  dpar <- phase18_biv_gaussian_q8_endpoint_member_dpars()
  coef <- phase18_biv_gaussian_q8_endpoint_member_coefs()
  pairs <- utils::combn(seq_along(dpar), 2L)
  vapply(
    seq_len(ncol(pairs)),
    function(j) {
      pair <- pairs[, j]
      phase18_biv_gaussian_q8_endpoint_cor_label(
        dpar[[pair[[1L]]]],
        coef[[pair[[1L]]]],
        dpar[[pair[[2L]]]],
        coef[[pair[[2L]]]]
      )
    },
    character(1L)
  )
}

phase18_biv_gaussian_q8_endpoint_named_vector <- function(
  x,
  expected,
  name
) {
  if (!is.numeric(x) || length(x) != length(expected) || any(!is.finite(x))) {
    stop(
      "`",
      name,
      "` must be a finite numeric vector of length ",
      length(expected),
      ".",
      call. = FALSE
    )
  }
  current <- names(x)
  if (is.null(current) || any(!nzchar(current))) {
    names(x) <- expected
    return(x)
  }
  if (!setequal(current, expected)) {
    stop(
      "`",
      name,
      "` must be unnamed or named with ",
      paste(expected, collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  x[expected]
}

phase18_biv_gaussian_q8_endpoint_correlations <- function(
  cor_base = 0.02,
  cor_mu_intercept = 0.12,
  cor_mu_x = 0.10,
  cor_sigma_intercept = 0.09,
  cor_sigma_x = 0.08,
  cor_mu1_sigma1_intercept = -0.06,
  cor_mu1_sigma1_x = 0.05
) {
  out <- stats::setNames(
    rep(cor_base, 28L),
    phase18_biv_gaussian_q8_endpoint_cor_names()
  )
  out[[
    phase18_biv_gaussian_q8_endpoint_cor_label(
      "mu1",
      "(Intercept)",
      "mu2",
      "(Intercept)"
    )
  ]] <- cor_mu_intercept
  out[[
    phase18_biv_gaussian_q8_endpoint_cor_label("mu1", "x", "mu2", "x")
  ]] <- cor_mu_x
  out[[
    phase18_biv_gaussian_q8_endpoint_cor_label(
      "sigma1",
      "(Intercept)",
      "sigma2",
      "(Intercept)"
    )
  ]] <- cor_sigma_intercept
  out[[
    phase18_biv_gaussian_q8_endpoint_cor_label("sigma1", "x", "sigma2", "x")
  ]] <- cor_sigma_x
  out[[
    phase18_biv_gaussian_q8_endpoint_cor_label(
      "mu1",
      "(Intercept)",
      "sigma1",
      "(Intercept)"
    )
  ]] <- cor_mu1_sigma1_intercept
  out[[
    phase18_biv_gaussian_q8_endpoint_cor_label("mu1", "x", "sigma1", "x")
  ]] <- cor_mu1_sigma1_x
  out
}

phase18_biv_gaussian_q8_endpoint_cor_matrix <- function(cor_re_cov) {
  cor_re_cov <- phase18_biv_gaussian_q8_endpoint_named_vector(
    cor_re_cov,
    phase18_biv_gaussian_q8_endpoint_cor_names(),
    "cor_re_cov"
  )
  for (name in names(cor_re_cov)) {
    assert_phase18_correlation(
      cor_re_cov[[name]],
      paste0("cor_re_cov[", name, "]")
    )
  }

  corr <- diag(8L)
  pairs <- utils::combn(seq_len(8L), 2L)
  for (j in seq_len(ncol(pairs))) {
    pair <- pairs[, j]
    corr[pair[[1L]], pair[[2L]]] <- cor_re_cov[[j]]
    corr[pair[[2L]], pair[[1L]]] <- cor_re_cov[[j]]
  }
  tryCatch(
    chol(corr),
    error = function(e) {
      stop(
        "`cor_re_cov` must define a positive-definite q=8 ",
        "correlation matrix.",
        call. = FALSE
      )
    }
  )
  corr
}

phase18_dgp_biv_gaussian_q8_endpoint <- function(
  n_id,
  n_each,
  beta_mu1 = c("(Intercept)" = 0.12, x = 0.28),
  beta_mu2 = c("(Intercept)" = -0.10, x = -0.22),
  beta_sigma1 = c("(Intercept)" = log(0.42), x = 0.05),
  beta_sigma2 = c("(Intercept)" = log(0.48), x = -0.04),
  sd_mu = c(
    "mu1:(1 + x | p | id):(Intercept)" = 0.34,
    "mu1:(1 + x | p | id):x" = 0.16,
    "mu2:(1 + x | p | id):(Intercept)" = 0.36,
    "mu2:(1 + x | p | id):x" = 0.15
  ),
  sd_sigma = c(
    "sigma1:(1 + x | p | id):(Intercept)" = 0.16,
    "sigma1:(1 + x | p | id):x" = 0.07,
    "sigma2:(1 + x | p | id):(Intercept)" = 0.17,
    "sigma2:(1 + x | p | id):x" = 0.06
  ),
  cor_re_cov = phase18_biv_gaussian_q8_endpoint_correlations(),
  residual_rho = 0.08,
  seed = NULL,
  cell_id = NA_character_,
  replicate = NA_integer_
) {
  assert_positive_whole_number(n_id, "n_id")
  assert_positive_whole_number(n_each, "n_each")
  beta_mu1 <- phase18_named_pair(beta_mu1, c("(Intercept)", "x"), "beta_mu1")
  beta_mu2 <- phase18_named_pair(beta_mu2, c("(Intercept)", "x"), "beta_mu2")
  beta_sigma1 <- phase18_named_pair(
    beta_sigma1,
    c("(Intercept)", "x"),
    "beta_sigma1"
  )
  beta_sigma2 <- phase18_named_pair(
    beta_sigma2,
    c("(Intercept)", "x"),
    "beta_sigma2"
  )
  sd_mu <- phase18_biv_gaussian_q8_endpoint_named_vector(
    sd_mu,
    phase18_biv_gaussian_q8_endpoint_sd_mu_names(),
    "sd_mu"
  )
  sd_sigma <- phase18_biv_gaussian_q8_endpoint_named_vector(
    sd_sigma,
    phase18_biv_gaussian_q8_endpoint_sd_sigma_names(),
    "sd_sigma"
  )
  if (any(sd_mu <= 0)) {
    stop("`sd_mu` values must be positive.", call. = FALSE)
  }
  if (any(sd_sigma <= 0)) {
    stop("`sd_sigma` values must be positive.", call. = FALSE)
  }
  cor_re_cov <- phase18_biv_gaussian_q8_endpoint_named_vector(
    cor_re_cov,
    phase18_biv_gaussian_q8_endpoint_cor_names(),
    "cor_re_cov"
  )
  corr <- phase18_biv_gaussian_q8_endpoint_cor_matrix(cor_re_cov)
  assert_phase18_correlation(residual_rho, "residual_rho")

  draw <- function() {
    id <- factor(rep(seq_len(n_id), each = n_each))
    n <- length(id)
    x_base <- seq(-1, 1, length.out = n_each)
    x <- rep(x_base, times = n_id)

    random_normal <- matrix(stats::rnorm(n_id * 8L), n_id, 8L)
    sd_all <- c(sd_mu, sd_sigma)
    b <- sweep(random_normal %*% chol(corr), 2L, sd_all, `*`)

    log_sigma1 <- beta_sigma1[["(Intercept)"]] +
      beta_sigma1[["x"]] * x +
      b[id, 5L] +
      b[id, 6L] * x
    log_sigma2 <- beta_sigma2[["(Intercept)"]] +
      beta_sigma2[["x"]] * x +
      b[id, 7L] +
      b[id, 8L] * x
    sigma1_obs <- exp(log_sigma1)
    sigma2_obs <- exp(log_sigma2)

    e1 <- stats::rnorm(n)
    e2 <- residual_rho * e1 + sqrt(1 - residual_rho^2) * stats::rnorm(n)
    mu1 <- unname(
      beta_mu1[["(Intercept)"]] +
        beta_mu1[["x"]] * x +
        b[id, 1L] +
        b[id, 2L] * x
    )
    mu2 <- unname(
      beta_mu2[["(Intercept)"]] +
        beta_mu2[["x"]] * x +
        b[id, 3L] +
        b[id, 4L] * x
    )

    dat <- data.frame(
      y1 = mu1 + sigma1_obs * e1,
      y2 = mu2 + sigma2_obs * e2,
      x = x,
      id = id,
      mu1 = mu1,
      mu2 = mu2,
      sigma1 = sigma1_obs,
      sigma2 = sigma2_obs,
      cell_id = cell_id,
      replicate = replicate,
      stringsAsFactors = FALSE
    )
    attr(dat, "truth") <- list(
      surface = "biv_gaussian_q8_endpoint",
      beta_mu1 = beta_mu1,
      beta_mu2 = beta_mu2,
      beta_sigma1 = beta_sigma1,
      beta_sigma2 = beta_sigma2,
      sd_mu = sd_mu,
      sd_sigma = sd_sigma,
      cor_re_cov = cor_re_cov,
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
