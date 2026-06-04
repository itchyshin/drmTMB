source_phase18_nbinom2_mu_re_recovery <- function() {
  env <- parent.frame()
  files <- c(
    "sim/R/sim_registry.R",
    "sim/R/sim_utils.R",
    "sim/R/sim_runner.R",
    "sim/R/sim_aggregate.R",
    "sim/R/sim_uncertainty.R",
    "sim/dgp/sim_dgp_nbinom2_mu_random_effect.R",
    "sim/fit/sim_summarise_nbinom2_mu_random_effect.R",
    "sim/run/sim_run_nbinom2_mu_random_effect_smoke.R",
    "sim/run/sim_summary_nbinom2_mu_random_effect_smoke.R",
    "sim/run/sim_write_nbinom2_mu_re_recovery_grid.R"
  )
  for (file in files) {
    source(system.file(file, package = "drmTMB", mustWork = TRUE), local = env)
  }
}

test_that("Phase 18 NB2 mu random-effect recovery summary carries coverage", {
  source_phase18_nbinom2_mu_re_recovery()

  result_dir <- tempfile("phase18-nbinom2-mu-re-recovery-")
  dir.create(result_dir)
  withr::defer(unlink(result_dir, recursive = TRUE))

  out <- phase18_summarise_nbinom2_mu_re_smoke(
    conditions = phase18_nbinom2_mu_re_conditions(
      n_group = 44L,
      n_per_group = 10L
    ),
    n_rep = 3L,
    master_seed = 20260633L,
    result_dir = result_dir
  )

  expect_identical(out$surface, "nbinom2_mu_random_effect")
  expect_equal(nrow(out$aggregate), 6L)
  expect_true(all(c("bias", "rmse", "empirical_se") %in% names(out$aggregate)))
  expect_true(all(c("bias_mcse", "rmse_mcse") %in% names(out$aggregate)))
  expect_true(any(is.finite(out$aggregate$bias)))
  expect_true(is.data.frame(out$wald_coverage))
  expect_true(all(c("coverage", "coverage_mcse") %in% names(out$wald_coverage)))
  expect_true(is.data.frame(out$profile_coverage))
})

test_that("Phase 18 NB2 mu random-effect recovery grid writer emits artifacts", {
  source_phase18_nbinom2_mu_re_recovery()

  output_dir <- tempfile("phase18-nbinom2-mu-re-recovery-grid-")
  withr::defer(unlink(output_dir, recursive = TRUE))

  out <- phase18_write_nbinom2_mu_re_recovery_grid_outputs(
    output_dir = output_dir,
    conditions = phase18_nbinom2_mu_re_conditions(
      n_group = 44L,
      n_per_group = 10L
    ),
    n_rep = 3L,
    master_seed = 20260633L,
    overwrite = FALSE
  )

  expect_identical(out$surface, "nbinom2_mu_re_recovery_grid")
  for (path in unlist(out$paths, use.names = FALSE)) {
    expect_true(file.exists(path))
  }
  aggregate <- utils::read.csv(out$paths$aggregate_csv)
  expect_equal(nrow(aggregate), 6L)
  expect_true("bias" %in% names(aggregate))

  expect_error(
    phase18_write_nbinom2_mu_re_recovery_grid_outputs(
      output_dir = output_dir,
      n_rep = 3L,
      master_seed = 20260633L,
      overwrite = FALSE
    ),
    "already exists"
  )
})
