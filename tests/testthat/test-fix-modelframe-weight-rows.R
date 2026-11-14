# Rows dropped inside a formula (log/sqrt of a non-positive predictor) must take
# their weights with them. complete.cases() on the raw columns does not see
# those NaNs, so the weight vector used to stay at the pre-transformation length
# and the likelihood consumed the first nobs weights.

test_that("poisson log() rows keep the weights of the retained rows", {
  d <- data.frame(
    count = c(1, 0, 3, 2, 1, 4),
    x = c(0.5, -1, 1.2, 0.8, -0.3, 1.5)
  )
  w <- c(4, 1, 0.25, 1, 1, 2)
  fit <- suppressWarnings(drmTMB(
    bf(count ~ log(x)),
    family = poisson(),
    data = d,
    weights = w,
    control = drm_control(se = FALSE)
  ))
  keep <- d$x > 0
  expect_identical(nobs(fit), sum(keep))
  expect_identical(length(fit$model$weights), nobs(fit))
  expect_identical(length(fit$model$y), nobs(fit))
  eta <- as.numeric(
    stats::model.matrix(~ log(x), d[keep, , drop = FALSE]) %*% coef(fit, "mu")
  )
  ref <- sum(w[keep] * stats::dpois(d$count[keep], exp(eta), log = TRUE))
  expect_equal(as.numeric(stats::logLik(fit)), ref, tolerance = 1e-6)
  expect_false(is.na(is_converged(fit)))
})

test_that("gaussian log() on both formulas uses retained-row weights", {
  d <- data.frame(
    y = c(0.2, -0.4, 0.7, 0.1, 1.1, -0.2),
    x = c(0.5, -1, 1.2, 0.8, -0.3, 1.5)
  )
  w <- c(4, 1, 0.25, 1, 1, 2)
  fit <- suppressWarnings(drmTMB(
    bf(y ~ log(x), sigma ~ log(x)),
    data = d,
    weights = w,
    control = drm_control(se = FALSE)
  ))
  keep <- d$x > 0
  expect_identical(as.numeric(fit$model$weights), w[keep])
  refit <- suppressWarnings(drmTMB(
    bf(y ~ log(x), sigma ~ log(x)),
    data = d[keep, , drop = FALSE],
    weights = w[keep],
    control = drm_control(se = FALSE)
  ))
  expect_equal(as.numeric(stats::logLik(fit)), as.numeric(stats::logLik(refit)), tolerance = 1e-6)
  expect_equal(coef(fit, "mu"), coef(refit, "mu"), tolerance = 1e-6)
  expect_equal(coef(fit, "sigma"), coef(refit, "sigma"), tolerance = 1e-6)
})

test_that("formulas that drop different transformed rows abort with a row-count error", {
  d <- data.frame(
    y = c(0.2, -0.4, 0.7, 0.1, 1.1, -0.2),
    x = c(0.5, -1, 1.2, 0.8, -0.3, 1.5)
  )
  expect_error(
    suppressWarnings(drmTMB(
      bf(y ~ log(x), sigma ~ 1),
      data = d,
      control = drm_control(se = FALSE)
    )),
    class = "drmTMB_model_frame_rows"
  )
})

test_that("a random intercept follows rows dropped by log()", {
  d <- data.frame(
    y = c(0.2, -0.4, 0.7, 0.1, 1.1, -0.2, 0.3, 0.5),
    x = c(0.5, -1, 1.2, 0.8, -0.3, 1.5, 0.4, 2),
    g = factor(c("a", "a", "b", "b", "c", "c", "a", "b"))
  )
  fit <- suppressWarnings(drmTMB(
    bf(y ~ log(x) + (1 | g), sigma ~ log(x)),
    data = d,
    control = drm_control(se = FALSE)
  ))
  keep <- d$x > 0
  expect_identical(nobs(fit), sum(keep))
  expect_identical(length(fit$model$weights), nobs(fit))
  refit <- suppressWarnings(drmTMB(
    bf(y ~ log(x) + (1 | g), sigma ~ log(x)),
    data = d[keep, , drop = FALSE],
    control = drm_control(se = FALSE)
  ))
  expect_equal(
    as.numeric(stats::logLik(fit)),
    as.numeric(stats::logLik(refit)),
    tolerance = 1e-6
  )
  expect_equal(coef(fit, "mu"), coef(refit, "mu"), tolerance = 1e-6)
  expect_equal(coef(fit, "sigma"), coef(refit, "sigma"), tolerance = 1e-6)
})

