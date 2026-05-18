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
})
