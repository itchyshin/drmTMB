test_that("uniform weights are not frequency weights for nobs() and BIC()", {
  set.seed(2)
  d <- data.frame(y = rnorm(30), x = rnorm(30))

  f_unit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    data = d,
    family = gaussian(),
    control = drm_control(se = FALSE)
  )

  d$w <- 2
  f_w <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    data = d,
    family = gaussian(),
    weights = d$w,
    control = drm_control(se = FALSE)
  )

  d_rep <- d[rep(seq_len(nrow(d)), each = 2), c("y", "x")]
  f_rep <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    data = d_rep,
    family = gaussian(),
    control = drm_control(se = FALSE)
  )

  expect_equal(as.numeric(logLik(f_w)), as.numeric(logLik(f_rep)), tolerance = 1e-6)
  expect_equal(AIC(f_w), AIC(f_rep), tolerance = 1e-6)
  expect_equal(nobs(f_w), 30L)
  expect_equal(nobs(f_rep), 60L)
  expect_false(isTRUE(all.equal(BIC(f_w), BIC(f_rep), tolerance = 1e-8)))
})

test_that("nobs() and BIC() omit zero-weight rows (#1863)", {
  set.seed(1)
  k <- 5L
  n <- 20L
  d <- data.frame(
    y = rnorm(n),
    x = rnorm(n),
    w = c(rep(0, k), rep(1, n - k))
  )
  fit_w <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    data = d,
    family = gaussian(),
    weights = d$w,
    control = drm_control(se = FALSE)
  )
  fit_d <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    data = d[d$w > 0, ],
    family = gaussian(),
    control = drm_control(se = FALSE)
  )

  expect_equal(nobs(fit_w), n - k)
  expect_equal(attr(logLik(fit_w), "nobs"), n - k)
  expect_equal(nobs(fit_w), nobs(fit_d))
  expect_equal(BIC(fit_w), BIC(fit_d))
  expect_equal(aicc(fit_w), aicc(fit_d))
})