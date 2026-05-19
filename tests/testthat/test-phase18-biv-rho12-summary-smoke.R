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
  expect_equal(summary$replicates$artifact_grain, rep("replicate", 20L))
  expect_equal(summary$aggregate$artifact_grain, rep("aggregate", 10L))
  expect_equal(
    unique(summary$wald_intervals$interval_scale),
    "formula_coefficient"
  )
  expect_true(all(summary$wald_intervals$interval_status == "ok"))
})
