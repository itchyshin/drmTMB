source_phase18_student_shape_summary <- function(env = parent.frame()) {
  source(
    system.file("sim/R/sim_registry.R", package = "drmTMB", mustWork = TRUE),
    local = env
  )
  source(
    system.file("sim/R/sim_utils.R", package = "drmTMB", mustWork = TRUE),
    local = env
  )
  source(
    system.file("sim/R/sim_runner.R", package = "drmTMB", mustWork = TRUE),
    local = env
  )
  source(
    system.file("sim/R/sim_aggregate.R", package = "drmTMB", mustWork = TRUE),
    local = env
  )
  source(
    system.file(
      "sim/R/sim_uncertainty.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
  source(
    system.file(
      "sim/dgp/sim_dgp_student_shape.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
  source(
    system.file(
      "sim/fit/sim_summarise_student_shape.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
  source(
    system.file(
      "sim/run/sim_run_student_shape_smoke.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
  source(
    system.file(
      "sim/run/sim_summary_student_shape_smoke.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
}

test_that("Phase 18 Student-t shape summary smoke returns interval artifacts", {
  source_phase18_student_shape_summary()
  conditions <- phase18_student_shape_conditions(
    n = 240L,
    nu_intercept = log(6),
    nu_slope = 0.20,
    sigma_slope = 0.20,
    rho_xw = 0.1
  )

  summary <- phase18_summarise_student_shape_smoke(
    conditions = conditions,
    n_rep = 2L,
    master_seed = 220L
  )

  expect_equal(summary$surface, "student_shape")
  expect_equal(nrow(summary$replicates), 12L)
  expect_equal(nrow(summary$aggregate), 6L)
  expect_equal(nrow(summary$manifest), 2L)
  expect_equal(nrow(summary$failures), 0L)
  expect_equal(nrow(summary$wald_intervals), 12L)
  expect_equal(nrow(summary$wald_coverage), 6L)
  expect_equal(nrow(summary$interval_failures), 0L)
  expect_equal(summary$replicates$artifact_grain, rep("replicate", 12L))
  expect_equal(summary$aggregate$artifact_grain, rep("aggregate", 6L))
  expect_equal(
    unique(summary$wald_intervals$interval_scale),
    "formula_coefficient"
  )
  expect_true(all(summary$wald_intervals$interval_status == "ok"))
})
