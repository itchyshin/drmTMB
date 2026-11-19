# #1751 / #936 (first slice): the simple Gaussian / Student-t location-scale
# path fits on y / sd(y) internally, so the absolute log-sigma clamp and the
# optimizer tolerances no longer depend on the units of y.
#
# Symbolic back-transform checked here (y = c * y0, original-unit fit F_c vs
# the unit-scale fit F_1):
#   coef mu       : F_c = c * F_1          sigma intercept: F_c = F_1 + log(c)
#   sigma slopes  : equal                  RE SD (log)    : F_c = F_1 + log(c)
#   logLik        : F_c = F_1 - n * log(c) (original-scale density)
#   vcov (mu)     : F_c = c^2 * F_1        simulate mean  : F_c = c * F_1

rescale_test_data <- function() {
  set.seed(2)
  n <- 200
  g <- factor(rep(seq_len(20), each = 10))
  x <- stats::rnorm(n)
  data.frame(
    y0 = 1 + 0.5 * x + stats::rnorm(20)[g] * 0.7 +
      exp(0.2 + 0.3 * x) * stats::rt(n, 4),
    x = x,
    g = g
  )
}

rescale_test_fit <- function(family, k, data = rescale_test_data()) {
  data$y <- data$y0 * k
  suppressWarnings(drmTMB(
    bf(y ~ x + (1 | g), sigma ~ x),
    family = family,
    data = data
  ))
}

test_that("Gaussian and Student-t fits are unit-free after back-transform", {
  n <- nrow(rescale_test_data())
  for (family in list(gaussian(), student())) {
    ref <- rescale_test_fit(family, 1)
    expect_null(ref$model$rescale_y)
    for (k in c(1e3, 1e-6, 1e6)) {
      fit <- rescale_test_fit(family, k)
      expect_false(is.null(fit$model$rescale_y))
      expect_equal(fit$opt$convergence, ref$opt$convergence)
      expect_equal(
        as.numeric(logLik(fit)) + n * log(k), as.numeric(logLik(ref)),
        tolerance = 1e-6
      )
      cf <- fit$coefficients
      cr <- ref$coefficients
      expect_equal(unname(cf$mu / k), unname(cr$mu), tolerance = 1e-5)
      expect_equal(unname(cf$sigma[-1L]), unname(cr$sigma[-1L]), tolerance = 1e-5)
      expect_equal(
        unname(cf$sigma[1L] - log(k)), unname(cr$sigma[1L]), tolerance = 1e-5
      )
      expect_equal(
        unname(sqrt(diag(vcov(fit)))[1:2] / k),
        unname(sqrt(diag(vcov(ref)))[1:2]),
        tolerance = 1e-4
      )
      expect_equal(predict(fit) / k, predict(ref), tolerance = 1e-5)
      expect_equal(
        rowMeans(as.matrix(simulate(fit, nsim = 4, seed = 1))) / k,
        rowMeans(as.matrix(simulate(ref, nsim = 4, seed = 1))),
        tolerance = 1e-5
      )
      expect_equal(
        residuals(fit, type = "quantile"), residuals(ref, type = "quantile"),
        tolerance = 1e-4
      )
      # The gradient the fit stores is the one the optimizer drove to zero, so
      # it is unit-free and the clamp is reported inactive.
      expect_lt(max(abs(fit$gradient)), 1e-6)
    }
  }
})

test_that("the #1751 clamp bias is gone at y scaled by 1e-6 and 1e6", {
  data <- rescale_test_data()
  n <- nrow(data)
  ref <- as.numeric(logLik(rescale_test_fit(gaussian(), 1)))
  for (k in c(1e-6, 1e6)) {
    # Switching the internal rescaling off reproduces the old clamped fit ...
    biased <- local({
      testthat::local_mocked_bindings(drm_rescale_window = c(0, Inf))
      rescale_test_fit(gaussian(), k)
    })
    expect_null(biased$model$rescale_y)
    expect_gt(abs(as.numeric(logLik(biased)) + n * log(k) - ref), 1e-3)
    # ... and the rescaled fit recovers the unit-scale value.
    fixed <- rescale_test_fit(gaussian(), k)
    expect_equal(as.numeric(logLik(fixed)) + n * log(k), ref, tolerance = 1e-6)
  }
})

test_that("other paths and in-window scales are left exactly as before", {
  data <- rescale_test_data()
  data$y <- data$y0 * 1e3
  # Fit with a random slope: not the simple path, so no rescale record.
  fit <- suppressWarnings(drmTMB(
    bf(y ~ x + (1 + x | g), sigma ~ 1), data = data
  ))
  expect_null(fit$model$rescale_y)
  # No clamp, or REML: ordinary path.
  expect_null(rescale_test_fit(gaussian(), 1)$model$rescale_y)
  fit_noclamp <- suppressWarnings(drmTMB(
    bf(y ~ x + (1 | g), sigma ~ x), data = data,
    control = drm_control(logsigma_clamp = NULL)
  ))
  expect_null(fit_noclamp$model$rescale_y)
})

test_that("a location offset is divided by the scale internally", {
  data <- rescale_test_data()
  n <- nrow(data)
  fit_k <- function(k) {
    d <- transform(data, y = y0 * k, off = 0.3 * x * k)
    suppressWarnings(drmTMB(
      bf(y ~ x + offset(off) + (1 | g), sigma ~ x), data = d
    ))
  }
  ref <- fit_k(1)
  fit <- fit_k(1e6)
  expect_false(is.null(fit$model$rescale_y))
  expect_equal(
    as.numeric(logLik(fit)) + n * log(1e6), as.numeric(logLik(ref)),
    tolerance = 1e-6
  )
  expect_equal(unname(fit$coefficients$mu / 1e6), unname(ref$coefficients$mu),
               tolerance = 1e-5)
})
