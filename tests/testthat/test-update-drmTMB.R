test_that("update.drmTMB refits with a new formula and reused defaults (#1241)", {
  set.seed(1)
  dat <- data.frame(y = stats::rnorm(40), x = stats::rnorm(40))
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = gaussian(),
    data = dat,
    control = drm_control(se = FALSE)
  )

  expect_error(update(fit, y ~ 1), "drm_formula|bf")

  reduced <- update(fit, bf(y ~ 1, sigma ~ 1))
  expect_s3_class(reduced, "drmTMB")
  expect_equal(nobs(reduced), nobs(fit))
  expect_lt(length(coef(reduced, "mu")), length(coef(fit, "mu")))
  expect_equal(names(coef(reduced, "mu")), "(Intercept)")

  unevaluated <- update(fit, bf(y ~ 1, sigma ~ 1), evaluate = FALSE)
  expect_true(is.call(unevaluated))
  expect_true(grepl("bf\\(", paste(deparse(unevaluated$formula), collapse = "")))

  shifted <- transform(dat, y = y + 1)
  refit <- update(fit, data = shifted)
  expect_equal(
    unname(coef(refit, "mu")[["(Intercept)"]]),
    unname(coef(fit, "mu")[["(Intercept)"]]) + 1,
    tolerance = 1e-4
  )

  # Unnamed extras must not be silently dropped (review of #1241 / PR #1500).
  expect_error(
    update(fit, bf(y ~ 1, sigma ~ 1), shifted),
    "named arguments"
  )
})
