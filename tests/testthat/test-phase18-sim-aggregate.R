test_that("Phase 18 aggregation summarises parameter errors by default groups", {
  source(
    system.file("sim/R/sim_aggregate.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )

  summary <- data.frame(
    surface = "gaussian_ls",
    cell_id = rep("gaussian_ls_001", 4L),
    replicate = c(1L, 2L, 1L, 2L),
    parameter = rep(c("mu:x", "sigma:z"), each = 2L),
    truth = c(0.6, 0.6, 0.3, 0.3),
    estimate = c(0.7, 0.5, 0.4, 0.35),
    error = c(0.1, -0.1, 0.1, 0.05),
    converged = c(TRUE, TRUE, TRUE, FALSE),
    pdHess = c(TRUE, TRUE, FALSE, FALSE),
    elapsed = c(0.2, 0.3, 0.4, 0.5),
    warning_count = c(0L, 1L, 0L, 0L)
  )

  out <- phase18_aggregate_parameters(summary)

  expect_equal(nrow(out), 2L)
  expect_equal(out$cell_id, rep("gaussian_ls_001", 2L))
  expect_equal(out$n_replicate, c(2L, 2L))
  expect_equal(out$bias[out$parameter == "mu:x"], 0)
  expect_equal(out$rmse[out$parameter == "mu:x"], 0.1)
  expect_equal(out$artifact_grain, rep("aggregate", 2L))
  expect_equal(out$convergence_rate[out$parameter == "sigma:z"], 0.5)
  expect_equal(out$pdHess_rate[out$parameter == "sigma:z"], 0)
  expect_equal(out$warning_rate[out$parameter == "mu:x"], 0.5)
})

test_that("Phase 18 aggregation can pool across cells when requested", {
  source(
    system.file("sim/R/sim_aggregate.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )

  summary <- data.frame(
    surface = "meta_v",
    known_v_type = rep(c("vector", "dense"), each = 2L),
    cell_id = c("meta_v_001", "meta_v_001", "meta_v_002", "meta_v_002"),
    parameter = "sigma",
    truth = 0.25,
    estimate = c(0.20, 0.30, 0.35, 0.15),
    error = c(-0.05, 0.05, 0.10, -0.10),
    converged = TRUE,
    pdHess = TRUE,
    elapsed = 0.1,
    warning_count = 0L
  )

  out <- phase18_aggregate_parameters(
    summary,
    by = c("surface", "known_v_type", "parameter")
  )

  expect_equal(nrow(out), 2L)
  expect_setequal(out$known_v_type, c("vector", "dense"))
  expect_equal(out$n_replicate, c(2L, 2L))
  expect_equal(out$bias[out$known_v_type == "vector"], 0)
  expect_equal(out$bias[out$known_v_type == "dense"], 0)
})

test_that("Phase 18 aggregation validates summary schema", {
  source(
    system.file("sim/R/sim_aggregate.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )

  expect_error(
    phase18_aggregate_parameters(data.frame()),
    "non-empty data frame"
  )
  expect_error(
    phase18_aggregate_parameters(data.frame(parameter = "x")),
    "must contain"
  )
  expect_error(
    phase18_aggregate_parameters(
      data.frame(
        parameter = "x",
        truth = 0,
        estimate = 0,
        error = 0,
        converged = TRUE,
        pdHess = TRUE,
        elapsed = 0,
        warning_count = 0
      ),
      by = "missing"
    ),
    "must exist"
  )
})
