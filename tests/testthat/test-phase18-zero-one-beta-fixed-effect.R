source_phase18_zero_one_beta_fe <- function(env = parent.frame()) {
  paths <- c(
    "sim/R/sim_registry.R",
    "sim/R/sim_utils.R",
    "sim/R/sim_runner.R",
    "sim/R/sim_aggregate.R",
    "sim/R/sim_uncertainty.R",
    "sim/dgp/sim_dgp_zero_one_beta_fixed_effect.R",
    "sim/fit/sim_summarise_zero_one_beta_fixed_effect.R",
    "sim/run/sim_run_zero_one_beta_fixed_effect_smoke.R",
    "sim/run/sim_summary_zero_one_beta_fixed_effect_smoke.R",
    "sim/run/sim_write_zero_one_beta_fixed_effect_grid.R"
  )
  for (path in paths) {
    source(system.file(path, package = "drmTMB", mustWork = TRUE), local = env)
  }
}

test_that("Phase 18 zero-one beta DGP generates interior and exact-boundary data", {
  source_phase18_zero_one_beta_fe()

  dat <- phase18_dgp_zero_one_beta_fe(
    n = 300L,
    beta_zoi = c("(Intercept)" = -0.70, w = 0.25),
    seed = 1201L
  )

  expect_true(all(dat$prop >= 0))
  expect_true(all(dat$prop <= 1))
  expect_true(any(dat$prop == 0))
  expect_true(any(dat$prop == 1))
  expect_true(any(dat$prop > 0 & dat$prop < 1))
  expect_true(all(dat$response_mean >= 0))
  expect_true(all(dat$response_mean <= 1))
  expect_equal(attr(dat, "truth")$surface, "zero_one_beta_fixed_effect")
  expect_named(attr(dat, "truth")$beta_zoi, c("(Intercept)", "w"))
  expect_named(attr(dat, "truth")$beta_coi, c("(Intercept)", "v"))
})

test_that("Phase 18 zero-one beta smoke returns Wald artifacts", {
  source_phase18_zero_one_beta_fe()
  conditions <- phase18_zero_one_beta_fe_conditions(
    n = 420L,
    beta_sigma_intercept = -0.80,
    beta_sigma_z = 0.15,
    beta_zoi_intercept = -1.15,
    beta_zoi_w = 0.25,
    beta_coi_intercept = 0.10,
    beta_coi_v = -0.25,
    rho_xz = 0.10
  )

  summary <- phase18_summarise_zero_one_beta_fe_smoke(
    conditions = conditions,
    n_rep = 1L,
    master_seed = 2041L
  )

  expect_equal(summary$surface, "zero_one_beta_fixed_effect")
  expect_equal(nrow(summary$replicates), 8L)
  expect_equal(nrow(summary$aggregate), 8L)
  expect_equal(nrow(summary$manifest), 1L)
  expect_equal(nrow(summary$failures), 0L)
  expect_equal(nrow(summary$wald_intervals), 8L)
  expect_equal(nrow(summary$wald_coverage), 8L)
  expect_equal(summary$replicates$artifact_grain, rep("replicate", 8L))
  expect_equal(summary$aggregate$artifact_grain, rep("aggregate", 8L))
  expect_equal(
    unique(summary$wald_intervals$interval_scale),
    "formula_coefficient"
  )
  expect_true(all(summary$wald_intervals$interval_status == "ok"))
  expect_setequal(
    sub(":.*", "", summary$replicates$parameter),
    c("mu", "sigma", "zoi", "coi")
  )
})

test_that("Phase 18 zero-one beta grid writer creates table artifacts", {
  source_phase18_zero_one_beta_fe()
  output_dir <- tempfile("phase18-zero-one-beta-fe-grid-")
  withr::defer(unlink(output_dir, recursive = TRUE))
  conditions <- phase18_zero_one_beta_fe_conditions(
    n = 420L,
    beta_sigma_intercept = -0.80,
    beta_sigma_z = 0.15,
    beta_zoi_intercept = -1.15,
    beta_zoi_w = 0.25,
    beta_coi_intercept = 0.10,
    beta_coi_v = -0.25,
    rho_xz = 0.10
  )

  out <- phase18_write_zero_one_beta_fe_grid_outputs(
    output_dir = output_dir,
    conditions = conditions,
    n_rep = 1L,
    master_seed = 2042L,
    cores = 10L
  )

  expect_equal(out$surface, "zero_one_beta_fixed_effect_grid")
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
    phase18_write_zero_one_beta_fe_grid_outputs(
      output_dir = output_dir,
      conditions = conditions,
      n_rep = 1L,
      master_seed = 2042L
    ),
    "already exists"
  )
  expect_silent(phase18_write_zero_one_beta_fe_grid_outputs(
    output_dir = output_dir,
    conditions = conditions,
    n_rep = 1L,
    master_seed = 2042L,
    overwrite = TRUE
  ))
})

test_that("Phase 18 zero-one beta helpers reject malformed inputs", {
  source_phase18_zero_one_beta_fe()

  expect_error(
    phase18_dgp_zero_one_beta_fe(n = 0L),
    "n"
  )
  expect_error(
    phase18_dgp_zero_one_beta_fe(
      n = 80L,
      beta_zoi = c("(Intercept)" = -1, bad = 0.1)
    ),
    "beta_zoi"
  )
  expect_error(
    phase18_dgp_zero_one_beta_fe(n = 80L, rho_xz = 2),
    "rho_xz"
  )
  expect_error(
    phase18_write_zero_one_beta_fe_grid_outputs(output_dir = ""),
    "output_dir"
  )
})
