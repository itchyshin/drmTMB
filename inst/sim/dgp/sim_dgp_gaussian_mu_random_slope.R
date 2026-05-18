phase18_gaussian_mu_rs_conditions <- function(
  n_group = c(24L, 40L),
  n_per_group = c(7L, 10L),
  sd_intercept = 0.45,
  sd_x1 = 0.30,
  sd_x2 = 0.24,
  cor_intercept_x1 = 0.25,
  cor_intercept_x2 = -0.15,
  cor_x1_x2 = 0.10,
  beta_mu_intercept = 0.20,
  beta_mu_x1 = 0.55,
  beta_mu_x2 = -0.35,
  sigma = 0.70
) {
  conditions <- expand.grid(
    n_group = as.integer(n_group),
    n_per_group = as.integer(n_per_group),
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  conditions$sd_intercept <- sd_intercept
  conditions$sd_x1 <- sd_x1
  conditions$sd_x2 <- sd_x2
  conditions$cor_intercept_x1 <- cor_intercept_x1
  conditions$cor_intercept_x2 <- cor_intercept_x2
  conditions$cor_x1_x2 <- cor_x1_x2
  conditions$beta_mu_intercept <- beta_mu_intercept
  conditions$beta_mu_x1 <- beta_mu_x1
  conditions$beta_mu_x2 <- beta_mu_x2
  conditions$sigma <- sigma
  conditions
}

phase18_dgp_gaussian_mu_rs <- function(
  n_group,
  n_per_group,
  beta_mu = c("(Intercept)" = 0.20, x1 = 0.55, x2 = -0.35),
  sigma = 0.70,
  sd = c("(Intercept)" = 0.45, x1 = 0.30, x2 = 0.24),
  cor = c(
    "cor((Intercept),x1 | id)" = 0.25,
    "cor((Intercept),x2 | id)" = -0.15,
    "cor(x1,x2 | id)" = 0.10
  ),
  seed = NULL,
  cell_id = NA_character_,
  replicate = NA_integer_
) {
  assert_positive_whole_number(n_group, "n_group")
  assert_positive_whole_number(n_per_group, "n_per_group")
  beta_mu <- phase18_named_numeric(
    beta_mu,
    c("(Intercept)", "x1", "x2"),
    "beta_mu"
  )
  sd <- phase18_named_numeric(sd, c("(Intercept)", "x1", "x2"), "sd")
  if (any(sd <= 0)) {
    stop("`sd` values must be positive.", call. = FALSE)
  }
  assert_phase18_positive_number(sigma, "sigma")
  cor <- phase18_named_numeric(
    cor,
    c(
      "cor((Intercept),x1 | id)",
      "cor((Intercept),x2 | id)",
      "cor(x1,x2 | id)"
    ),
    "cor"
  )
  corr <- phase18_gaussian_mu_rs_corr(cor)
  covariance <- diag(sd) %*% corr %*% diag(sd)

  draw <- function() {
    n <- n_group * n_per_group
    id <- factor(rep(seq_len(n_group), each = n_per_group))
    x1 <- rep(seq(-1, 1, length.out = n_per_group), times = n_group)
    x2 <- stats::rnorm(n)
    latent <- matrix(stats::rnorm(n_group * 3L), ncol = 3L) %*%
      chol(covariance)
    colnames(latent) <- names(sd)

    mu <- unname(
      beta_mu[["(Intercept)"]] +
        beta_mu[["x1"]] * x1 +
        beta_mu[["x2"]] * x2 +
        latent[id, "(Intercept)"] +
        latent[id, "x1"] * x1 +
        latent[id, "x2"] * x2
    )
    y <- stats::rnorm(n, mean = mu, sd = sigma)

    dat <- data.frame(
      y = y,
      x1 = x1,
      x2 = x2,
      id = id,
      mu = mu,
      sigma = sigma,
      cell_id = cell_id,
      replicate = replicate,
      stringsAsFactors = FALSE
    )
    attr(dat, "truth") <- list(
      surface = "gaussian_mu_random_slope",
      beta_mu = beta_mu,
      sigma = sigma,
      sd = stats::setNames(
        sd,
        paste0("(1 + x1 + x2 | id):", names(sd))
      ),
      cor = cor,
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

phase18_named_numeric <- function(x, expected, name) {
  if (
    !is.numeric(x) ||
      length(x) != length(expected) ||
      any(!is.finite(x))
  ) {
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

phase18_gaussian_mu_rs_corr <- function(cor) {
  cor <- phase18_named_numeric(
    cor,
    c(
      "cor((Intercept),x1 | id)",
      "cor((Intercept),x2 | id)",
      "cor(x1,x2 | id)"
    ),
    "cor"
  )
  for (name in names(cor)) {
    assert_phase18_correlation(cor[[name]], name)
  }
  corr <- matrix(
    c(
      1,
      cor[["cor((Intercept),x1 | id)"]],
      cor[["cor((Intercept),x2 | id)"]],
      cor[["cor((Intercept),x1 | id)"]],
      1,
      cor[["cor(x1,x2 | id)"]],
      cor[["cor((Intercept),x2 | id)"]],
      cor[["cor(x1,x2 | id)"]],
      1
    ),
    nrow = 3L,
    dimnames = list(c("(Intercept)", "x1", "x2"), c("(Intercept)", "x1", "x2"))
  )
  smallest <- min(eigen(corr, symmetric = TRUE, only.values = TRUE)$values)
  if (!is.finite(smallest) || smallest <= 1e-8) {
    stop("`cor` must define a positive-definite 3 by 3 matrix.", call. = FALSE)
  }
  corr
}
