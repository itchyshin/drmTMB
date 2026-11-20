test_that("heritability(), icc(), and repeatability() validate profile level (#1480)", {
  dat <- data.frame(
    y = rnorm(40),
    g = factor(rep(1:10, each = 4))
  )
  fit <- drmTMB(bf(y ~ 1 + (1 | g), sigma ~ 1), family = gaussian(), data = dat)
  for (fn in list(heritability, icc, repeatability)) {
    expect_error(fn(fit, level = 1.05), "level")
    expect_error(fn(fit, level = 0), "level")
    expect_error(fn(fit, level = NA_real_), "level")
    expect_error(fn(fit, level = c(0.9, 0.95)), "level")
  }
})