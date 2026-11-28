# Extra post-fit surfaces to round out coverage expects.

test_that("truncated NB2 models return positive fitted counts", {
  set.seed(112594)
  dat <- data.frame(y = stats::rpois(18, 2), x = stats::rnorm(18))
  pos <- dat[dat$y > 0, ]
  zt <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = truncated_nbinom2(),
    data = pos,
    control = drm_control(se = FALSE)
  )
  expect_true(all(fitted(zt) > 0))
  expect_length(predict(zt, newdata = pos[1:3, ]), 3L)
  expect_equal(length(residuals(zt, type = "response")), nrow(pos))
  expect_true(is.finite(logLik(zt)))
  expect_true(all(is.finite(residuals(zt, type = "pearson"))))
})

test_that("zero-one beta and student models keep finite residuals", {
  set.seed(112596)
  dat <- data.frame(y = runif(18, 0.05, 0.95), x = stats::rnorm(18))
  zo <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = zero_one_beta(),
    data = dat,
    control = drm_control(se = FALSE)
  )
  expect_true(all(is.finite(residuals(zo, type = "pearson"))))
  expect_gt(predict_parameters(zo, dpar = "mu", type = "response", newdata = dat[1, ])$estimate, 0)
  expect_length(fitted(zo), 18L)
  st <- drmTMB(
    bf(y ~ x, sigma ~ 1, nu ~ 1),
    family = student(),
    data = data.frame(y = stats::rt(16, 4), x = stats::rnorm(16)),
    control = drm_control(se = FALSE)
  )
  expect_equal(length(fitted(st)), 16L)
  expect_true(all(is.finite(predict(st, newdata = st$data[1:2, ]))))
  expect_true(is.finite(AIC(st)))
  expect_equal(attr(logLik(st), "nobs"), 16L)
})