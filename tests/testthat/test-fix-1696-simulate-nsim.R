# Regression for #1696: validate `nsim` in simulate.drmTMB().

new_simulate_nsim_fit <- function() {
  dat <- data.frame(y = c(0.2, 0.5, 1.1, 1.4), x = c(-1, 0, 1, 2))
  drmTMB(
    bf(y ~ x, sigma ~ 1),
    data = dat,
    control = drm_control(se = FALSE)
  )
}

test_that("simulate() refuses invalid nsim with a drmTMB abort (#1696)", {
  fit <- new_simulate_nsim_fit()
  nsim_abort <- function(nsim) {
    expect_error(
      simulate(fit, nsim = nsim, seed = 1),
      "one positive whole number",
      class = "rlang_error"
    )
  }
  nsim_abort(0)
  nsim_abort(-1)
  nsim_abort(NA_real_)
  nsim_abort(Inf)
  nsim_abort(1.5)
  nsim_abort(TRUE)
  nsim_abort(c(1, 2))
  nsim_abort(numeric(0))
})

test_that("simulate() accepts positive integer nsim (#1696)", {
  fit <- new_simulate_nsim_fit()
  expect_equal(ncol(simulate(fit, nsim = 1L, seed = 1)), 1L)
  expect_equal(ncol(simulate(fit, nsim = 3L, seed = 1)), 3L)
  expect_equal(ncol(simulate(fit, nsim = 2.0, seed = 1)), 2L)
})