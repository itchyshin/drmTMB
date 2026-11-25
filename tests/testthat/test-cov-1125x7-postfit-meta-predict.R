# Meta-analysis and response-scale prediction (R/drmTMB.R meta path, R/predict-parameters.R).

test_that("meta_V Gaussian fits support predict_parameters for each study row", {
  set.seed(112586)
  dat <- data.frame(
    y = c(0.1, 0.2, 0.25),
    se = c(0.05, 0.04, 0.05),
    study = factor(1:3)
  )
  V <- diag(dat$se^2)
  fit <- drmTMB(
    bf(y ~ 1, sigma ~ 1),
    family = gaussian(),
    meta_V(V = V),
    data = dat,
    control = drm_control(se = FALSE)
  )
  pp <- predict_parameters(fit, dpar = "mu", type = "response")
  expect_equal(nrow(pp), 3L)
  expect_true(all(is.finite(pp$estimate)))
  expect_equal(length(fitted(fit)), 3L)
})

test_that("Gamma predict_parameters returns positive response-scale scale", {
  set.seed(112587)
  dat <- data.frame(y = stats::rgamma(16, shape = 2, scale = 2), x = stats::rnorm(16))
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = Gamma(link = "log"),
    data = dat,
    control = drm_control(se = FALSE)
  )
  sig <- predict_parameters(fit, dpar = "sigma", type = "response", newdata = dat[1:2, ])
  expect_equal(nrow(sig), 2L)
  expect_true(all(sig$estimate > 0))
  mu <- predict_parameters(fit, dpar = "mu", type = "response", newdata = dat[1, ])
  expect_gt(mu$estimate, 0)
})