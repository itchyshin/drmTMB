source_phase18_biv_gaussian_mu_slope_recovery <- function() {
  env <- parent.frame()
  files <- c(
    "sim/R/sim_registry.R",
    "sim/R/sim_utils.R",
    "sim/R/sim_runner.R",
    "sim/R/sim_aggregate.R",
    "sim/R/sim_uncertainty.R",
    "sim/dgp/sim_dgp_biv_gaussian_mu_slope.R",
    "sim/fit/sim_summarise_biv_gaussian_mu_slope.R",
    "sim/run/sim_run_biv_gaussian_mu_slope_smoke.R",
    "sim/run/sim_summary_biv_gaussian_mu_slope_recovery.R",
    "sim/run/sim_write_biv_gaussian_mu_slope_recovery_grid.R"
  )
  for (file in files) {
    source(system.file(file, package = "drmTMB", mustWork = TRUE), local = env)
  }
}

test_that("Phase 18 mu slope recovery reports bias, MCSE, and coverage", {
  source_phase18_biv_gaussian_mu_slope_recovery()

  result_dir <- tempfile("phase18-biv-gaussian-mu-slope-recovery-")
  dir.create(result_dir)
  withr::defer(unlink(result_dir, recursive = TRUE))
  conditions <- phase18_biv_gaussian_mu_slope_conditions(
    n_id = 36L,
    n_each = 6L
  )

  out <- phase18_summarise_biv_gaussian_mu_slope_recovery(
    conditions = conditions,
    n_rep = 4L,
    master_seed = 20260631L,
    result_dir = result_dir
  )

  expect_identical(out$surface, "biv_gaussian_mu_slope_recovery")

  # The recovery aggregate keeps the same 10 estimands as the smoke lane, now
  # with bias and Monte Carlo standard error populated over replicates.
  expect_equal(nrow(out$aggregate), 10L)
  expect_true(all(c("bias", "rmse", "empirical_se") %in% names(out$aggregate)))
  expect_true(all(c("bias_mcse", "rmse_mcse") %in% names(out$aggregate)))
  expect_true(any(is.finite(out$aggregate$bias)))
  expect_true(any(is.finite(out$aggregate$bias_mcse)))

  expect_true(is.data.frame(out$wald_coverage))
  expect_true(all(c("coverage", "coverage_mcse") %in% names(out$wald_coverage)))
  expect_true(is.data.frame(out$wald_intervals))
  expect_true(all(c("conf.low", "conf.high") %in% names(out$wald_intervals)))
})

test_that("Phase 18 mu slope recovery leaves SD and correlation Wald-unavailable", {
  source_phase18_biv_gaussian_mu_slope_recovery()

  result_dir <- tempfile("phase18-biv-gaussian-mu-slope-recovery-")
  dir.create(result_dir)
  withr::defer(unlink(result_dir, recursive = TRUE))

  out <- phase18_summarise_biv_gaussian_mu_slope_recovery(
    conditions = phase18_biv_gaussian_mu_slope_conditions(
      n_id = 36L,
      n_each = 6L
    ),
    n_rep = 4L,
    master_seed = 20260631L,
    result_dir = result_dir
  )

  # The two slope random-effect SDs and the derived slope-slope correlation have
  # no Wald standard error, so their interval endpoints stay NA rather than
  # being reported as interval-ready.
  intervals <- out$wald_intervals
  derived <- grepl("^sd:|^cor:", intervals$parameter)
  expect_true(any(derived))
  expect_true(all(is.na(intervals$conf.low[derived])))
  expect_true(all(is.na(intervals$conf.high[derived])))
})

test_that("Phase 18 mu slope recovery grid writer emits coverage tables", {
  source_phase18_biv_gaussian_mu_slope_recovery()

  output_dir <- tempfile("phase18-biv-gaussian-mu-slope-recovery-grid-")
  withr::defer(unlink(output_dir, recursive = TRUE))

  out <- phase18_write_biv_gaussian_mu_slope_recovery_grid_outputs(
    output_dir = output_dir,
    conditions = phase18_biv_gaussian_mu_slope_conditions(
      n_id = 36L,
      n_each = 6L
    ),
    n_rep = 4L,
    master_seed = 20260631L,
    overwrite = FALSE
  )

  expect_identical(out$surface, "biv_gaussian_mu_slope_recovery_grid")
  for (path in unlist(out$paths, use.names = FALSE)) {
    expect_true(file.exists(path))
  }
  aggregate <- utils::read.csv(out$paths$aggregate_csv)
  expect_equal(nrow(aggregate), 10L)
  expect_true("bias" %in% names(aggregate))

  expect_error(
    phase18_write_biv_gaussian_mu_slope_recovery_grid_outputs(
      output_dir = output_dir,
      n_rep = 4L,
      master_seed = 20260631L,
      overwrite = FALSE
    ),
    "already exists"
  )
})
