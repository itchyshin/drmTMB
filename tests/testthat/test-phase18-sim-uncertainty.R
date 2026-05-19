test_that("Phase 18 MCSE helpers summarise error uncertainty", {
  source(
    system.file("sim/R/sim_uncertainty.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )

  summary <- data.frame(
    surface = "gaussian_ls",
    cell_id = "gaussian_ls_001",
    parameter = rep(c("mu:x", "sigma:z"), each = 4L),
    error = c(-0.1, 0.0, 0.1, 0.2, -0.2, -0.1, 0.1, 0.2)
  )

  out <- phase18_aggregate_error_mcse(summary)

  expect_equal(nrow(out), 2L)
  expect_equal(out$n_replicate, c(4L, 4L))
  expect_true(all(out$bias_mcse > 0))
  expect_true(all(out$rmse_mcse > 0))
  expect_equal(
    phase18_mcse_mean(c(1, 2, 3)),
    stats::sd(c(1, 2, 3)) / sqrt(3)
  )
  expect_equal(
    phase18_mcse_proportion(c(TRUE, FALSE, TRUE, TRUE)),
    sqrt(0.75 * 0.25 / 4)
  )
})

test_that("Phase 18 interval coverage helper uses explicit interval columns", {
  source(
    system.file("sim/R/sim_uncertainty.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )

  summary <- data.frame(
    surface = "meta_v",
    known_v_type = "vector",
    cell_id = "meta_v_001",
    parameter = "sigma",
    truth = c(0.25, 0.25, 0.25, 0.25),
    conf.low = c(0.20, 0.22, 0.30, NA),
    conf.high = c(0.30, 0.24, 0.45, NA)
  )

  out <- phase18_summarise_interval_coverage(summary)

  expect_equal(nrow(out), 1L)
  expect_equal(out$n_replicate, 4L)
  expect_equal(out$n_interval, 3L)
  expect_equal(out$coverage, 0.25)
  expect_equal(out$coverage_mcse, sqrt(0.25 * 0.75 / 4))
  expect_equal(out$mean_interval_width, mean(c(0.10, 0.02, 0.15)))
})

test_that("Phase 18 interval coverage tolerates sparse finite intervals", {
  source(
    system.file("sim/R/sim_uncertainty.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )

  one_interval <- data.frame(
    surface = "student_shape",
    cell_id = "student_shape_001",
    parameter = "nu:w",
    truth = c(0.20, 0.20),
    conf.low = c(0.10, NA_real_),
    conf.high = c(0.30, NA_real_)
  )

  one_out <- phase18_summarise_interval_coverage(one_interval)

  expect_equal(one_out$n_replicate, 2L)
  expect_equal(one_out$n_interval, 1L)
  expect_equal(one_out$mean_interval_width, 0.20)
  expect_true(is.na(one_out$interval_width_mcse))

  zero_interval <- one_interval
  zero_interval$conf.low <- NA_real_
  zero_interval$conf.high <- NA_real_

  zero_out <- phase18_summarise_interval_coverage(zero_interval)

  expect_equal(zero_out$n_replicate, 2L)
  expect_equal(zero_out$n_interval, 0L)
  expect_true(is.na(zero_out$mean_interval_width))
  expect_true(is.na(zero_out$interval_width_mcse))
})

test_that("Phase 18 Wald interval helper records method and status", {
  source(
    system.file("sim/R/sim_uncertainty.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )

  summary <- data.frame(
    surface = "gaussian_ls",
    cell_id = "gaussian_ls_001",
    parameter = "mu:x",
    truth = c(0, 0, 0),
    estimate = c(0.00, 0.20, 0.50),
    std.error = c(0.10, 0.10, NA_real_)
  )

  out <- phase18_add_wald_intervals(summary, interval_scale = "public")
  z <- stats::qnorm(0.975)

  expect_equal(out$conf.low[1:2], summary$estimate[1:2] - z * 0.10)
  expect_equal(out$conf.high[1:2], summary$estimate[1:2] + z * 0.10)
  expect_true(is.na(out$conf.low[[3L]]))
  expect_equal(out$interval_method, rep("wald", 3L))
  expect_equal(out$interval_scale, rep("public", 3L))
  expect_equal(out$interval_status, c("ok", "ok", "failed"))
  expect_match(out$interval_message[[3L]], "invalid")

  mixed_scale <- phase18_add_wald_intervals(
    summary,
    interval_scale = c("formula_coefficient", "formula_coefficient", "public")
  )
  expect_equal(
    mixed_scale$interval_scale,
    c("formula_coefficient", "formula_coefficient", "public")
  )

  coverage <- phase18_summarise_interval_coverage(out)
  expect_equal(coverage$n_replicate, 3L)
  expect_equal(coverage$n_interval, 2L)
})

test_that("Phase 18 interval failure ledger keeps failed intervals visible", {
  source(
    system.file("sim/R/sim_uncertainty.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )

  intervals <- data.frame(
    surface = "biv_rho12",
    cell_id = "biv_rho12_001",
    parameter = c("rho12:w", "rho12:(Intercept)", "sigma1:z1"),
    interval_status = c("ok", "failed", NA_character_),
    interval_message = c("", "profile failed", NA_character_)
  )

  failures <- phase18_interval_failures(intervals)

  expect_equal(nrow(failures), 2L)
  expect_equal(failures$artifact_grain, rep("interval_failure", 2L))
  expect_equal(
    failures$parameter,
    c("rho12:(Intercept)", "sigma1:z1")
  )
  expect_equal(
    failures$interval_failure_status,
    c("failed", NA_character_)
  )

  profile_intervals <- data.frame(
    parameter = c("rho12", "cor:mu:x"),
    conf.status = c("profile", "newdata_required")
  )
  profile_failures <- phase18_interval_failures(profile_intervals)
  expect_equal(nrow(profile_failures), 1L)
  expect_equal(profile_failures$interval_failure_status, "newdata_required")
  expect_named(
    profile_failures,
    c(
      "parameter",
      "conf.status",
      "artifact_grain",
      "interval_failure_status",
      "interval_message"
    )
  )
})

test_that("Phase 18 correlation Wald helper uses Fisher-z scale", {
  source(
    system.file("sim/R/sim_uncertainty.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )

  summary <- data.frame(
    surface = "biv_gaussian",
    cell_id = "rho_001",
    parameter = "rho12",
    truth = c(0.30, 0.30, 0.30),
    estimate = c(0.30, 0.80, 1.00),
    std.error = c(0.10, 0.10, 0.10)
  )

  out <- phase18_add_correlation_fisher_z_intervals(
    summary,
    std.error.scale = "rho"
  )
  z <- stats::qnorm(0.975)
  se_z <- 0.10 / (1 - 0.30^2)
  expected <- tanh(atanh(0.30) + c(-1, 1) * z * se_z)

  expect_equal(out$conf.low[[1L]], expected[[1L]])
  expect_equal(out$conf.high[[1L]], expected[[2L]])
  expect_true(out$conf.low[[2L]] > -1)
  expect_true(out$conf.high[[2L]] < 1)
  expect_true(is.na(out$conf.low[[3L]]))
  expect_equal(
    out$interval_scale,
    rep("fisher_z_backtransformed", 3L)
  )
  expect_equal(out$std.error.scale, rep("rho", 3L))
  expect_equal(out$interval_status, c("ok", "ok", "failed"))

  fisher_scale <- phase18_add_correlation_fisher_z_intervals(
    summary[1:2, ],
    conf.level = 0.90,
    std.error.scale = "fisher_z",
    lower = "lo",
    upper = "hi"
  )
  z_90 <- stats::qnorm(0.95)
  expected_z <- tanh(atanh(summary$estimate[[1L]]) + c(-1, 1) * z_90 * 0.10)

  expect_equal(fisher_scale$lo[[1L]], expected_z[[1L]])
  expect_equal(fisher_scale$hi[[1L]], expected_z[[2L]])
  expect_true(all(fisher_scale$lo > -1))
  expect_true(all(fisher_scale$hi < 1))
  expect_equal(
    fisher_scale$interval_scale,
    rep("fisher_z_backtransformed", 2L)
  )
  expect_equal(fisher_scale$std.error.scale, rep("fisher_z", 2L))
  expect_equal(fisher_scale$interval_status, rep("ok", 2L))
})

test_that("Phase 18 uncertainty helpers validate inputs", {
  source(
    system.file("sim/R/sim_uncertainty.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )

  expect_error(phase18_mcse_mean(numeric()), "non-empty")
  expect_error(phase18_mcse_proportion(c(TRUE, NA)), "without missing")
  expect_error(
    phase18_aggregate_error_mcse(data.frame(parameter = "x")),
    "must contain"
  )
  expect_error(
    phase18_summarise_interval_coverage(
      data.frame(
        parameter = "x",
        truth = 0,
        conf.low = 0,
        conf.high = 1
      ),
      by = "missing"
    ),
    "must exist"
  )
  expect_error(
    phase18_add_wald_intervals(
      data.frame(parameter = "x", estimate = 0, std.error = 0.1),
      conf.level = 1
    ),
    "conf.level"
  )
  expect_error(
    phase18_add_correlation_fisher_z_intervals(
      data.frame(parameter = "rho12", estimate = 0.1, std.error = 0.1),
      std.error.scale = "bad"
    ),
    "arg"
  )
})