test_that("gaussian meta_V follows rows dropped by log()", {
  d <- data.frame(
    y = c(0.2, -0.4, 0.7, 0.1, 1.1, -0.2),
    x = c(0.5, -1, 1.2, 0.8, -0.3, 1.5),
    vi = c(0.05, 0.02, 0.04, 0.03, 0.06, 0.02)
  )
  keep <- d$x > 0
  fit <- suppressWarnings(drmTMB(
    bf(y ~ log(x) + meta_V(V = vi), sigma ~ log(x)),
    data = d,
    control = drm_control(se = FALSE)
  ))
  refit <- suppressWarnings(drmTMB(
    bf(y ~ log(x) + meta_V(V = vi), sigma ~ log(x)),
    data = d[keep, , drop = FALSE],
    control = drm_control(se = FALSE)
  ))
  expect_identical(nobs(fit), sum(keep))
  expect_equal(as.numeric(fit$model$V_known), d$vi[keep])
  expect_equal(
    as.numeric(stats::logLik(fit)),
    as.numeric(stats::logLik(refit)),
    tolerance = 1e-6
  )
})

test_that("log() of strictly positive x still weights every row", {
  d <- data.frame(
    count = c(1, 0, 3, 2, 1, 4),
    x = c(0.5, 0.4, 1.2, 0.8, 0.3, 1.5)
  )
  w <- c(4, 1, 0.25, 1, 1, 2)
  fit <- drmTMB(
    bf(count ~ log(x)),
    family = poisson(),
    data = d,
    weights = w,
    control = drm_control(se = FALSE)
  )
  eta <- as.numeric(stats::model.matrix(~ log(x), d) %*% coef(fit, "mu"))
  ref <- sum(w * stats::dpois(d$count, exp(eta), log = TRUE))
  expect_identical(nobs(fit), nrow(d))
  expect_equal(as.numeric(stats::logLik(fit)), ref, tolerance = 1e-6)
})

new_biv_log_rows_data <- function(n = 80L, seed = 20261112) {
  set.seed(seed)
  x <- stats::rnorm(n)
  x[c(3L, 11L, 12L, 27L, 55L)] <- c(-0.7, -1.1, -0.2, -0.4, -0.9)
  y1 <- 0.2 + 0.5 * x + stats::rnorm(n, sd = 0.5)
  y2 <- -0.1 - 0.3 * x + 0.4 * (y1 - 0.2 - 0.5 * x) + stats::rnorm(n, sd = 0.5)
  data.frame(x = x, y1 = y1, y2 = y2)
}

test_that("bivariate Gaussian weights follow rows dropped by log()", {
  d <- new_biv_log_rows_data()
  w <- stats::runif(nrow(d), 0.5, 2)
  keep <- d$x > 0
  expect_lt(sum(keep), nrow(d))
  f <- bf(
    mu1 = y1 ~ log(x),
    mu2 = y2 ~ log(x),
    sigma1 = ~ log(x),
    sigma2 = ~ log(x),
    rho12 = ~ log(x)
  )
  fit <- suppressWarnings(drmTMB(
    f,
    family = biv_gaussian(),
    data = d,
    weights = w,
    control = drm_control(se = FALSE)
  ))
  refit <- suppressWarnings(drmTMB(
    f,
    family = biv_gaussian(),
    data = d[keep, , drop = FALSE],
    weights = w[keep],
    control = drm_control(se = FALSE)
  ))
  expect_identical(nobs(fit), sum(keep))
  expect_equal(as.numeric(stats::weights(fit)), w[keep])
  expect_equal(
    as.numeric(stats::logLik(fit)),
    as.numeric(stats::logLik(refit)),
    tolerance = 1e-6
  )
  for (dpar in c("mu1", "mu2", "sigma1", "sigma2", "rho12")) {
    expect_equal(coef(fit, dpar), coef(refit, dpar), tolerance = 1e-6)
  }
})

