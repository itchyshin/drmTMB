test_that("Phase 18 synthetic interval smoke helper builds coverage tables", {
  source(
    system.file("sim/R/sim_uncertainty.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file(
      "sim/run/sim_interval_coverage_smoke.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )

  summary <- data.frame(
    surface = "gaussian_ls",
    cell_id = "gaussian_ls_001",
    parameter = rep(c("mu:x", "sigma:z"), each = 4L),
    truth = c(rep(0, 4L), rep(1, 4L)),
    estimate = c(0.0, 0.3, 0.7, -0.1, 0.9, 1.1, 1.3, 0.4)
  )

  out <- phase18_summarise_synthetic_interval_smoke(
    summary,
    half_width = 0.25
  )

  expect_identical(out$interval_source, "synthetic")
  expect_equal(nrow(out$summary), nrow(summary))
  expect_equal(nrow(out$coverage), 2L)
  expect_equal(out$coverage$n_replicate, c(4L, 4L))
  expect_equal(out$coverage$n_interval, c(4L, 4L))
  expect_equal(out$coverage$coverage, c(0.5, 0.5))
  expect_true(all(out$coverage$coverage_mcse > 0))
})

test_that("Phase 18 synthetic interval smoke helper validates inputs", {
  source(
    system.file("sim/R/sim_uncertainty.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file(
      "sim/run/sim_interval_coverage_smoke.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )

  summary <- data.frame(
    surface = "meta_v",
    cell_id = "meta_v_001",
    parameter = "sigma",
    truth = 0.25,
    estimate = 0.3
  )

  expect_error(
    phase18_add_synthetic_intervals(summary, half_width = 0),
    "half_width"
  )
  expect_error(
    phase18_add_synthetic_intervals(
      summary,
      lower = "",
      upper = "conf.high"
    ),
    "lower"
  )
  expect_error(
    phase18_add_synthetic_intervals(data.frame(parameter = "x")),
    "must contain"
  )
})
