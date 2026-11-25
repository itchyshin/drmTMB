# Additional post-fit surfaces across families (methods, distributional outputs).

cov_1125x7_family <- function(family, dat, formula = bf(y ~ x, sigma ~ 1)) {
  drmTMB(
    formula,
    family = family,
    data = dat,
    control = drm_control(se = FALSE)
  )
}

test_that("Student-t fits support predict_parameters and fitted()", {
  set.seed(112588)
  dat <- data.frame(y = stats::rt(18, df = 5), x = stats::rnorm(18))
  fit <- cov_1125x7_family(student(), dat, bf(y ~ x, sigma ~ 1, nu ~ 1))
  pp <- predict_parameters(fit, dpar = "mu", newdata = dat[1, ])
  expect_equal(nrow(pp), 1L)
  expect_true(is.finite(pp$estimate))
  expect_equal(length(fitted(fit)), 18L)
  expect_true(all(is.finite(fitted(fit))))
})

test_that("negative binomial fits return positive response means", {
  set.seed(112589)
  dat <- data.frame(y = stats::rnbinom(20, mu = 4, size = 2), x = stats::rnorm(20))
  fit <- cov_1125x7_family(nbinom2(), dat, bf(y ~ x, sigma ~ 1))
  mu <- predict_parameters(fit, dpar = "mu", type = "response", newdata = dat[1:3, ])
  expect_true(all(mu$estimate > 0))
  sig <- predict_parameters(fit, dpar = "sigma", type = "response", newdata = dat[1, ])
  expect_gt(sig$estimate, 0)
  expect_length(predict(fit, newdata = dat[1:2, ]), 2L)
})

test_that("beta fits expose link-scale predict_parameters", {
  set.seed(112590)
  dat <- data.frame(y = stats::rbeta(18, 2, 2), x = stats::rnorm(18))
  fit <- cov_1125x7_family(beta_family(), dat)
  link <- predict_parameters(fit, dpar = "mu", type = "link", newdata = dat[1:2, ])
  expect_equal(nrow(link), 2L)
  resp <- predict_parameters(fit, dpar = "mu", type = "response", newdata = dat[1, ])
  expect_gt(resp$estimate, 0)
  expect_lt(resp$estimate, 1)
  qr <- residuals(fit, type = "quantile")
  expect_equal(length(qr), 18L)
})

test_that("ordinal cumulative-logit fits return finite fitted counts", {
  set.seed(112591)
  y <- factor(stats::rnorm(20), ordered = TRUE, levels = sort(unique(stats::rnorm(20))))
  dat <- data.frame(y = factor(sample(1:4, 20, replace = TRUE), ordered = TRUE), x = stats::rnorm(20))
  fit <- drmTMB(
    bf(y ~ x),
    family = cumulative_logit(),
    data = dat,
    control = drm_control(se = FALSE)
  )
  expect_equal(length(fitted(fit)), 20L)
  expect_true(all(is.finite(fitted(fit))))
  pp <- predict_parameters(fit, dpar = "mu", newdata = dat[1, ])
  expect_equal(nrow(pp), 1L)
  expect_true(is.finite(pp$estimate))
  chk <- check_drm(fit)
  expect_s3_class(chk, "data.frame")
})