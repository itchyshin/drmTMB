# refs #1882: stats::update.default() calls update(formula(fit), formula.), which
# breaks when formula. is a drm_formula object passed positionally.

test_that("update(fit, bf(...)) refits univariate, bivariate, and meta_V models", {
  skip_on_cran()
  ctl <- drm_control(parallel = "none", se = FALSE)

  set.seed(1)
  d <- data.frame(y = rnorm(20), x = rnorm(20))
  fit <- drmTMB(bf(y ~ x), family = gaussian(), data = d, control = ctl)
  same <- update(fit, bf(y ~ x))
  expect_equal(same$opt$convergence, fit$opt$convergence)
  expect_equal(unname(coef(same)), unname(coef(fit)), tolerance = 1e-6)

  reduced <- update(fit, bf(y ~ 1))
  expect_lt(as.numeric(logLik(reduced)), as.numeric(logLik(fit)))

  set.seed(2)
  d2 <- data.frame(y1 = rnorm(20), y2 = rnorm(20))
  fit_b <- drmTMB(
    bf(mu1 = y1 ~ 1, mu2 = y2 ~ 1, sigma1 = ~1, sigma2 = ~1, rho12 = ~1),
    family = biv_gaussian(),
    data = d2,
    control = ctl
  )
  again_b <- update(
    fit_b,
    bf(mu1 = y1 ~ 1, mu2 = y2 ~ 1, sigma1 = ~1, sigma2 = ~1, rho12 = ~1)
  )
  expect_equal(again_b$opt$convergence, fit_b$opt$convergence)

  set.seed(3)
  d3 <- data.frame(yi = rnorm(20), x = rnorm(20), vi = rep(0.03, 20))
  fit_m <- drmTMB(
    bf(yi ~ x + meta_V(V = vi), sigma ~ 1),
    family = gaussian(),
    data = d3,
    control = ctl
  )
  changed_m <- update(fit_m, bf(yi ~ 1 + meta_V(V = vi), sigma ~ 1))
  expect_equal(changed_m$opt$convergence, 0L)

  expect_error(
    update(fit, . ~ . + x),
    "bf\\(\\)"
  )
})