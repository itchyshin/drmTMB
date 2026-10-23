# Issue #1123: parametric bootstrap CIs failed for binomial fits whose
# response is cbind(successes, failures). bootstrap_response_data() only
# knew how to write a single response column back into the resampled data,
# so the two-column cbind() response tripped the "no stored response column"
# guard even though the fit itself is a documented, supported syntax.

new_bootstrap_cbind_data <- function(n = 60, seed = 20260903) {
  set.seed(seed)
  dat <- data.frame(
    x = stats::rnorm(n),
    trials = sample(5:20, n, replace = TRUE)
  )
  eta <- -0.20 + 0.60 * dat$x
  dat$s <- stats::rbinom(n, size = dat$trials, prob = stats::plogis(eta))
  dat$f <- dat$trials - dat$s
  dat
}

test_that("bootstrap confint works for cbind(successes, failures) binomial fits", {
  dat <- new_bootstrap_cbind_data()
  fit <- drmTMB(
    bf(cbind(s, f) ~ x),
    family = binomial(),
    data = dat
  )

  ci <- stats::confint(
    fit,
    parm = c("fixef:mu:(Intercept)", "fixef:mu:x"),
    method = "bootstrap",
    R = 15,
    seed = 20260904
  )

  expect_equal(ci$parm, c("fixef:mu:(Intercept)", "fixef:mu:x"))
  expect_true(all(is.finite(ci$conf.low)))
  expect_true(all(is.finite(ci$conf.high)))
})

test_that("bootstrap_response_data keeps each row's trial size for cbind binomial fits", {
  dat <- new_bootstrap_cbind_data()
  fit <- drmTMB(
    bf(cbind(s, f) ~ x),
    family = binomial(),
    data = dat
  )

  simulations <- stats::simulate(fit, nsim = 5L, seed = 20260905)

  for (index in c(1L, 3L, 5L)) {
    resampled <- drmTMB:::bootstrap_response_data(fit, simulations, index)
    expect_equal(resampled$s + resampled$f, dat$trials)
  }
})
