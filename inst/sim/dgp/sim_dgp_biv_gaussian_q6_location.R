phase18_biv_gaussian_q6_location_conditions <- function(
  n_id = c(72L),
  n_each = c(5L),
  beta_mu1_intercept = 0.12,
  beta_mu1_x = 0.38,
  beta_mu1_z = -0.24,
  beta_mu2_intercept = -0.16,
  beta_mu2_x = -0.30,
  beta_mu2_z = 0.22,
  sigma1 = 0.36,
  sigma2 = 0.43,
  sd_mu1_intercept = 0.30,
  sd_mu1_x = 0.10,
  sd_mu1_z = 0.08,
  sd_mu2_intercept = 0.32,
  sd_mu2_x = 0.10,
  sd_mu2_z = 0.08,
  cor_mu1_intercept_mu1_x = 0.02,
  cor_mu1_intercept_mu1_z = 0.02,
  cor_mu1_intercept_mu2_intercept = 0.04,
  cor_mu1_intercept_mu2_x = 0,
  cor_mu1_intercept_mu2_z = 0,
  cor_mu1_x_mu1_z = 0.02,
  cor_mu1_x_mu2_intercept = 0,
  cor_mu1_x_mu2_x = 0.03,
  cor_mu1_x_mu2_z = 0,
  cor_mu1_z_mu2_intercept = 0,
  cor_mu1_z_mu2_x = 0,
  cor_mu1_z_mu2_z = 0.03,
  cor_mu2_intercept_mu2_x = 0.02,
  cor_mu2_intercept_mu2_z = 0.02,
  cor_mu2_x_mu2_z = 0.02,
  residual_rho = 0.05
) {
  conditions <- expand.grid(
    n_id = as.integer(n_id),
    n_each = as.integer(n_each),
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  conditions$beta_mu1_intercept <- beta_mu1_intercept
  conditions$beta_mu1_x <- beta_mu1_x
  conditions$beta_mu1_z <- beta_mu1_z
  conditions$beta_mu2_intercept <- beta_mu2_intercept
  conditions$beta_mu2_x <- beta_mu2_x
  conditions$beta_mu2_z <- beta_mu2_z
  conditions$sigma1 <- sigma1
  conditions$sigma2 <- sigma2
  conditions$sd_mu1_intercept <- sd_mu1_intercept
  conditions$sd_mu1_x <- sd_mu1_x
  conditions$sd_mu1_z <- sd_mu1_z
  conditions$sd_mu2_intercept <- sd_mu2_intercept
  conditions$sd_mu2_x <- sd_mu2_x
  conditions$sd_mu2_z <- sd_mu2_z
  conditions$cor_mu1_intercept_mu1_x <- cor_mu1_intercept_mu1_x
  conditions$cor_mu1_intercept_mu1_z <- cor_mu1_intercept_mu1_z
  conditions$cor_mu1_intercept_mu2_intercept <-
    cor_mu1_intercept_mu2_intercept
  conditions$cor_mu1_intercept_mu2_x <- cor_mu1_intercept_mu2_x
  conditions$cor_mu1_intercept_mu2_z <- cor_mu1_intercept_mu2_z
  conditions$cor_mu1_x_mu1_z <- cor_mu1_x_mu1_z
  conditions$cor_mu1_x_mu2_intercept <- cor_mu1_x_mu2_intercept
  conditions$cor_mu1_x_mu2_x <- cor_mu1_x_mu2_x
  conditions$cor_mu1_x_mu2_z <- cor_mu1_x_mu2_z
  conditions$cor_mu1_z_mu2_intercept <- cor_mu1_z_mu2_intercept
  conditions$cor_mu1_z_mu2_x <- cor_mu1_z_mu2_x
  conditions$cor_mu1_z_mu2_z <- cor_mu1_z_mu2_z
  conditions$cor_mu2_intercept_mu2_x <- cor_mu2_intercept_mu2_x
  conditions$cor_mu2_intercept_mu2_z <- cor_mu2_intercept_mu2_z
  conditions$cor_mu2_x_mu2_z <- cor_mu2_x_mu2_z
  conditions$residual_rho <- residual_rho
  conditions
}

phase18_biv_gaussian_q6_location_sd_names <- function() {
  c(
    "mu1:(1 + x + z | p | id):(Intercept)",
    "mu1:(1 + x + z | p | id):x",
    "mu1:(1 + x + z | p | id):z",
    "mu2:(1 + x + z | p | id):(Intercept)",
    "mu2:(1 + x + z | p | id):x",
    "mu2:(1 + x + z | p | id):z"
  )
}

phase18_biv_gaussian_q6_location_cor_names <- function() {
  c(
    "cor(mu1:(Intercept),mu1:x | p | id)",
    "cor(mu1:(Intercept),mu1:z | p | id)",
    "cor(mu1:(Intercept),mu2:(Intercept) | p | id)",
    "cor(mu1:(Intercept),mu2:x | p | id)",
    "cor(mu1:(Intercept),mu2:z | p | id)",
    "cor(mu1:x,mu1:z | p | id)",
    "cor(mu1:x,mu2:(Intercept) | p | id)",
    "cor(mu1:x,mu2:x | p | id)",
    "cor(mu1:x,mu2:z | p | id)",
    "cor(mu1:z,mu2:(Intercept) | p | id)",
    "cor(mu1:z,mu2:x | p | id)",
    "cor(mu1:z,mu2:z | p | id)",
    "cor(mu2:(Intercept),mu2:x | p | id)",
    "cor(mu2:(Intercept),mu2:z | p | id)",
    "cor(mu2:x,mu2:z | p | id)"
  )
}

phase18_biv_gaussian_q6_named_vector <- function(
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

phase18_biv_gaussian_q6_location_cor_matrix <- function(cor_mu) {
  cor_mu <- phase18_biv_gaussian_q6_named_vector(
    cor_mu,
    phase18_biv_gaussian_q6_location_cor_names(),
    "cor_mu"
  )
  for (name in names(cor_mu)) {
    assert_phase18_correlation(cor_mu[[name]], paste0("cor_mu[", name, "]"))
  }

  corr <- diag(6L)
  corr[lower.tri(corr)] <- unname(cor_mu)
  corr <- corr + t(corr) - diag(6L)
  tryCatch(
    chol(corr),
    error = function(e) {
      stop(
        "`cor_mu` must define a positive-definite q=6 correlation matrix.",
        call. = FALSE
      )
    }
  )
  corr
}

phase18_dgp_biv_gaussian_q6_location <- function(
  n_id,
  n_each,
  beta_mu1 = c("(Intercept)" = 0.12, x = 0.38, z = -0.24),
  beta_mu2 = c("(Intercept)" = -0.16, x = -0.30, z = 0.22),
  sigma = c(sigma1 = 0.36, sigma2 = 0.43),
  sd_mu = c(
    "mu1:(1 + x + z | p | id):(Intercept)" = 0.30,
    "mu1:(1 + x + z | p | id):x" = 0.10,
    "mu1:(1 + x + z | p | id):z" = 0.08,
    "mu2:(1 + x + z | p | id):(Intercept)" = 0.32,
    "mu2:(1 + x + z | p | id):x" = 0.10,
    "mu2:(1 + x + z | p | id):z" = 0.08
  ),
  cor_mu = c(
    "cor(mu1:(Intercept),mu1:x | p | id)" = 0.02,
    "cor(mu1:(Intercept),mu1:z | p | id)" = 0.02,
    "cor(mu1:(Intercept),mu2:(Intercept) | p | id)" = 0.04,
    "cor(mu1:(Intercept),mu2:x | p | id)" = 0,
    "cor(mu1:(Intercept),mu2:z | p | id)" = 0,
    "cor(mu1:x,mu1:z | p | id)" = 0.02,
    "cor(mu1:x,mu2:(Intercept) | p | id)" = 0,
    "cor(mu1:x,mu2:x | p | id)" = 0.03,
    "cor(mu1:x,mu2:z | p | id)" = 0,
    "cor(mu1:z,mu2:(Intercept) | p | id)" = 0,
    "cor(mu1:z,mu2:x | p | id)" = 0,
    "cor(mu1:z,mu2:z | p | id)" = 0.03,
    "cor(mu2:(Intercept),mu2:x | p | id)" = 0.02,
    "cor(mu2:(Intercept),mu2:z | p | id)" = 0.02,
    "cor(mu2:x,mu2:z | p | id)" = 0.02
  ),
  residual_rho = 0.05,
  seed = NULL,
  cell_id = NA_character_,
  replicate = NA_integer_
) {
  assert_positive_whole_number(n_id, "n_id")
  assert_positive_whole_number(n_each, "n_each")
  beta_mu1 <- phase18_biv_gaussian_q6_named_vector(
    beta_mu1,
    c("(Intercept)", "x", "z"),
    "beta_mu1"
  )
  beta_mu2 <- phase18_biv_gaussian_q6_named_vector(
    beta_mu2,
    c("(Intercept)", "x", "z"),
    "beta_mu2"
  )
  sigma <- phase18_named_pair(sigma, c("sigma1", "sigma2"), "sigma")
  if (any(sigma <= 0)) {
    stop("`sigma` values must be positive.", call. = FALSE)
  }
  sd_mu <- phase18_biv_gaussian_q6_named_vector(
    sd_mu,
    phase18_biv_gaussian_q6_location_sd_names(),
    "sd_mu"
  )
  if (any(sd_mu <= 0)) {
    stop("`sd_mu` values must be positive.", call. = FALSE)
  }
  cor_mu <- phase18_biv_gaussian_q6_named_vector(
    cor_mu,
    phase18_biv_gaussian_q6_location_cor_names(),
    "cor_mu"
  )
  corr <- phase18_biv_gaussian_q6_location_cor_matrix(cor_mu)
  assert_phase18_correlation(residual_rho, "residual_rho")

  draw <- function() {
    id <- factor(rep(seq_len(n_id), each = n_each))
    n <- length(id)
    x_base <- seq(-1, 1, length.out = n_each)
    x <- rep(x_base, times = n_id)
    z <- rep(x_base^2 - mean(x_base^2), times = n_id)

    random_normal <- matrix(stats::rnorm(n_id * 6L), n_id, 6L)
    b <- sweep(random_normal %*% chol(corr), 2L, sd_mu, `*`)

    e1 <- stats::rnorm(n)
    e2 <- residual_rho * e1 + sqrt(1 - residual_rho^2) * stats::rnorm(n)
    mu1 <- unname(
      beta_mu1[["(Intercept)"]] +
        beta_mu1[["x"]] * x +
        beta_mu1[["z"]] * z +
        b[id, 1L] +
        b[id, 2L] * x +
        b[id, 3L] * z
    )
    mu2 <- unname(
      beta_mu2[["(Intercept)"]] +
        beta_mu2[["x"]] * x +
        beta_mu2[["z"]] * z +
        b[id, 4L] +
        b[id, 5L] * x +
        b[id, 6L] * z
    )

    dat <- data.frame(
      y1 = mu1 + sigma[["sigma1"]] * e1,
      y2 = mu2 + sigma[["sigma2"]] * e2,
      x = x,
      z = z,
      id = id,
      mu1 = mu1,
      mu2 = mu2,
      sigma1 = sigma[["sigma1"]],
      sigma2 = sigma[["sigma2"]],
      cell_id = cell_id,
      replicate = replicate,
      stringsAsFactors = FALSE
    )
    attr(dat, "truth") <- list(
      surface = "biv_gaussian_q6_location",
      beta_mu1 = beta_mu1,
      beta_mu2 = beta_mu2,
      sigma = sigma,
      sd_mu = sd_mu,
      cor_mu = cor_mu,
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
