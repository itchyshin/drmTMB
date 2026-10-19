# imputed() for a Gaussian mi() predictor must return the exact inner optimum
# E[x | y, theta] = (sigma^2 eta + b tau^2 (y - a)) / (sigma^2 + b^2 tau^2),
# not TMB's inner-Newton mode, which can sit 1e-4 to 1e-3 away from it.
# Rows whose response is also missing reduce to the predictor-model mean eta.

imputed_gaussian_mi_data <- function() {
  set.seed(1129)
  n <- 120
  z <- rnorm(n)
  x <- 0.3 + 0.8 * z + rnorm(n, sd = 0.6)
  y <- 0.5 + 1.2 * x + rnorm(n, sd = 0.5)
  dat <- data.frame(y = y, x = x, z = z)
  miss_x <- sample(n, 40)
  dat$x[miss_x] <- NA_real_
  dat$y[sample(miss_x, 8)] <- NA_real_
  dat
}

test_that("imputed() matches the closed-form Gaussian posterior mean", {
  dat <- imputed_gaussian_mi_data()
  fit <- drmTMB(
    bf(y ~ mi(x), sigma ~ 1),
    data = dat,
    impute = list(x = x ~ z),
    missing = miss_control(predictor = "model", response = "include"),
    control = drm_control(se = FALSE)
  )
  imp <- imputed(fit, se = FALSE)

  a <- fit$coefficients$mu[["(Intercept)"]]
  b <- fit$coefficients$mu[["mi(x)"]]
  sigma <- exp(fit$coefficients$sigma[["(Intercept)"]])
  tau <- exp(fit$opt$par[["log_sigma_mi"]])
  eta <- fit$coefficients$mi_x[["(Intercept)"]] +
    fit$coefficients$mi_x[["z"]] * dat$z[imp$original_row]
  y <- dat$y[imp$original_row]
  y_obs <- !is.na(y)

  expect_gt(sum(y_obs), 20)
  expect_gt(sum(!y_obs), 0)
  oracle <- ifelse(
    y_obs,
    (sigma^2 * eta + b * tau^2 * (y - a)) / (sigma^2 + b^2 * tau^2),
    eta
  )
  expect_equal(imp$estimate[y_obs], oracle[y_obs], tolerance = 1e-6)
  expect_equal(imp$estimate[!y_obs], oracle[!y_obs], tolerance = 1e-6)
})
