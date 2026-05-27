source_phase18_student_mu_ri <- function(env = parent.frame()) {
  paths <- c(
    "sim/R/sim_registry.R",
    "sim/R/sim_utils.R",
    "sim/R/sim_runner.R",
    "sim/R/sim_aggregate.R",
    "sim/R/sim_uncertainty.R",
    "sim/dgp/sim_dgp_student_mu_random_intercept.R",
    "sim/fit/sim_summarise_student_mu_random_intercept.R",
    "sim/run/sim_run_student_mu_random_intercept_smoke.R",
    "sim/run/sim_summary_student_mu_random_intercept_smoke.R",
    "sim/run/sim_write_student_mu_random_intercept_grid.R"
  )
  for (path in paths) {
    source(system.file(path, package = "drmTMB", mustWork = TRUE), local = env)
  }
}

test_that("Phase 18 Student-t mu random-intercept DGP records shape truth", {
  source_phase18_student_mu_ri()

  dat <- phase18_dgp_student_mu_ri(
    n_group = 16L,
    n_per_group = 5L,
    beta_nu = c("(Intercept)" = log(8)),
    seed = 1379L
  )

  expect_equal(length(unique(dat$id)), 16L)
  expect_true(all(is.finite(dat$y)))
  expect_true(all(dat$sigma > 0))
  expect_true(all(dat$nu > 2))
  expect_equal(dat$nu, 2 + exp(dat$eta_nu))
  expect_equal(unique(dat$eta_nu), log(8), tolerance = 1e-12)
  expect_equal(
    attr(dat, "truth")$surface,
    "student_mu_random_intercept"
  )
  expect_equal(attr(dat, "truth")$beta_nu[["(Intercept)"]], log(8))
})

test_that("Phase 18 Student-t mu random-intercept smoke returns artifacts", {
  source_phase18_student_mu_ri()
  conditions <- phase18_student_mu_ri_conditions(
    n_group = 24L,
    n_per_group = 7L,
    beta_sigma_intercept = -0.42,
    beta_sigma_z = 0.18,
    beta_nu_intercept = log(c(5, 9)),
    sd_intercept = 0.45,
    rho_xz = 0.20
  )

  summary <- phase18_summarise_student_mu_ri_smoke(
    conditions = conditions,
    n_rep = 1L,
    master_seed = 2061L
  )

  expect_equal(summary$surface, "student_mu_random_intercept")
  expect_equal(nrow(summary$replicates), 12L)
  expect_equal(nrow(summary$aggregate), 12L)
  expect_equal(nrow(summary$manifest), 2L)
  expect_equal(nrow(summary$failures), 0L)
  expect_equal(nrow(summary$wald_intervals), 12L)
  expect_gte(nrow(summary$wald_coverage), 10L)
  expect_equal(nrow(summary$profile_intervals), 2L)
  expect_setequal(
    unique(summary$replicates$parameter_class),
    c("fixed_mu", "fixed_sigma", "fixed_nu", "random_sd")
  )
  expect_equal(summary$replicates$artifact_grain, rep("replicate", 12L))
  expect_equal(summary$aggregate$artifact_grain, rep("aggregate", 12L))
  expect_true(all(summary$manifest$status == "ok"))
  expect_equal(
    sum(
      summary$wald_intervals$interval_scale == "formula_coefficient" &
        summary$wald_intervals$interval_status == "ok"
    ),
    10L
  )
})

test_that("Phase 18 Student-t mu random-intercept grid writer creates artifacts", {
  source_phase18_student_mu_ri()
  output_dir <- tempfile("phase18-student-mu-ri-grid-")
  withr::defer(unlink(output_dir, recursive = TRUE))
  conditions <- phase18_student_mu_ri_conditions(
    n_group = 24L,
    n_per_group = 7L,
    beta_sigma_intercept = -0.42,
    beta_sigma_z = 0.18,
    beta_nu_intercept = log(c(5, 9)),
    sd_intercept = 0.45,
    rho_xz = 0.20
  )

  out <- phase18_write_student_mu_ri_grid_outputs(
    output_dir = output_dir,
    conditions = conditions,
    n_rep = 1L,
    master_seed = 2062L,
    cores = 10L
  )

  expect_equal(out$surface, "student_mu_random_intercept_grid")
  expect_equal(out$summary$run$parallel$backend, "none")
  expect_equal(out$summary$run$parallel$requested_cores, 10L)
  expect_equal(out$summary$run$parallel$cores, 1L)
  expect_equal(nrow(out$artifact_manifest), length(out$paths))
  expect_true(all(out$artifact_manifest$exists))
  expect_true(dir.exists(out$result_dir))
  expect_true(dir.exists(out$table_dir))
  expect_true(all(file.exists(unlist(out$paths, use.names = FALSE))))
  expect_equal(nrow(out$summary$replicates), 12L)
  expect_equal(nrow(out$summary$aggregate), 12L)
  expect_equal(nrow(utils::read.csv(out$paths$profile_intervals_csv)), 2L)
  expect_error(
    phase18_write_student_mu_ri_grid_outputs(
      output_dir = output_dir,
      conditions = conditions,
      n_rep = 1L,
      master_seed = 2062L
    ),
    "already exists"
  )
  expect_silent(phase18_write_student_mu_ri_grid_outputs(
    output_dir = output_dir,
    conditions = conditions,
    n_rep = 1L,
    master_seed = 2062L,
    overwrite = TRUE
  ))
})

test_that("Phase 18 Student-t mu random-intercept helpers reject malformed inputs", {
  source_phase18_student_mu_ri()

  expect_error(
    phase18_dgp_student_mu_ri(
      n_group = 0L,
      n_per_group = 5L
    ),
    "n_group"
  )
  expect_error(
    phase18_dgp_student_mu_ri(
      n_group = 10L,
      n_per_group = 5L,
      beta_nu = c("(Intercept)" = NA_real_)
    ),
    "beta_nu"
  )
  expect_error(
    phase18_dgp_student_mu_ri(
      n_group = 10L,
      n_per_group = 5L,
      sd = c("(1 | id)" = 0)
    ),
    "sd"
  )
  expect_error(
    phase18_write_student_mu_ri_grid_outputs(output_dir = ""),
    "output_dir"
  )
})
