source_phase18_first_wave_summary_smoke_runner <- function(
  env = parent.frame()
) {
  paths <- c(
    "sim/R/sim_registry.R",
    "sim/R/sim_utils.R",
    "sim/R/sim_runner.R",
    "sim/R/sim_aggregate.R",
    "sim/R/sim_uncertainty.R",
    "sim/dgp/sim_dgp_gaussian_ls.R",
    "sim/dgp/sim_dgp_meta_v.R",
    "sim/dgp/sim_dgp_poisson_mu_random_effect.R",
    "sim/dgp/sim_dgp_nbinom2_mu_random_effect.R",
    "sim/dgp/sim_dgp_proportion_fixed_effect.R",
    "sim/dgp/sim_dgp_positive_continuous_fixed_effect.R",
    "sim/dgp/sim_dgp_ordinal_fixed_effect.R",
    "sim/dgp/sim_dgp_gaussian_mu_random_slope.R",
    "sim/dgp/sim_dgp_gaussian_sigma_random_slope.R",
    "sim/dgp/sim_dgp_spatial_mu_slope.R",
    "sim/fit/sim_summarise_gaussian_ls.R",
    "sim/fit/sim_summarise_meta_v.R",
    "sim/fit/sim_summarise_poisson_mu_random_effect.R",
    "sim/fit/sim_summarise_nbinom2_mu_random_effect.R",
    "sim/fit/sim_summarise_proportion_fixed_effect.R",
    "sim/fit/sim_summarise_positive_continuous_fixed_effect.R",
    "sim/fit/sim_summarise_ordinal_fixed_effect.R",
    "sim/fit/sim_summarise_gaussian_mu_random_slope.R",
    "sim/fit/sim_summarise_gaussian_sigma_random_slope.R",
    "sim/fit/sim_summarise_spatial_mu_slope.R",
    "sim/run/sim_run_gaussian_ls_smoke.R",
    "sim/run/sim_run_meta_v_smoke.R",
    "sim/run/sim_run_poisson_mu_random_effect_smoke.R",
    "sim/run/sim_run_nbinom2_mu_random_effect_smoke.R",
    "sim/run/sim_run_proportion_fixed_effect_smoke.R",
    "sim/run/sim_run_positive_continuous_fixed_effect_smoke.R",
    "sim/run/sim_run_ordinal_fixed_effect_smoke.R",
    "sim/run/sim_run_gaussian_mu_random_slope_smoke.R",
    "sim/run/sim_run_gaussian_sigma_random_slope_smoke.R",
    "sim/run/sim_run_spatial_mu_slope_smoke.R",
    "sim/run/sim_summary_gaussian_ls_smoke.R",
    "sim/run/sim_summary_meta_v_smoke.R",
    "sim/run/sim_summary_poisson_mu_random_effect_smoke.R",
    "sim/run/sim_summary_nbinom2_mu_random_effect_smoke.R",
    "sim/run/sim_summary_count_mu_random_effect_pilot.R",
    "sim/run/sim_summary_proportion_fixed_effect_smoke.R",
    "sim/run/sim_summary_positive_continuous_fixed_effect_smoke.R",
    "sim/run/sim_summary_ordinal_fixed_effect_smoke.R",
    "sim/run/sim_summary_gaussian_mu_random_slope_smoke.R",
    "sim/run/sim_summary_gaussian_sigma_random_slope_smoke.R",
    "sim/run/sim_summary_spatial_mu_slope_smoke.R",
    "sim/run/sim_write_gaussian_ls_grid.R",
    "sim/run/sim_write_meta_v_grid.R",
    "sim/run/sim_write_count_mu_random_effect_grid.R",
    "sim/run/sim_write_proportion_fixed_effect_grid.R",
    "sim/run/sim_write_positive_continuous_fixed_effect_grid.R",
    "sim/run/sim_write_ordinal_fixed_effect_grid.R",
    "sim/run/sim_write_gaussian_mu_random_slope_grid.R",
    "sim/run/sim_write_gaussian_sigma_random_slope_grid.R",
    "sim/run/sim_write_spatial_mu_slope_grid.R",
    "sim/run/sim_write_first_wave_artifact_status.R",
    "sim/run/sim_write_first_wave_table_bundle.R",
    "sim/run/sim_render_first_wave_summary_report.R",
    "sim/run/sim_run_first_wave_summary_smoke.R"
  )
  for (path in paths) {
    source(system.file(path, package = "drmTMB", mustWork = TRUE), local = env)
  }
}

test_that("Phase 18 first-wave summary smoke runner stages outputs", {
  source_phase18_first_wave_summary_smoke_runner()
  output_dir <- tempfile("phase18-first-wave-summary-smoke-runner-")
  withr::defer(unlink(output_dir, recursive = TRUE))

  out <- phase18_run_first_wave_summary_smoke(
    output_dir = output_dir,
    n_rep = 1L,
    master_seed = 889L,
    cores = 10L,
    backend = "none",
    render = FALSE,
    notes = "runner test"
  )

  expect_equal(out$surface, "phase18_first_wave_summary_smoke")
  expect_null(out$report$report_path)
  expect_true(file.exists(out$paths$parallel_summary_csv))
  expect_equal(nrow(out$parallel_summary), 10L)
  expect_setequal(
    out$parallel_summary$surface,
    c(
      "gaussian_ls_grid",
      "meta_v_grid",
      "poisson_mu_random_effect",
      "nbinom2_mu_random_effect",
      "proportion_fixed_effect_grid",
      "positive_continuous_fixed_effect_grid",
      "ordinal_fixed_effect_grid",
      "gaussian_mu_random_slope_grid",
      "gaussian_sigma_random_slope_grid",
      "spatial_mu_slope_grid"
    )
  )
  expect_equal(out$parallel_summary$requested_cores, rep(10L, 10L))
  expect_equal(out$parallel_summary$cores, rep(1L, 10L))
  expect_true(file.exists(out$report$status$paths$artifact_status_csv))
  expect_true(file.exists(out$report$tables$paths$aggregate_csv))
  expect_equal(nrow(out$report$tables$tables$aggregate_csv), 67L)
  expect_equal(nrow(out$report$tables$tables$wald_coverage_csv), 37L)
  expect_gt(nrow(out$report$tables$tables$profile_coverage_csv), 0L)
})

test_that("Phase 18 first-wave summary smoke runner validates inputs", {
  source_phase18_first_wave_summary_smoke_runner()

  expect_error(
    phase18_run_first_wave_summary_smoke(output_dir = ""),
    "output_dir"
  )
  expect_error(
    phase18_run_first_wave_summary_smoke(
      output_dir = tempfile(),
      n_rep = 0L
    ),
    "n_rep"
  )
  expect_error(
    phase18_run_first_wave_summary_smoke(
      output_dir = tempfile(),
      master_seed = NA_integer_
    ),
    "master_seed"
  )
  expect_error(
    phase18_run_first_wave_summary_smoke(
      output_dir = tempfile(),
      notes = NA_character_
    ),
    "notes"
  )
})
