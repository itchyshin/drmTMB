# Issue #1699: nobs() counted zero-weight rows that do not contribute to the
# likelihood, so BIC() used too large an n. glm() reports sum(weights > 0).
# These expectations fail on main before the fix (nobs and BIC disagree with
# the fit that drops the zero-weight rows) and pass after it.

drm_1699_ctrl <- function() {
  drm_control(se = FALSE)
}

test_that("zero-weight rows are omitted from nobs() and BIC (#1699)", {
  set.seed(1)
  d <- data.frame(
    y = rnorm(20),
    x = rnorm(20),
    w = c(rep(0, 5), rep(1, 15))
  )
  fit_w <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = gaussian(),
    data = d,
    weights = d$w,
    control = drm_1699_ctrl()
  )
  fit_d <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = gaussian(),
    data = d[d$w > 0, ],
    control = drm_1699_ctrl()
  )
  glm_fit <- stats::glm(y ~ x, data = d, weights = d$w)

  expect_equal(nobs(fit_w), nobs(fit_d))
  expect_equal(nobs(fit_w), sum(d$w > 0))
  expect_equal(nobs(fit_w), nobs(glm_fit))
  expect_equal(attr(logLik(fit_w), "nobs"), nobs(fit_d))
  expect_equal(BIC(fit_w), BIC(fit_d))
  expect_equal(as.numeric(logLik(fit_w)), as.numeric(logLik(fit_d)))
  expect_equal(AIC(fit_w), AIC(fit_d))
  expect_equal(attr(logLik(fit_w), "df"), attr(logLik(fit_d), "df"))
  expect_equal(df.residual(fit_w), nobs(fit_w) - attr(logLik(fit_w), "df"))
  expect_equal(df.residual(fit_w), df.residual(fit_d))
  expect_equal(aicc(fit_w), aicc(fit_d))
  expect_equal(length(fitted(fit_w)), nrow(d))
  expect_equal(length(residuals(fit_w)), nrow(d))
  expect_equal(weights(fit_w), d$w)
})

test_that("a positive non-unit weight still counts as one observation (#1699)", {
  set.seed(1)
  d <- data.frame(
    y = rnorm(20),
    x = rnorm(20),
    w = c(0, 0, 0.5, 2, rep(1, 16))
  )
  keep <- d$w > 0
  fit_w <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = gaussian(),
    data = d,
    weights = d$w,
    control = drm_1699_ctrl()
  )
  fit_d <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = gaussian(),
    data = d[keep, ],
    weights = d$w[keep],
    control = drm_1699_ctrl()
  )

  expect_equal(sum(d$w), 18.5)
  expect_equal(nobs(fit_w), sum(keep))
  expect_equal(nobs(fit_w), nobs(fit_d))
  expect_equal(nobs(fit_w), nobs(stats::glm(y ~ x, data = d, weights = d$w)))
  expect_equal(attr(logLik(fit_w), "nobs"), nobs(fit_d))
  expect_equal(BIC(fit_w), BIC(fit_d))
  expect_equal(as.numeric(logLik(fit_w)), as.numeric(logLik(fit_d)))
  expect_equal(AIC(fit_w), AIC(fit_d))
  expect_equal(length(fitted(fit_w)), nrow(d))
  expect_equal(length(residuals(fit_w)), nrow(d))
  expect_equal(weights(fit_w), d$w)
})

test_that("nobs() counts positive weights only among complete cases (#1699)", {
  set.seed(1)
  d <- data.frame(
    y = rnorm(20),
    x = rnorm(20),
    w = c(rep(0, 5), rep(1, 15))
  )
  d$y[18] <- NA_real_
  keep <- d$w > 0 & !is.na(d$y)
  used <- !is.na(d$y)
  fit_w <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = gaussian(),
    data = d,
    weights = d$w,
    control = drm_1699_ctrl()
  )
  fit_d <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = gaussian(),
    data = d[keep, ],
    control = drm_1699_ctrl()
  )

  expect_equal(nobs(fit_w), nobs(fit_d))
  expect_equal(nobs(fit_w), sum(keep))
  expect_equal(nobs(fit_w), nobs(stats::glm(y ~ x, data = d, weights = d$w)))
  expect_equal(BIC(fit_w), BIC(fit_d))
  expect_equal(as.numeric(logLik(fit_w)), as.numeric(logLik(fit_d)))
  expect_equal(AIC(fit_w), AIC(fit_d))
  expect_equal(length(fitted(fit_w)), sum(used))
  expect_equal(length(residuals(fit_w)), sum(used))
  expect_equal(weights(fit_w), d$w[used])
})

