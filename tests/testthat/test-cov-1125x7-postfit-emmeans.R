# emmeans S3 methods after a fit (R/emmeans-preflight.R).

cov_1125x7_emm <- function() {
  set.seed(112582)
  dat <- data.frame(
    y = stats::rnorm(18),
    x = stats::rnorm(18),
    trt = factor(rep(c("A", "B"), each = 9))
  )
  drmTMB(
    bf(y ~ trt + x, sigma ~ 1),
    data = dat,
    control = drm_control(se = TRUE)
  )
}

test_that("drm_emmeans_mu_basis() returns a design matrix for mu", {
  fit <- cov_1125x7_emm()
  grid <- data.frame(trt = factor(c("A", "B"), levels = levels(fit$data$trt)), x = 0)
  basis <- drmTMB:::drm_emmeans_mu_basis(fit, newdata = grid, dpar = "mu", type = "link")
  expect_equal(basis$dpar, "mu")
  expect_equal(basis$type, "link")
  expect_true(length(basis$basis$bhat) >= 2L)
})

test_that("emm_basis.drmTMB() exposes coefficients and vcov for emmeans", {
  fit <- cov_1125x7_emm()
  grid <- data.frame(trt = factor("A", levels = levels(fit$data$trt)), x = 0)
  recovered <- drmTMB:::drm_emmeans_recover_data(fit, dpar = "mu")
  trms <- recovered$terms
  xlev <- stats::.getXlevels(trms, recovered$model_frame)
  out <- emmeans::emm_basis(fit, trms = trms, xlev = xlev, grid = grid, dpar = "mu")
  expect_true(is.list(out))
  expect_true(length(out$bhat) >= 2L)
  expect_true(is.matrix(out$V) || inherits(out$V, "Matrix"))
})

test_that("recover_data.drmTMB() rebuilds the model frame", {
  fit <- cov_1125x7_emm()
  rec <- recover_data.drmTMB(fit, dpar = "mu")
  expect_s3_class(rec, "data.frame")
  expect_equal(nrow(rec), nrow(fit$data))
})