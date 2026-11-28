# residuals() and simulate() branches (R/methods.R).

cov_1125x7_re <- function() {
  set.seed(112573)
  dat <- data.frame(
    y = stats::rnorm(20),
    x = stats::rnorm(20),
    g = rep(letters[1:2], each = 10)
  )
  drmTMB(
    bf(y ~ x + (1 | g), sigma ~ 1),
    data = dat,
    control = drm_control(se = FALSE)
  )
}

test_that("residuals() exposes response, pearson, and quantile types", {
  fit <- cov_1125x7_re()
  r_resp <- residuals(fit, type = "response")
  r_pearson <- residuals(fit, type = "pearson")
  r_quant <- residuals(fit, type = "quantile")
  expect_equal(length(r_resp), fit$nobs)
  expect_equal(length(r_pearson), fit$nobs)
  expect_equal(length(r_quant), fit$nobs)
  expect_true(all(is.finite(r_pearson)))
})

test_that("simulate() returns nsim columns with correct dimensions", {
  fit <- cov_1125x7_re()
  sim <- simulate(fit, nsim = 3, seed = 112573)
  expect_s3_class(sim, "data.frame")
  expect_equal(ncol(sim), 3L)
  expect_equal(nrow(sim), fit$nobs)
  expect_true(all(is.finite(unlist(sim))))
})

test_that("simulate() honors re.form = NULL for conditional random effects", {
  fit <- cov_1125x7_re()
  sim <- simulate(fit, nsim = 2, seed = 2, re.form = NULL)
  expect_equal(dim(sim), c(fit$nobs, 2L))
  expect_true(all(is.finite(unlist(sim))))
})

test_that("binomial residuals stay finite for a tiny logistic fit", {
  set.seed(112574)
  dat <- data.frame(
    y = stats::rbinom(24, 1, 0.4),
    x = stats::rnorm(24)
  )
  fit <- drmTMB(
    bf(y ~ x),
    family = binomial(),
    data = dat,
    control = drm_control(se = FALSE)
  )
  r <- residuals(fit, type = "pearson")
  expect_equal(length(r), 24L)
  expect_true(all(is.finite(r)))
})