test_that("bivariate Gaussian meta_V follows rows dropped by log()", {
  d <- new_biv_log_rows_data(seed = 20261113)
  n <- nrow(d)
  keep <- d$x > 0
  expect_lt(sum(keep), n)
  V <- meta_vcov_bivariate(
    v1 = seq(0.02, 0.05, length.out = n),
    v2 = seq(0.05, 0.02, length.out = n),
    cor12 = rep(c(0.6, 0.3), length.out = n)
  )
  pair_keep <- as.vector(rbind(keep, keep))
  V_keep <- V[pair_keep, pair_keep, drop = FALSE]
  fit <- suppressWarnings(drmTMB(
    bf(
      mu1 = y1 ~ log(x) + meta_V(V = V),
      mu2 = y2 ~ log(x),
      sigma1 = ~ log(x),
      sigma2 = ~ log(x),
      rho12 = ~ log(x)
    ),
    family = biv_gaussian(),
    data = d,
    control = drm_control(se = FALSE)
  ))
  refit <- suppressWarnings(drmTMB(
    bf(
      mu1 = y1 ~ log(x) + meta_V(V = V_keep),
      mu2 = y2 ~ log(x),
      sigma1 = ~ log(x),
      sigma2 = ~ log(x),
      rho12 = ~ log(x)
    ),
    family = biv_gaussian(),
    data = d[keep, , drop = FALSE],
    control = drm_control(se = FALSE)
  ))
  expect_identical(nobs(fit), sum(keep))
  expect_equal(unname(fit$model$V_known), unname(V_keep))
  expect_equal(
    as.numeric(stats::logLik(fit)),
    as.numeric(stats::logLik(refit)),
    tolerance = 1e-6
  )
  for (dpar in c("mu1", "mu2", "sigma1", "sigma2", "rho12")) {
    expect_equal(coef(fit, dpar), coef(refit, dpar), tolerance = 1e-6)
  }
})

test_that("nbinom2 sd_sigma frames follow rows dropped by log()", {
  set.seed(20261114)
  n_id <- 24L
  n <- 5L * n_id
  g_level <- stats::runif(n_id, 0.5, 2)
  g_level[c(5L, 14L)] <- c(-0.5, -1)
  d <- data.frame(
    id = factor(rep(seq_len(n_id), each = 5L)),
    x = stats::rnorm(n)
  )
  d$g <- g_level[d$id]
  keep <- d$g > 0
  expect_lt(sum(keep), n)
  eta <- 0.8 + 0.3 * stats::rnorm(n_id)[d$id]
  d$count <- stats::rnbinom(n, size = 3, mu = exp(eta + 0.2 * d$x))
  f <- bf(
    count ~ x + log(g),
    sigma ~ 1 + log(g) + (1 | id),
    sd(id, dpar = "sigma") ~ log(g)
  )
  ctrl <- drm_control(se = FALSE)
  fit <- suppressWarnings(drmTMB(f, family = nbinom2(), data = d, control = ctrl))
  refit <- suppressWarnings(drmTMB(
    f,
    family = nbinom2(),
    data = d[keep, , drop = FALSE],
    control = ctrl
  ))
  expect_identical(nobs(fit), sum(keep))
  expect_equal(
    as.numeric(stats::logLik(fit)),
    as.numeric(stats::logLik(refit)),
    tolerance = 1e-6
  )
  expect_equal(coef(fit, "mu"), coef(refit, "mu"), tolerance = 1e-5)
  expect_equal(coef(fit, "sigma"), coef(refit, "sigma"), tolerance = 1e-5)
})
