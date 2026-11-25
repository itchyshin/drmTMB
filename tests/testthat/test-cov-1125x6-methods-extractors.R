# fixef/ranef/weights/print on a tiny Gaussian fit (R/methods.R).

cov_1125x6_fit <- function() {
  set.seed(11256)
  dat <- data.frame(
    y = stats::rnorm(14),
    x = stats::rnorm(14),
    g = rep(letters[1:2], each = 7)
  )
  drmTMB(
    bf(y ~ x + (1 | g), sigma ~ 1),
    family = gaussian(),
    data = dat,
    control = drm_control(se = FALSE)
  )
}

test_that("fixef() and ranef() return coefficient tables for ordinary RE", {
  fit <- cov_1125x6_fit()
  fe <- fixef(fit)
  expect_true("mu" %in% names(fe))
  expect_true(any(grepl("x", names(fe$mu))))
  re <- ranef(fit)
  expect_true(length(re) >= 1L)
  expect_error(drmTMB:::ranef.drmTMB(fit, dpar = "missing"), "Unknown random-effect")
})

test_that("weights() defaults to unit weights on the fit rows", {
  fit <- cov_1125x6_fit()
  w <- weights(fit)
  expect_equal(length(w), fit$nobs)
  expect_true(all(w == 1))
})

test_that("print.drmTMB() names family and observation count", {
  fit <- cov_1125x6_fit()
  txt <- paste(capture.output(print(fit), type = "message"), collapse = "\n")
  expect_match(txt, "Gaussian")
  expect_match(txt, "observations: 14")
})

test_that("structured_effects() refuses non-drmTMB objects", {
  expect_error(structured_effects(lm(y ~ x, data = data.frame(y = 1:3, x = 1:3))), "drmTMB")
})