test_that("included missing responses stay out of the positive-weight nobs (#1699)", {
  set.seed(1)
  d <- data.frame(
    y = rnorm(20),
    x = rnorm(20),
    w = c(rep(0, 5), rep(1, 15))
  )
  d$y[18] <- NA_real_
  keep <- !is.na(d$y) & d$w > 0
  fit_w <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = gaussian(),
    data = d,
    weights = d$w,
    missing = miss_control(response = "include"),
    control = drm_1699_ctrl()
  )
  fit_d <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = gaussian(),
    data = d[keep, ],
    control = drm_1699_ctrl()
  )

  expect_equal(nobs(fit_w), nobs(fit_d))
  expect_equal(nobs(fit_w), sum(keep))
  expect_equal(attr(logLik(fit_w), "nobs"), nobs(fit_d))
  expect_equal(BIC(fit_w), BIC(fit_d))
  expect_equal(as.numeric(logLik(fit_w)), as.numeric(logLik(fit_d)))
  expect_equal(AIC(fit_w), AIC(fit_d))
  expect_equal(df.residual(fit_w), df.residual(fit_d))
  expect_equal(length(fitted(fit_w)), nrow(d))
  expect_equal(length(residuals(fit_w)), nrow(d))
  expect_equal(weights(fit_w), d$w)
})

test_that("REML nobs() and BIC use the positive-weight count (#1699)", {
  set.seed(1)
  d <- data.frame(
    y = rnorm(20),
    x = rnorm(20),
    w = c(rep(0, 5), rep(1, 15))
  )
  fit_w <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = gaussian(),
    data = d,
    weights = d$w,
    REML = TRUE,
    control = drm_1699_ctrl()
  )
  fit_d <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = gaussian(),
    data = d[d$w > 0, ],
    REML = TRUE,
    control = drm_1699_ctrl()
  )

  expect_equal(fit_w$estimator, "REML")
  expect_equal(fit_d$estimator, "REML")
  expect_equal(as.numeric(logLik(fit_w)), as.numeric(logLik(fit_d)))
  expect_equal(attr(logLik(fit_w), "df"), attr(logLik(fit_d), "df"))
  expect_equal(attr(logLik(fit_w), "nobs"), nobs(fit_d))
  expect_equal(nobs(fit_w), nobs(fit_d))
  expect_equal(nobs(fit_w), sum(d$w > 0))
  expect_equal(suppressWarnings(BIC(fit_w)), suppressWarnings(BIC(fit_d)))
  expect_equal(suppressWarnings(AIC(fit_w)), suppressWarnings(AIC(fit_d)))
  expect_equal(df.residual(fit_w), nobs(fit_w) - attr(logLik(fit_w), "df"))
  expect_equal(df.residual(fit_w), df.residual(fit_d))
  expect_equal(length(fitted(fit_w)), nrow(d))
  expect_equal(weights(fit_w), d$w)
})

test_that("bivariate nobs() drops zero-weight rows and keeps fitted length (#1699)", {
  set.seed(3)
  d <- data.frame(
    y1 = rnorm(24),
    y2 = rnorm(24),
    x = rnorm(24),
    w = c(rep(0, 6), rep(1, 18))
  )
  form <- bf(
    mu1 = y1 ~ x,
    mu2 = y2 ~ x,
    sigma1 = ~ 1,
    sigma2 = ~ 1,
    rho12 = ~ 1
  )
  fit_w <- drmTMB(
    form,
    family = biv_gaussian(),
    data = d,
    weights = d$w,
    control = drm_1699_ctrl()
  )
  fit_d <- drmTMB(
    form,
    family = biv_gaussian(),
    data = d[d$w > 0, ],
    control = drm_1699_ctrl()
  )

  expect_equal(nobs(fit_w), nobs(fit_d))
  expect_equal(nobs(fit_w), sum(d$w > 0))
  expect_equal(attr(logLik(fit_w), "nobs"), nobs(fit_d))
  expect_equal(BIC(fit_w), BIC(fit_d))
  expect_equal(as.numeric(logLik(fit_w)), as.numeric(logLik(fit_d)))
  expect_equal(AIC(fit_w), AIC(fit_d))
  expect_equal(length(fitted(fit_w)), 2L * nrow(d))
  expect_equal(length(residuals(fit_w)), 2L * nrow(d))
  expect_equal(weights(fit_w), d$w)
})

test_that("Poisson nobs() drops zero-weight rows (#1699)", {
  set.seed(2)
  d <- data.frame(
    y = rpois(30, lambda = 2),
    x = rnorm(30),
    w = c(rep(0, 4), rep(1, 26))
  )
  fit_w <- drmTMB(
    bf(y ~ x),
    family = poisson(),
    data = d,
    weights = d$w,
    control = drm_1699_ctrl()
  )
  fit_d <- drmTMB(
    bf(y ~ x),
    family = poisson(),
    data = d[d$w > 0, ],
    control = drm_1699_ctrl()
  )

  expect_equal(nobs(fit_w), nobs(fit_d))
  expect_equal(nobs(fit_w), sum(d$w > 0))
  expect_equal(BIC(fit_w), BIC(fit_d))
  expect_equal(as.numeric(logLik(fit_w)), as.numeric(logLik(fit_d)))
  expect_equal(AIC(fit_w), AIC(fit_d))
  expect_equal(length(fitted(fit_w)), nrow(d))
  expect_equal(weights(fit_w), d$w)
})
