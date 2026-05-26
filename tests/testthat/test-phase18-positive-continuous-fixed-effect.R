source_phase18_positive_continuous_fe <- function(env = parent.frame()) {
  paths <- c(
    "sim/R/sim_registry.R",
    "sim/R/sim_utils.R",
    "sim/R/sim_runner.R",
    "sim/R/sim_aggregate.R",
    "sim/R/sim_uncertainty.R",
    "sim/dgp/sim_dgp_positive_continuous_fixed_effect.R",
    "sim/fit/sim_summarise_positive_continuous_fixed_effect.R",
    "sim/run/sim_run_positive_continuous_fixed_effect_smoke.R",
    "sim/run/sim_summary_positive_continuous_fixed_effect_smoke.R",
    "sim/run/sim_write_positive_continuous_fixed_effect_grid.R"
  )
  for (path in paths) {
    source(system.file(path, package = "drmTMB", mustWork = TRUE), local = env)
  }
}

test_that("Phase 18 positive-continuous DGP separates lognormal and Gamma data", {
  source_phase18_positive_continuous_fe()

  lognormal_dat <- phase18_dgp_positive_continuous_fe(
    n = 80L,
    family = "lognormal",
    seed = 1101L
  )
  gamma_dat <- phase18_dgp_positive_continuous_fe(
    n = 80L,
    family = "gamma",
    seed = 1102L
  )

  expect_true(all(lognormal_dat$y > 0))
  expect_true(all(gamma_dat$y > 0))
  expect_equal(attr(lognormal_dat, "truth")$family, "lognormal")
  expect_equal(attr(gamma_dat, "truth")$family, "gamma")
  expect_equal(lognormal_dat$mu, lognormal_dat$eta_mu)
  expect_equal(gamma_dat$mu, exp(gamma_dat$eta_mu))
  expect_equal(gamma_dat$response_mean, gamma_dat$mu)
})

test_that("Phase 18 positive-continuous smoke returns Wald artifacts", {
  source_phase18_positive_continuous_fe()
  conditions <- phase18_positive_continuous_fe_conditions(
    family = c("lognormal", "gamma"),
    n = 320L,
    beta_sigma_intercept = -0.75,
    beta_sigma_z = 0.15,
    rho_xz = 0.10
  )

  summary <- phase18_summarise_positive_continuous_fe_smoke(
    conditions = conditions,
    n_rep = 1L,
    master_seed = 2031L
  )

  expect_equal(summary$surface, "positive_continuous_fixed_effect")
  expect_equal(nrow(summary$replicates), 8L)
  expect_equal(nrow(summary$aggregate), 8L)
  expect_equal(nrow(summary$manifest), 2L)
  expect_equal(nrow(summary$failures), 0L)
  expect_equal(nrow(summary$wald_intervals), 8L)
  expect_equal(nrow(summary$wald_coverage), 8L)
  expect_setequal(summary$replicates$family, c("lognormal", "gamma"))
  expect_equal(summary$replicates$artifact_grain, rep("replicate", 8L))
  expect_equal(summary$aggregate$artifact_grain, rep("aggregate", 8L))
  expect_equal(
    unique(summary$wald_intervals$interval_scale),
    "formula_coefficient"
  )
  expect_true(all(summary$wald_intervals$interval_status == "ok"))
})

test_that("Phase 18 positive-continuous grid writer creates table artifacts", {
  source_phase18_positive_continuous_fe()
  output_dir <- tempfile("phase18-positive-continuous-fe-grid-")
  withr::defer(unlink(output_dir, recursive = TRUE))
  conditions <- phase18_positive_continuous_fe_conditions(
    family = c("lognormal", "gamma"),
    n = 320L,
    beta_sigma_intercept = -0.75,
    beta_sigma_z = 0.15,
    rho_xz = 0.10
  )

  out <- phase18_write_positive_continuous_fe_grid_outputs(
    output_dir = output_dir,
    conditions = conditions,
    n_rep = 1L,
    master_seed = 2032L,
    cores = 10L
  )

  expect_equal(out$surface, "positive_continuous_fixed_effect_grid")
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
    phase18_write_positive_continuous_fe_grid_outputs(
      output_dir = output_dir,
      conditions = conditions,
      n_rep = 1L,
      master_seed = 2032L
    ),
    "already exists"
  )
  expect_silent(phase18_write_positive_continuous_fe_grid_outputs(
    output_dir = output_dir,
    conditions = conditions,
    n_rep = 1L,
    master_seed = 2032L,
    overwrite = TRUE
  ))
})

test_that("Phase 18 positive-continuous helpers reject malformed inputs", {
  source_phase18_positive_continuous_fe()

  expect_error(
    phase18_positive_continuous_fe_conditions(family = "weibull"),
    "family"
  )
  expect_error(
    phase18_dgp_positive_continuous_fe(n = 0L, family = "lognormal"),
    "n"
  )
  expect_error(
    phase18_dgp_positive_continuous_fe(
      n = 80L,
      family = "gamma",
      rho_xz = 2
    ),
    "rho_xz"
  )
  expect_error(
    phase18_write_positive_continuous_fe_grid_outputs(output_dir = ""),
    "output_dir"
  )
})
