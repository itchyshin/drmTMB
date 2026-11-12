# Inf in a bivariate Gaussian response or design must abort in drmTMB.
# NA and NaN responses stay on the complete-case path (#1709).

biv_nonfinite_data <- function() {
  set.seed(1)
  data.frame(
    y1 = stats::rnorm(20),
    y2 = stats::rnorm(20),
    x = stats::rnorm(20)
  )
}

biv_nonfinite_formula <- function() {
  bf(
    mu1 = y1 ~ x,
    mu2 = y2 ~ x,
    sigma1 = ~ 1,
    sigma2 = ~ 1,
    rho12 = ~ 1
  )
}

expect_biv_finite_response <- function(data, response) {
  err <- expect_error(
    drmTMB(
      biv_nonfinite_formula(),
      family = biv_gaussian(),
      data = data,
      control = drm_control(se = FALSE)
    ),
    class = "rlang_error"
  )
  expect_match(conditionMessage(err), "finite observed response")
  expect_match(conditionMessage(err), response, fixed = TRUE)
}

test_that("biv_gaussian #1709: Inf in y1 aborts with a finite-response error", {
  d <- biv_nonfinite_data()
  d$y1[1] <- Inf
  expect_biv_finite_response(d, "y1")
})

test_that("biv_gaussian #1709: Inf in y2 aborts with a finite-response error", {
  d <- biv_nonfinite_data()
  d$y2[1] <- -Inf
  expect_biv_finite_response(d, "y2")
})

test_that("biv_gaussian #1709: Inf in a predictor aborts and names the column", {
  d <- biv_nonfinite_data()
  d$x[1] <- Inf
  err <- expect_error(
    drmTMB(
      biv_nonfinite_formula(),
      family = biv_gaussian(),
      data = d,
      control = drm_control(se = FALSE)
    ),
    class = "rlang_error"
  )
  expect_match(conditionMessage(err), "finite fixed-effect design values")
  expect_match(conditionMessage(err), "\\bx\\b")
  expect_match(conditionMessage(err), "dpar = \"mu1\"", fixed = TRUE)
})

test_that("biv_gaussian #1709: Inf in a sigma1 predictor aborts and names the column", {
  d <- biv_nonfinite_data()
  d$z <- d$x
  d$z[1] <- Inf
  err <- expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ 1,
        mu2 = y2 ~ 1,
        sigma1 = ~ z,
        sigma2 = ~ 1,
        rho12 = ~ 1
      ),
      family = biv_gaussian(),
      data = d,
      control = drm_control(se = FALSE)
    ),
    class = "rlang_error"
  )
  expect_match(conditionMessage(err), "finite fixed-effect design values")
  expect_match(conditionMessage(err), "\\bz\\b")
  expect_match(conditionMessage(err), "dpar = \"sigma1\"", fixed = TRUE)
})

test_that("biv_gaussian #1709: NA and NaN in y1 stay dropped", {
  d <- biv_nonfinite_data()
  d$y1[1] <- NA_real_
  fit_na <- drmTMB(
    biv_nonfinite_formula(),
    family = biv_gaussian(),
    data = d,
    control = drm_control(se = FALSE)
  )
  expect_equal(nobs(fit_na), 19L)

  d$y1[1] <- NaN
  fit_nan <- drmTMB(
    biv_nonfinite_formula(),
    family = biv_gaussian(),
    data = d,
    control = drm_control(se = FALSE)
  )
  expect_equal(nobs(fit_nan), 19L)
})
