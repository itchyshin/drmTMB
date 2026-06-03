phase18_biv_gaussian_q4_location_conditions <- function(
  n_id = c(36L),
  n_each = c(5L),
  beta_mu1_intercept = 0.15,
  beta_mu1_x = 0.42,
  beta_mu2_intercept = -0.18,
  beta_mu2_x = -0.32,
  sigma1 = 0.36,
  sigma2 = 0.43,
  sd_mu1_intercept = 0.46,
  sd_mu1_x = 0.18,
  sd_mu2_intercept = 0.50,
  sd_mu2_x = 0.18,
  cor_mu1_intercept_mu1_x = 0.08,
  cor_mu1_intercept_mu2_intercept = 0.08,
  cor_mu1_intercept_mu2_x = 0,
  cor_mu1_x_mu2_intercept = 0,
  cor_mu1_x_mu2_x = 0.08,
  cor_mu2_intercept_mu2_x = 0.08,
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
  conditions$sd_mu1_intercept <- sd_mu1_intercept
  conditions$sd_mu1_x <- sd_mu1_x
  conditions$sd_mu2_intercept <- sd_mu2_intercept
  conditions$sd_mu2_x <- sd_mu2_x
  conditions$cor_mu1_intercept_mu1_x <- cor_mu1_intercept_mu1_x
  conditions$cor_mu1_intercept_mu2_intercept <-
    cor_mu1_intercept_mu2_intercept
  conditions$cor_mu1_intercept_mu2_x <- cor_mu1_intercept_mu2_x
  conditions$cor_mu1_x_mu2_intercept <- cor_mu1_x_mu2_intercept
  conditions$cor_mu1_x_mu2_x <- cor_mu1_x_mu2_x
  conditions$cor_mu2_intercept_mu2_x <- cor_mu2_intercept_mu2_x
  conditions$residual_rho <- residual_rho
  conditions
}

phase18_biv_gaussian_q4_location_sd_names <- function() {
  c(
    "mu1:(1 + x | p | id):(Intercept)",
    "mu1:(1 + x | p | id):x",
    "mu2:(1 + x | p | id):(Intercept)",
    "mu2:(1 + x | p | id):x"
  )
}

phase18_biv_gaussian_q4_location_cor_names <- function() {
  c(
    "cor(mu1:(Intercept),mu1:x | p | id)",
    "cor(mu1:(Intercept),mu2:(Intercept) | p | id)",
    "cor(mu1:(Intercept),mu2:x | p | id)",
    "cor(mu1:x,mu2:(Intercept) | p | id)",
    "cor(mu1:x,mu2:x | p | id)",
    "cor(mu2:(Intercept),mu2:x | p | id)"
  )
}

phase18_biv_gaussian_q4_named_vector <- function(
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

phase18_biv_gaussian_q4_location_cor_matrix <- function(cor_mu) {
  cor_mu <- phase18_biv_gaussian_q4_named_vector(
    cor_mu,
    phase18_biv_gaussian_q4_location_cor_names(),
    "cor_mu"
  )
  for (name in names(cor_mu)) {
    assert_phase18_correlation(cor_mu[[name]], paste0("cor_mu[", name, "]"))
  }

  corr <- diag(4L)
  corr[lower.tri(corr)] <- unname(cor_mu)
  corr <- corr + t(corr) - diag(4L)
  tryCatch(
    chol(corr),
    error = function(e) {
      stop(
        "`cor_mu` must define a positive-definite q=4 correlation matrix.",
        call. = FALSE
      )
    }
  )
  corr
}

phase18_dgp_biv_gaussian_q4_location <- function(
  n_id,
  n_each,
  beta_mu1 = c("(Intercept)" = 0.15, x = 0.42),
  beta_mu2 = c("(Intercept)" = -0.18, x = -0.32),
  sigma = c(sigma1 = 0.36, sigma2 = 0.43),
  sd_mu = c(
    "mu1:(1 + x | p | id):(Intercept)" = 0.46,
    "mu1:(1 + x | p | id):x" = 0.24,
    "mu2:(1 + x | p | id):(Intercept)" = 0.50,
    "mu2:(1 + x | p | id):x" = 0.20
  ),
  cor_mu = c(
    "cor(mu1:(Intercept),mu1:x | p | id)" = 0.22,
    "cor(mu1:(Intercept),mu2:(Intercept) | p | id)" = 0.28,
    "cor(mu1:(Intercept),mu2:x | p | id)" = -0.10,
    "cor(mu1:x,mu2:(Intercept) | p | id)" = 0.06,
    "cor(mu1:x,mu2:x | p | id)" = 0.24,
    "cor(mu2:(Intercept),mu2:x | p | id)" = 0.18
  ),
  residual_rho = 0.12,
  seed = NULL,
  cell_id = NA_character_,
  replicate = NA_integer_
) {
  assert_positive_whole_number(n_id, "n_id")
  assert_positive_whole_number(n_each, "n_each")
  beta_mu1 <- phase18_named_pair(beta_mu1, c("(Intercept)", "x"), "beta_mu1")
  beta_mu2 <- phase18_named_pair(beta_mu2, c("(Intercept)", "x"), "beta_mu2")
  sigma <- phase18_named_pair(sigma, c("sigma1", "sigma2"), "sigma")
  if (any(sigma <= 0)) {
    stop("`sigma` values must be positive.", call. = FALSE)
  }
  sd_mu <- phase18_biv_gaussian_q4_named_vector(
    sd_mu,
    phase18_biv_gaussian_q4_location_sd_names(),
    "sd_mu"
  )
  if (any(sd_mu <= 0)) {
    stop("`sd_mu` values must be positive.", call. = FALSE)
  }
  cor_mu <- phase18_biv_gaussian_q4_named_vector(
    cor_mu,
    phase18_biv_gaussian_q4_location_cor_names(),
    "cor_mu"
  )
  corr <- phase18_biv_gaussian_q4_location_cor_matrix(cor_mu)
  assert_phase18_correlation(residual_rho, "residual_rho")

  draw <- function() {
    id <- factor(rep(seq_len(n_id), each = n_each))
    n <- length(id)
    x <- rep(seq(-1, 1, length.out = n_each), times = n_id)

    z <- matrix(stats::rnorm(n_id * 4L), n_id, 4L)
    b <- sweep(z %*% chol(corr), 2L, sd_mu, `*`)

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
      y1 = mu1 + sigma[["sigma1"]] * e1,
      y2 = mu2 + sigma[["sigma2"]] * e2,
      x = x,
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
      surface = "biv_gaussian_q4_location",
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
