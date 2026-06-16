source_phase18_binomial_fe <- function(env = parent.frame()) {
  paths <- c(
    "sim/R/sim_registry.R",
    "sim/R/sim_utils.R",
    "sim/R/sim_runner.R",
    "sim/R/sim_aggregate.R",
    "sim/R/sim_uncertainty.R",
    "sim/dgp/sim_dgp_binomial_fixed_effect.R",
    "sim/fit/sim_summarise_binomial_fixed_effect.R",
    "sim/run/sim_run_binomial_fixed_effect_smoke.R",
    "sim/run/sim_summary_binomial_fixed_effect_smoke.R",
    "sim/run/sim_write_binomial_fixed_effect_grid.R"
  )
  for (path in paths) {
    source(system.file(path, package = "drmTMB", mustWork = TRUE), local = env)
  }
}

test_that("Phase 18 binomial fixed-effect DGP separates encodings", {
  source_phase18_binomial_fe()

  binary_dat <- phase18_dgp_binomial_fe(
    n = 80L,
    encoding = "binary",
    seed = 1001L
  )
  cbind_dat <- phase18_dgp_binomial_fe(
    n = 80L,
    encoding = "cbind",
    trial_min = 10L,
    trial_max = 16L,
    seed = 1002L
  )

  expect_setequal(binary_dat$y01, c(0L, 1L))
  expect_false("success" %in% names(binary_dat))
  expect_true(all(cbind_dat$success >= 0L))
  expect_equal(cbind_dat$success + cbind_dat$failure, cbind_dat$trials)
  expect_true(all(cbind_dat$trials >= 10L))
  expect_true(all(cbind_dat$trials <= 16L))
  expect_equal(attr(binary_dat, "truth")$encoding, "binary")
  expect_equal(attr(cbind_dat, "truth")$encoding, "cbind")
})

test_that("Phase 18 binomial fixed-effect smoke records glm parity", {
  source_phase18_binomial_fe()
  conditions <- phase18_binomial_fe_conditions(
    encoding = c("binary", "cbind"),
    n = 320L,
    trial_min = 12L,
    trial_max = 24L
  )

  summary <- phase18_summarise_binomial_fe_smoke(
    conditions = conditions,
    n_rep = 1L,
    master_seed = 2021L
  )

  expect_equal(summary$surface, "binomial_fixed_effect")
  expect_equal(nrow(summary$replicates), 4L)
  expect_equal(nrow(summary$aggregate), 4L)
  expect_equal(nrow(summary$manifest), 2L)
  expect_equal(nrow(summary$failures), 0L)
  expect_equal(nrow(summary$wald_intervals), 4L)
  expect_equal(nrow(summary$wald_coverage), 4L)
  expect_equal(nrow(summary$comparator_parity), 4L)
  expect_setequal(summary$replicates$encoding, c("binary", "cbind"))
  expect_equal(summary$replicates$artifact_grain, rep("replicate", 4L))
  expect_equal(summary$aggregate$artifact_grain, rep("aggregate", 4L))
  expect_equal(unique(summary$comparator_parity$comparator), "stats::glm")
  expect_setequal(summary$comparator_parity$encoding, c("binary", "cbind"))
  expect_true(all(abs(summary$replicates$drmtmb_glm_diff) < 1e-8))
  expect_true(all(abs(summary$replicates$logLik_diff) < 1e-8))
  expect_true(all(abs(summary$replicates$AIC_diff) < 1e-8))
  expect_true(all(abs(summary$replicates$BIC_diff) < 1e-8))
  expect_equal(
    unique(summary$wald_intervals$interval_scale),
    "formula_coefficient"
  )
  expect_true(all(summary$wald_intervals$interval_status == "ok"))
})

test_that("Phase 18 binomial fixed-effect grid writer creates table artifacts", {
  source_phase18_binomial_fe()
  output_dir <- tempfile("phase18-binomial-fe-grid-")
  withr::defer(unlink(output_dir, recursive = TRUE))
  conditions <- phase18_binomial_fe_conditions(
    encoding = c("binary", "cbind"),
    n = 320L,
    trial_min = 12L,
    trial_max = 24L
  )

  out <- phase18_write_binomial_fe_grid_outputs(
    output_dir = output_dir,
    conditions = conditions,
    n_rep = 1L,
    master_seed = 2022L,
    cores = 10L
  )

  expect_equal(out$surface, "binomial_fixed_effect_grid")
  expect_equal(out$summary$run$parallel$backend, "none")
  expect_equal(out$summary$run$parallel$requested_cores, 10L)
  expect_equal(out$summary$run$parallel$cores, 1L)
  expect_true(dir.exists(out$result_dir))
  expect_true(dir.exists(out$table_dir))
  expect_true(all(file.exists(unlist(out$paths, use.names = FALSE))))
  expect_equal(nrow(out$summary$replicates), 4L)
  expect_equal(nrow(out$summary$aggregate), 4L)
  expect_equal(nrow(utils::read.csv(out$paths$replicate_csv)), 4L)
  expect_equal(nrow(utils::read.csv(out$paths$comparator_parity_csv)), 4L)
  expect_error(
    phase18_write_binomial_fe_grid_outputs(
      output_dir = output_dir,
      conditions = conditions,
      n_rep = 1L,
      master_seed = 2022L
    ),
    "already exists"
  )
  expect_silent(phase18_write_binomial_fe_grid_outputs(
    output_dir = output_dir,
    conditions = conditions,
    n_rep = 1L,
    master_seed = 2022L,
    overwrite = TRUE
  ))
})

test_that("Phase 18 binomial fixed-effect helpers reject malformed inputs", {
  source_phase18_binomial_fe()

  expect_error(
    phase18_binomial_fe_conditions(encoding = "beta_binomial"),
    "encoding"
  )
  expect_error(
    phase18_binomial_fe_conditions(trial_min = 12L, trial_max = 8L),
    "trial_min"
  )
  expect_error(
    phase18_dgp_binomial_fe(
      n = 80L,
      encoding = "cbind",
      trial_min = 12L,
      trial_max = 8L
    ),
    "trial_min"
  )
  expect_error(
    phase18_write_binomial_fe_grid_outputs(output_dir = ""),
    "output_dir"
  )
})
