source_phase18_interval_heavy_summary_smoke_runner <- function(
  env = parent.frame()
) {
  paths <- c(
    "sim/R/sim_registry.R",
    "sim/R/sim_utils.R",
    "sim/R/sim_runner.R",
    "sim/R/sim_aggregate.R",
    "sim/R/sim_uncertainty.R",
    "sim/R/sim_bootstrap.R",
    "sim/dgp/sim_dgp_student_shape.R",
    "sim/dgp/sim_dgp_biv_rho12.R",
    "sim/fit/sim_summarise_student_shape.R",
    "sim/fit/sim_summarise_biv_rho12.R",
    "sim/run/sim_run_student_shape_smoke.R",
    "sim/run/sim_run_biv_rho12_smoke.R",
    "sim/run/sim_summary_student_shape_smoke.R",
    "sim/run/sim_summary_biv_rho12_smoke.R",
    "sim/run/sim_write_student_shape_grid.R",
    "sim/run/sim_write_biv_rho12_grid.R",
    "sim/run/sim_write_first_wave_artifact_status.R",
    "sim/run/sim_write_first_wave_table_bundle.R",
    "sim/run/sim_render_first_wave_summary_report.R",
    "sim/run/sim_run_interval_heavy_summary_smoke.R"
  )
  for (path in paths) {
    source(system.file(path, package = "drmTMB", mustWork = TRUE), local = env)
  }
}

test_that("Phase 18 interval-heavy summary smoke runner stages outputs", {
  source_phase18_interval_heavy_summary_smoke_runner()
  output_dir <- tempfile("phase18-interval-heavy-summary-smoke-runner-")
  withr::defer(unlink(output_dir, recursive = TRUE))

  out <- phase18_run_interval_heavy_summary_smoke(
    output_dir = output_dir,
    n_rep = 1L,
    master_seed = 958L,
    cores = 10L,
    backend = "none",
    render = FALSE,
    notes = "interval-heavy runner test"
  )

  expect_equal(out$surface, "phase18_interval_heavy_summary_smoke")
  expect_null(out$report$report_path)
  expect_true(file.exists(out$paths$parallel_summary_csv))
  expect_equal(nrow(out$parallel_summary), 2L)
  expect_setequal(
    out$parallel_summary$surface,
    c("student_shape_grid", "biv_rho12_grid")
  )
  expect_equal(out$parallel_summary$requested_cores, rep(10L, 2L))
  expect_equal(out$parallel_summary$cores, rep(1L, 2L))
  expect_true(file.exists(out$report$status$paths$artifact_status_csv))
  expect_true(file.exists(out$report$tables$paths$aggregate_csv))
  expect_equal(nrow(out$report$tables$tables$aggregate_csv), 16L)
  expect_equal(nrow(out$report$tables$tables$wald_coverage_csv), 16L)
})

test_that("Phase 18 interval-heavy summary smoke runner validates inputs", {
  source_phase18_interval_heavy_summary_smoke_runner()

  expect_error(
    phase18_run_interval_heavy_summary_smoke(output_dir = ""),
    "output_dir"
  )
  expect_error(
    phase18_run_interval_heavy_summary_smoke(
      output_dir = tempfile(),
      n_rep = 0L
    ),
    "n_rep"
  )
  expect_error(
    phase18_run_interval_heavy_summary_smoke(
      output_dir = tempfile(),
      master_seed = NA_integer_
    ),
    "master_seed"
  )
  expect_error(
    phase18_run_interval_heavy_summary_smoke(
      output_dir = tempfile(),
      notes = NA_character_
    ),
    "notes"
  )
})
