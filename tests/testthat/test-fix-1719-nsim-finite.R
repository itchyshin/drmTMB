# Simulation counts outside simulate.drmTMB() share one guard: `nsim` must be
# a finite positive whole number. `Inf` used to slip through and end in a raw
# base-R error or an NA count (#1719).

bad_nsim_values <- list(Inf, -Inf, NaN, NA, NA_real_, 3e9, 0, -1, 1.5, "2", TRUE, c(1, 2))

expect_nsim_abort <- function(expr_fn) {
  for (bad in bad_nsim_values) {
    err <- expect_error(
      expect_no_warning(expr_fn(bad)),
      class = "rlang_error"
    )
    expect_match(
      conditionMessage(err),
      "must be one finite positive whole number",
      fixed = TRUE,
      info = paste("nsim =", deparse(bad))
    )
  }
}

test_that("#1719: drm_validate_nsim() accepts whole counts and rejects the rest", {
  expect_identical(drmTMB:::drm_validate_nsim(1), 1L)
  expect_identical(drmTMB:::drm_validate_nsim(5L), 5L)
  expect_nsim_abort(function(n) drmTMB:::drm_validate_nsim(n))
})

test_that("#1719: quantile residuals reject Inf nsim with a drmTMB abort", {
  set.seed(1719)
  d <- data.frame(x = stats::rnorm(30))
  d$y <- 1 + 0.5 * d$x + stats::rnorm(30)
  fit <- drmTMB(bf(y ~ x), family = gaussian(), data = d)
  expect_nsim_abort(function(n) drmTMB:::drm_quantile_residuals(fit, seed = 1, nsim = n))
  expect_length(drmTMB:::drm_quantile_residuals(fit, seed = 1, nsim = 1), 30L)
  expect_length(drmTMB:::drm_quantile_residuals(fit, seed = 1, nsim = 2), 60L)
})

test_that("#1719: simulate() on a pair association rejects Inf nsim", {
  object <- structure(list(status = "interior"), class = "drm_pair_association")
  expect_nsim_abort(function(n) simulate(object, nsim = n))
})

test_that("#1719: Julia Gamma and NB2 SD simulators reject Inf nsim", {
  expect_nsim_abort(function(n) {
    drmTMB:::drm_julia_simulate_gamma_animal_sd(
      object = NULL, spec = NULL, nsim = n, seed = NULL, marginal = TRUE
    )
  })
  expect_nsim_abort(function(n) {
    drmTMB:::drm_julia_simulate_nbinom2_animal_sd_slope(
      object = NULL, spec = NULL, nsim = n, seed = NULL, marginal = TRUE
    )
  })
})

test_that("#1719: Julia binomial SD simulation rejects Inf nsim", {
  testthat::local_mocked_bindings(
    drm_julia_binomial_sd_simulation_spec = function(object) {
      list(components = list("g"))
    }
  )
  object <- structure(
    list(model = list(model_type = "binomial")),
    class = c("drmTMB_julia", "drmTMB")
  )
  expect_nsim_abort(function(n) simulate(object, nsim = n))
})
