test_that("confint accepts bare dpar names as fixef target shortcuts (#1871, #1872)", {
  skip_on_cran()
  set.seed(112611)
  n <- 180
  d_zip <- data.frame(
    x = rnorm(n),
    z = rnorm(n),
    y = ifelse(
      runif(n) < plogis(-0.4 + 0.25 * rnorm(n)),
      0L,
      rpois(n, 2)
    )
  )
  fit_zip <- drmTMB(
    bf(y ~ x, zi ~ z),
    family = poisson(),
    data = d_zip,
    control = drm_control(se = TRUE, parallel = "none")
  )
  expect_error(confint(fit_zip, parm = "zi_"), "Unknown confidence-interval target")
  zi_shorth <- confint(fit_zip, parm = "zi")
  expect_equal(zi_shorth$parm, c("fixef:zi:(Intercept)", "fixef:zi:z"))
  zi_fixef <- confint(fit_zip, parm = "fixef:zi:z")
  expect_equal(
    as.numeric(zi_shorth[zi_shorth$parm == "fixef:zi:z", c("lower", "upper")]),
    as.numeric(zi_fixef[c("lower", "upper")])
  )

  d_hu <- data.frame(
    x = rnorm(n),
    w = rnorm(n),
    count = sample(0:8, n, TRUE)
  )
  fit_hu <- drmTMB(
    bf(count ~ x, hu ~ w),
    family = truncated_nbinom2(),
    data = d_hu,
    control = drm_control(se = TRUE, parallel = "none")
  )
  hu_shorth <- confint(fit_hu, parm = "hu")
  expect_equal(hu_shorth$parm, c("fixef:hu:(Intercept)", "fixef:hu:w"))

  set.seed(1126)
  d_biv <- data.frame(y1 = rnorm(60), y2 = rnorm(60))
  fit_biv <- drmTMB(
    bf(mu1 = y1 ~ 1, mu2 = y2 ~ 1, sigma1 = ~ 1, sigma2 = ~ 1, rho12 = ~ 1),
    family = biv_gaussian(),
    data = d_biv,
    control = drm_control(se = TRUE, parallel = "none")
  )
  mu1_shorth <- confint(fit_biv, parm = "mu1")
  expect_equal(mu1_shorth$parm, "fixef:mu1:(Intercept)")
  rho12_shorth <- confint(fit_biv, parm = "rho12")
  expect_equal(rho12_shorth$parm, "rho12")
})