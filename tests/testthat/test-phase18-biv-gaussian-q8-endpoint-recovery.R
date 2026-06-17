source_phase18_biv_gaussian_q8_endpoint_recovery <- function() {
  env <- parent.frame()
  files <- c(
    "sim/R/sim_registry.R",
    "sim/R/sim_utils.R",
    "sim/R/sim_runner.R",
    "sim/R/sim_aggregate.R",
    "sim/R/sim_uncertainty.R",
    "sim/dgp/sim_dgp_biv_gaussian_q8_endpoint.R",
    "sim/fit/sim_summarise_biv_gaussian_q8_endpoint.R",
    "sim/run/sim_run_biv_gaussian_q8_endpoint_smoke.R",
    "sim/run/sim_summary_biv_gaussian_q8_endpoint_recovery.R",
    "sim/run/sim_write_biv_gaussian_q8_endpoint_recovery_grid.R"
  )
  for (file in files) {
    source(system.file(file, package = "drmTMB", mustWork = TRUE), local = env)
  }
}

test_that("Phase 18 q8 endpoint recovery reports bias and MCSE", {
  source_phase18_biv_gaussian_q8_endpoint_recovery()

  result_dir <- tempfile("phase18-biv-gaussian-q8-endpoint-recovery-")
  dir.create(result_dir)
  withr::defer(unlink(result_dir, recursive = TRUE))

  out <- phase18_summarise_biv_gaussian_q8_endpoint_recovery(
    conditions = phase18_biv_gaussian_q8_endpoint_conditions(
      n_id = 48L,
      n_each = 10L
    ),
    n_rep = 2L,
    master_seed = 20260635L,
    result_dir = result_dir
  )

  expect_identical(out$surface, "biv_gaussian_q8_endpoint_recovery")
  expect_equal(nrow(out$aggregate), 45L)
  expect_true(all(c("bias", "rmse", "empirical_se") %in% names(out$aggregate)))
  expect_true(all(c("bias_mcse", "rmse_mcse") %in% names(out$aggregate)))
  expect_true(any(is.finite(out$aggregate$bias)))
  expect_true(any(is.finite(out$aggregate$bias_mcse)))
  expect_equal(nrow(out$replicates), 90L)
  expect_equal(nrow(out$manifest), 2L)
})

test_that("Phase 18 q8 endpoint recovery records interval unavailability", {
  source_phase18_biv_gaussian_q8_endpoint_recovery()

  result_dir <- tempfile("phase18-biv-gaussian-q8-endpoint-recovery-")
  dir.create(result_dir)
  withr::defer(unlink(result_dir, recursive = TRUE))

  out <- phase18_summarise_biv_gaussian_q8_endpoint_recovery(
    conditions = phase18_biv_gaussian_q8_endpoint_conditions(
      n_id = 48L,
      n_each = 10L
    ),
    n_rep = 2L,
    master_seed = 20260635L,
    result_dir = result_dir
  )

  expect_true(is.data.frame(out$wald_coverage))
  expect_true(all(c("coverage", "coverage_mcse") %in% names(out$wald_coverage)))
  expect_true(is.data.frame(out$wald_intervals))
  expect_true(all(c("conf.low", "conf.high") %in% names(out$wald_intervals)))
  expect_true(all(is.na(out$wald_intervals$conf.low)))
  expect_true(all(is.na(out$wald_intervals$conf.high)))
  expect_true(all(out$wald_intervals$interval_status == "failed"))
  expect_true(all(out$wald_coverage$n_interval == 0L))
  expect_true(nrow(out$interval_failures) > 0L)
})

test_that("Phase 18 q8 endpoint recovery grid writer emits interval tables", {
  source_phase18_biv_gaussian_q8_endpoint_recovery()

  output_dir <- tempfile("phase18-biv-gaussian-q8-endpoint-recovery-grid-")
  withr::defer(unlink(output_dir, recursive = TRUE))

  out <- phase18_write_biv_gaussian_q8_endpoint_recovery_grid_outputs(
    output_dir = output_dir,
    conditions = phase18_biv_gaussian_q8_endpoint_conditions(
      n_id = 48L,
      n_each = 10L
    ),
    n_rep = 2L,
    master_seed = 20260635L,
    overwrite = FALSE
  )

  expect_identical(out$surface, "biv_gaussian_q8_endpoint_recovery_grid")
  for (path in unlist(out$paths, use.names = FALSE)) {
    expect_true(file.exists(path))
  }
  aggregate <- utils::read.csv(out$paths$aggregate_csv)
  intervals <- utils::read.csv(out$paths$wald_intervals_csv)
  expect_equal(nrow(aggregate), 45L)
  expect_equal(nrow(intervals), 90L)
  expect_true("bias" %in% names(aggregate))
  expect_true(all(intervals$interval_status == "failed"))

  expect_error(
    phase18_write_biv_gaussian_q8_endpoint_recovery_grid_outputs(
      output_dir = output_dir,
      n_rep = 2L,
      master_seed = 20260635L,
      overwrite = FALSE
    ),
    "already exists"
  )
})
