test_that("Phase 18 parametric bootstrap refits simulated responses", {
  source(
    system.file("sim/R/sim_registry.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_utils.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_bootstrap.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_uncertainty.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )

  dat <- data.frame(
    y = c(-0.8, -0.1, 0.2, 0.7, 1.1, 1.5),
    x = c(-2, -1, 0, 1, 2, 3)
  )
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)
  refit_fun <- function(fit, simulations, index) {
    dat$y <- simulations[[paste0("sim_", index)]]
    drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)
  }
  statistic_fun <- function(fit) {
    c(
      "mu:(Intercept)" = unname(stats::coef(fit, dpar = "mu")[["(Intercept)"]]),
      "mu:x" = unname(stats::coef(fit, dpar = "mu")[["x"]])
    )
  }

  draws <- phase18_parametric_bootstrap(
    fit,
    statistic_fun = statistic_fun,
    refit_fun = refit_fun,
    nsim = 3L,
    seed = 20260627L
  )
  intervals <- phase18_bootstrap_percentile_intervals(draws)

  expect_equal(nrow(draws), 6L)
  expect_equal(draws$artifact_grain, rep("bootstrap", 6L))
  expect_equal(draws$status, rep("ok", 6L))
  expect_equal(sort(unique(draws$parameter)), c("mu:(Intercept)", "mu:x"))
  expect_equal(nrow(intervals), 2L)
  expect_equal(intervals$interval_method, rep("parametric_bootstrap", 2L))
  expect_equal(intervals$interval_status, rep("ok", 2L))
  expect_equal(intervals$n_bootstrap, rep(3L, 2L))
})

test_that("Phase 18 parametric bootstrap records refit failures", {
  source(
    system.file("sim/R/sim_registry.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_utils.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_bootstrap.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_uncertainty.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )

  dat <- data.frame(y = c(0.1, 0.4, 0.7, 1.0), x = c(-1, 0, 1, 2))
  fit <- drmTMB(bf(y ~ x), family = gaussian(), data = dat)
  draws <- phase18_parametric_bootstrap(
    fit,
    statistic_fun = function(fit) c(beta = 1),
    refit_fun = function(...) stop("planned failure", call. = FALSE),
    nsim = 2L,
    seed = 20260628L
  )

  expect_equal(nrow(draws), 2L)
  expect_equal(draws$status, rep("error", 2L))
  expect_equal(draws$error, rep("planned failure", 2L))
  expect_true(all(is.na(draws$parameter)))
  expect_equal(
    nrow(phase18_interval_failures(
      transform(draws, interval_status = status)
    )),
    2L
  )
})

test_that("Phase 18 bootstrap helpers validate inputs", {
  source(
    system.file("sim/R/sim_registry.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_utils.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_bootstrap.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )

  dat <- data.frame(y = c(0.1, 0.4, 0.7, 1.0), x = c(-1, 0, 1, 2))
  fit <- drmTMB(bf(y ~ x), family = gaussian(), data = dat)

  expect_error(
    phase18_parametric_bootstrap(
      fit,
      statistic_fun = NULL,
      refit_fun = function(...) fit
    ),
    "statistic_fun"
  )
  expect_error(
    phase18_parametric_bootstrap(
      fit,
      statistic_fun = function(fit) c(beta = 1),
      refit_fun = function(...) fit,
      nsim = 0L
    ),
    "positive whole number"
  )
  expect_error(
    phase18_bootstrap_percentile_intervals(data.frame(parameter = "x")),
    "must contain"
  )
})
