# prediction_grid() and marginal_parameters() with fits (R/prediction-grid.R, R/marginal-parameters.R).

cov_1125x7_grid <- function() {
  set.seed(112578)
  dat <- data.frame(
    y = stats::rnorm(16),
    x = stats::rnorm(16),
    g = rep(c("a", "b"), each = 8)
  )
  drmTMB(
    bf(y ~ x + g, sigma ~ 1),
    data = dat,
    control = drm_control(se = FALSE)
  )
}

test_that("prediction_grid() builds focal rows at requested values", {
  fit <- cov_1125x7_grid()
  grid <- prediction_grid(
    fit,
    focal = "x",
    at = list(x = c(-0.5, 0, 0.5)),
    condition = list(g = "a")
  )
  expect_equal(nrow(grid), 3L)
  expect_equal(grid$x, c(-0.5, 0, 0.5))
  expect_true(all(grid$g == "a"))
})

test_that("marginal_parameters() averages mu across a focal by-column", {
  fit <- cov_1125x7_grid()
  grid <- prediction_grid(fit, focal = "g", at = list(g = c("a", "b")), condition = list(x = 0))
  avg <- marginal_parameters(fit, newdata = grid, dpar = "mu", by = "g")
  expect_equal(nrow(avg), 2L)
  expect_true(all(avg$dpar == "mu"))
  expect_true(all(is.finite(avg$estimate)))
})

test_that("predict_parameters() tracks grid rows for sigma on the response scale", {
  fit <- cov_1125x7_grid()
  grid <- prediction_grid(fit, focal = "x", at = list(x = 0))
  sig <- predict_parameters(fit, newdata = grid, dpar = "sigma", type = "response")
  expect_equal(nrow(sig), 1L)
  expect_gt(sig$estimate, 0)
  expect_equal(sig$dpar, "sigma")
})

test_that("marginal_parameters() refuses unknown distributional parameters", {
  fit <- cov_1125x7_grid()
  expect_error(
    marginal_parameters(fit, newdata = fit$data, dpar = "rho12", by = "g"),
    regexp = "rho12|distributional|parameter"
  )
})

test_that("prediction_grid() preserves factor levels from the fit", {
  fit <- cov_1125x7_grid()
  grid <- prediction_grid(fit, focal = "g", at = list(g = levels(fit$data$g)), condition = list(x = 0))
  expect_s3_class(grid$g, "factor")
  expect_equal(length(levels(grid$g)), 2L)
  pred <- predict_parameters(fit, newdata = grid, dpar = "mu", type = "response")
  expect_equal(nrow(pred), nrow(grid))
  expect_true(all(is.finite(pred$estimate)))
})