source_phase18_proportion_fe <- function(env = parent.frame()) {
  paths <- c(
    "sim/R/sim_registry.R",
    "sim/R/sim_utils.R",
    "sim/R/sim_runner.R",
    "sim/R/sim_aggregate.R",
    "sim/R/sim_uncertainty.R",
    "sim/dgp/sim_dgp_proportion_fixed_effect.R",
    "sim/fit/sim_summarise_proportion_fixed_effect.R",
    "sim/run/sim_run_proportion_fixed_effect_smoke.R",
    "sim/run/sim_summary_proportion_fixed_effect_smoke.R",
    "sim/run/sim_write_proportion_fixed_effect_grid.R"
  )
  for (path in paths) {
    source(system.file(path, package = "drmTMB", mustWork = TRUE), local = env)
  }
}

test_that("Phase 18 proportion fixed-effect DGP separates beta and beta-binomial data", {
  source_phase18_proportion_fe()

  beta_dat <- phase18_dgp_proportion_fe(
    n = 80L,
    family = "beta",
    seed = 1001L
  )
  beta_binomial_dat <- phase18_dgp_proportion_fe(
    n = 80L,
    family = "beta_binomial",
    trial_min = 10L,
    trial_max = 16L,
    seed = 1002L
  )

  expect_true(all(beta_dat$prop > 0))
  expect_true(all(beta_dat$prop < 1))
  expect_false("success" %in% names(beta_dat))
  expect_true(all(beta_binomial_dat$success >= 0L))
  expect_equal(
    beta_binomial_dat$success + beta_binomial_dat$failure,
    beta_binomial_dat$trials
  )
  expect_true(all(beta_binomial_dat$trials >= 10L))
  expect_true(all(beta_binomial_dat$trials <= 16L))
  expect_equal(attr(beta_dat, "truth")$family, "beta")
  expect_equal(attr(beta_binomial_dat, "truth")$family, "beta_binomial")
})

test_that("Phase 18 proportion fixed-effect smoke returns Wald artifacts", {
  source_phase18_proportion_fe()
  conditions <- phase18_proportion_fe_conditions(
    family = c("beta", "beta_binomial"),
    n = 320L,
    trial_min = 12L,
    trial_max = 24L,
    beta_sigma_intercept = -0.90,
    beta_sigma_z = 0.15,
    rho_xz = 0.10
  )

  summary <- phase18_summarise_proportion_fe_smoke(
    conditions = conditions,
    n_rep = 1L,
    master_seed = 2021L
  )

  expect_equal(summary$surface, "proportion_fixed_effect")
  expect_equal(nrow(summary$replicates), 8L)
  expect_equal(nrow(summary$aggregate), 8L)
  expect_equal(nrow(summary$manifest), 2L)
  expect_equal(nrow(summary$failures), 0L)
  expect_equal(nrow(summary$wald_intervals), 8L)
  expect_equal(nrow(summary$wald_coverage), 8L)
  expect_setequal(summary$replicates$family, c("beta", "beta_binomial"))
  expect_equal(summary$replicates$artifact_grain, rep("replicate", 8L))
  expect_equal(summary$aggregate$artifact_grain, rep("aggregate", 8L))
  expect_equal(
    unique(summary$wald_intervals$interval_scale),
    "formula_coefficient"
  )
  expect_true(all(summary$wald_intervals$interval_status == "ok"))
})

test_that("Phase 18 proportion fixed-effect grid writer creates table artifacts", {
  source_phase18_proportion_fe()
  output_dir <- tempfile("phase18-proportion-fe-grid-")
  withr::defer(unlink(output_dir, recursive = TRUE))
  conditions <- phase18_proportion_fe_conditions(
    family = c("beta", "beta_binomial"),
    n = 320L,
    trial_min = 12L,
    trial_max = 24L,
    beta_sigma_intercept = -0.90,
    beta_sigma_z = 0.15,
    rho_xz = 0.10
  )

  out <- phase18_write_proportion_fe_grid_outputs(
    output_dir = output_dir,
    conditions = conditions,
    n_rep = 1L,
    master_seed = 2022L,
    cores = 10L
  )

  expect_equal(out$surface, "proportion_fixed_effect_grid")
  expect_equal(out$summary$run$parallel$backend, "none")
  expect_equal(out$summary$run$parallel$requested_cores, 10L)
  expect_equal(out$summary$run$parallel$cores, 1L)
  expect_true(dir.exists(out$result_dir))
  expect_true(dir.exists(out$table_dir))
  expect_true(all(file.exists(unlist(out$paths, use.names = FALSE))))
  expect_equal(nrow(out$summary$replicates), 8L)
  expect_equal(nrow(out$summary$aggregate), 8L)
  expect_equal(nrow(utils::read.csv(out$paths$replicate_csv)), 8L)
  expect_error(
    phase18_write_proportion_fe_grid_outputs(
      output_dir = output_dir,
      conditions = conditions,
      n_rep = 1L,
      master_seed = 2022L
    ),
    "already exists"
  )
  expect_silent(phase18_write_proportion_fe_grid_outputs(
    output_dir = output_dir,
    conditions = conditions,
    n_rep = 1L,
    master_seed = 2022L,
    overwrite = TRUE
  ))
})

test_that("Phase 18 proportion fixed-effect helpers reject malformed inputs", {
  source_phase18_proportion_fe()

  expect_error(
    phase18_proportion_fe_conditions(family = "binomial"),
    "family"
  )
  expect_error(
    phase18_proportion_fe_conditions(trial_min = 12L, trial_max = 8L),
    "trial_min"
  )
  expect_error(
    phase18_dgp_proportion_fe(
      n = 80L,
      family = "beta_binomial",
      trial_min = 12L,
      trial_max = 8L
    ),
    "trial_min"
  )
  expect_error(
    phase18_write_proportion_fe_grid_outputs(output_dir = ""),
    "output_dir"
  )
})
