# Regression for #1696: validate `nsim` in simulate.drmTMB().

new_simulate_nsim_fit <- function() {
  dat <- data.frame(y = c(0.2, 0.5, 1.1, 1.4), x = c(-1, 0, 1, 2))
  drmTMB(
    bf(y ~ x, sigma ~ 1),
    data = dat,
    control = drm_control(se = FALSE)
  )
}

test_that("test-fix-1696", {
  fit <- new_simulate_nsim_fit()
  bad_nsim <- list(0, -1, NA, Inf, 1.5, c(1, 2), numeric(0), TRUE, "a")
  for (bad in bad_nsim) {
    expect_error(
      simulate(fit, nsim = bad, seed = 1),
      "one positive whole number",
      class = "rlang_error"
    )
  }
  two <- simulate(fit, nsim = 2.0, seed = 1)
  expect_equal(ncol(two), 2L)
  expect_equal(nrow(two), 4L)
  one <- simulate(fit, nsim = 1, seed = 1)
  expect_equal(ncol(one), 1L)
  expect_equal(nrow(one), 4L)
  three <- simulate(fit, nsim = 3, seed = 1)
  expect_equal(ncol(three), 3L)
  expect_equal(nrow(three), 4L)
  expect_equal(names(three), c("sim_1", "sim_2", "sim_3"))
})
