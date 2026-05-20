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
      "sim/R/sim_bootstrap.R",
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
  expect_equal(nrow(summary$interval_diagnostics), 6L)
  expect_equal(nrow(summary$interval_failures), 0L)
  expect_equal(summary$replicates$artifact_grain, rep("replicate", 12L))
  expect_equal(summary$aggregate$artifact_grain, rep("aggregate", 6L))
  expect_equal(
    unique(summary$wald_intervals$interval_scale),
    "formula_coefficient"
  )
  expect_true(all(summary$wald_intervals$interval_status == "ok"))
})

test_that("Phase 18 Student-t shape summary can request profile and bootstrap evidence", {
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
    n_rep = 1L,
    master_seed = 224L,
    profile_parameters = c("nu:(Intercept)", "nu:w"),
    profile_level = 0.70,
    profile_args = list(ystep = 0.50),
    bootstrap_nsim = 2L,
    bootstrap_level = 0.70,
    bootstrap_cores = 10L
  )

  expect_equal(nrow(summary$profile_intervals), 2L)
  expect_setequal(
    summary$profile_intervals$parameter,
    c("nu:(Intercept)", "nu:w")
  )
  expect_true(
    all(summary$profile_intervals$interval_status %in% c("ok", "failed"))
  )
  expect_true(any(summary$profile_intervals$interval_status == "ok"))
  expect_equal(nrow(summary$bootstrap_intervals), 6L)
  expect_true(any(summary$bootstrap_intervals$n_bootstrap > 0L))
  expect_true(all(summary$bootstrap_intervals$n_bootstrap <= 2L))
  expect_equal(unique(summary$bootstrap_intervals$bootstrap.backend), "none")
  expect_equal(
    unique(summary$bootstrap_intervals$bootstrap.requested_cores),
    10L
  )
  expect_equal(unique(summary$bootstrap_intervals$bootstrap.cores), 1L)
  expect_setequal(
    unique(summary$interval_evidence$interval_method),
    c("wald", "profile", "parametric_bootstrap")
  )
  expect_setequal(
    unique(summary$interval_diagnostics$interval_method),
    c("wald", "profile", "parametric_bootstrap")
  )
  expect_true(
    all(summary$interval_diagnostics$artifact_grain == "interval_diagnostics")
  )
  expect_true(nrow(summary$interval_evidence) >= 14L)
})
