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
  expect_s3_class(fit, "drmTMB")
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
