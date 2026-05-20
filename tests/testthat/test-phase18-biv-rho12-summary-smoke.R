source_phase18_biv_rho12_summary <- function(env = parent.frame()) {
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
      "sim/dgp/sim_dgp_biv_rho12.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
  source(
    system.file(
      "sim/fit/sim_summarise_biv_rho12.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
  source(
    system.file(
      "sim/run/sim_run_biv_rho12_smoke.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
  source(
    system.file(
      "sim/run/sim_summary_biv_rho12_smoke.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
}

test_that("Phase 18 bivariate rho12 summary smoke returns replicate and interval tables", {
  source_phase18_biv_rho12_summary()
  conditions <- phase18_biv_rho12_conditions(
    n = 180L,
    delta0 = atanh(0.20),
    delta1 = 0.20,
    sigma_ratio = 1.1,
    rho_xw = 0.1
  )

  summary <- phase18_summarise_biv_rho12_smoke(
    conditions = conditions,
    n_rep = 2L,
    master_seed = 217L
  )

  expect_equal(summary$surface, "biv_rho12")
  expect_equal(nrow(summary$replicates), 20L)
  expect_equal(nrow(summary$aggregate), 10L)
  expect_equal(nrow(summary$manifest), 2L)
  expect_equal(nrow(summary$failures), 0L)
  expect_equal(nrow(summary$wald_intervals), 20L)
  expect_equal(nrow(summary$wald_coverage), 10L)
  expect_equal(nrow(summary$interval_diagnostics), 10L)
  expect_equal(summary$replicates$artifact_grain, rep("replicate", 20L))
  expect_equal(summary$aggregate$artifact_grain, rep("aggregate", 10L))
  expect_equal(
    unique(summary$wald_intervals$interval_scale),
    "formula_coefficient"
  )
  expect_true(all(summary$wald_intervals$interval_status == "ok"))
})

test_that("Phase 18 bivariate rho12 summary can request profile and bootstrap evidence", {
  source_phase18_biv_rho12_summary()
  conditions <- phase18_biv_rho12_conditions(
    n = 180L,
    delta0 = atanh(0.20),
    delta1 = 0.20,
    sigma_ratio = 1.1,
    rho_xw = 0.1
  )

  summary <- phase18_summarise_biv_rho12_smoke(
    conditions = conditions,
    n_rep = 1L,
    master_seed = 225L,
    profile_parameters = "rho12:w",
    profile_level = 0.70,
    profile_args = list(ystep = 0.75),
    bootstrap_nsim = 2L,
    bootstrap_level = 0.70,
    bootstrap_cores = 10L
  )

  expect_equal(nrow(summary$profile_intervals), 1L)
  expect_equal(summary$profile_intervals$parameter, "rho12:w")
  expect_true(
    summary$profile_intervals$interval_status %in% c("ok", "failed")
  )
  expect_equal(nrow(summary$bootstrap_intervals), 10L)
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
  expect_true(nrow(summary$interval_evidence) >= 21L)
})
