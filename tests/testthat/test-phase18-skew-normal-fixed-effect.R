source_phase18_skew_normal_fe <- function(env = parent.frame()) {
  source(
    system.file("sim/R/sim_registry.R", package = "drmTMB", mustWork = TRUE),
    local = env
  )
  source(
    system.file("sim/R/sim_utils.R", package = "drmTMB", mustWork = TRUE),
    local = env
  )
  source(
    system.file("sim/R/sim_runner.R", package = "drmTMB", mustWork = TRUE),
    local = env
  )
  source(
    system.file("sim/R/sim_aggregate.R", package = "drmTMB", mustWork = TRUE),
    local = env
  )
  source(
    system.file(
      "sim/R/sim_uncertainty.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
  source(
    system.file(
      "sim/R/sim_bootstrap.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
  source(
    system.file(
      "sim/dgp/sim_dgp_skew_normal_fixed_effect.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
  source(
    system.file(
      "sim/fit/sim_summarise_skew_normal_fixed_effect.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
  source(
    system.file(
      "sim/run/sim_run_skew_normal_fixed_effect_smoke.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
  source(
    system.file(
      "sim/run/sim_summary_skew_normal_fixed_effect_smoke.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
  source(
    system.file(
      "sim/run/sim_write_skew_normal_fixed_effect_grid.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
}

phase18_skew_normal_fe_test_conditions <- function(n = 720L) {
  condition_fun <- get(
    "phase18_skew_normal_fe_conditions",
    envir = parent.frame()
  )
  condition_fun(
    n = n,
    nu_intercept = 1.00,
    nu_slope = 0.35,
    sigma_slope = 0.18,
    rho_xw = 0.20
  )
}

test_that("Phase 18 skew-normal DGP records public moment truth", {
  source_phase18_skew_normal_fe()

  dat <- phase18_dgp_skew_normal_fe(n = 60L, seed = 20260617L)
  truth <- attr(dat, "truth", exact = TRUE)
  mean_from_native <- dat$native_xi +
    dat$native_omega * dat$native_delta * sqrt(2 / pi)
  sd_from_native <- dat$native_omega *
    sqrt(1 - 2 * dat$native_delta^2 / pi)

  expect_equal(nrow(dat), 60L)
  expect_equal(truth$surface, "skew_normal_fixed_effect")
  expect_named(truth$beta_mu, c("(Intercept)", "x"))
  expect_named(truth$beta_sigma, c("(Intercept)", "z"))
  expect_named(truth$beta_nu, c("(Intercept)", "w"))
  expect_equal(mean_from_native, dat$mu, tolerance = 1e-12)
  expect_equal(sd_from_native, dat$sigma, tolerance = 1e-12)
  expect_equal(dat$nu, dat$eta_nu, tolerance = 1e-12)
})

test_that("Phase 18 skew-normal smoke runner completes and resumes", {
  source_phase18_skew_normal_fe()
  result_dir <- tempfile("phase18-skew-normal-fe-results-")
  dir.create(result_dir)
  withr::defer(unlink(result_dir, recursive = TRUE))

  first <- phase18_run_skew_normal_fe_smoke(
    conditions = phase18_skew_normal_fe_test_conditions(),
    n_rep = 1L,
    master_seed = 226L,
    result_dir = result_dir
  )
  second <- phase18_run_skew_normal_fe_smoke(
    conditions = phase18_skew_normal_fe_test_conditions(),
    n_rep = 1L,
    master_seed = 226L,
    result_dir = result_dir
  )

  expect_identical(first$surface, "skew_normal_fixed_effect")
  expect_equal(nrow(first$registry$cells), 1L)
  expect_equal(length(first$results), 1L)
  expect_equal(first$parallel$backend, "none")
  expect_equal(first$parallel$cores, 1L)
  expect_identical(first$results[[1L]]$status, "ok")
  expect_false(first$results[[1L]]$skipped)
  expect_true(second$results[[1L]]$skipped)
  expect_equal(nrow(first$summary), 6L)
  expect_equal(
    first$summary$surface,
    rep("skew_normal_fixed_effect", 6L)
  )
  expect_equal(first$summary$artifact_grain, rep("replicate", 6L))
  expect_equal(
    first$summary$parameter,
    c(
      "mu:(Intercept)",
      "mu:x",
      "sigma:(Intercept)",
      "sigma:z",
      "nu:(Intercept)",
      "nu:w"
    )
  )
  expect_true(all(is.finite(first$summary$estimate)))
  expect_true(all(is.finite(first$summary$std.error)))
  expect_true(any(first$summary$dpar == "nu"))
  expect_true(file.exists(phase18_result_path(
    result_dir,
    "skew_normal_fixed_effect_001",
    1L
  )))
  expect_equal(second$summary, first$summary)
})

test_that("Phase 18 skew-normal summary can request interval evidence", {
  source_phase18_skew_normal_fe()

  summary <- phase18_summarise_skew_normal_fe_smoke(
    conditions = phase18_skew_normal_fe_test_conditions(),
    n_rep = 1L,
    master_seed = 227L,
    profile_parameters = "nu:(Intercept)",
    profile_level = 0.70,
    profile_args = list(ystep = 0.50),
    bootstrap_nsim = 2L,
    bootstrap_level = 0.70,
    bootstrap_cores = 10L
  )

  expect_equal(summary$surface, "skew_normal_fixed_effect")
  expect_equal(nrow(summary$replicates), 6L)
  expect_equal(nrow(summary$aggregate), 6L)
  expect_equal(nrow(summary$manifest), 1L)
  expect_false(any(summary$failures$severity == "error"))
  expect_equal(nrow(summary$wald_intervals), 6L)
  expect_equal(nrow(summary$wald_coverage), 6L)
  expect_equal(nrow(summary$profile_intervals), 1L)
  expect_equal(summary$profile_intervals$parameter, "nu:(Intercept)")
  expect_true(
    summary$profile_intervals$interval_status %in% c("ok", "failed")
  )
  expect_equal(nrow(summary$bootstrap_intervals), 6L)
  expect_true(any(summary$bootstrap_intervals$n_bootstrap > 0L))
  expect_true(all(summary$bootstrap_intervals$n_bootstrap <= 2L))
  expect_equal(unique(summary$bootstrap_intervals$bootstrap.backend), "none")
  expect_equal(
    unique(summary$bootstrap_intervals$bootstrap.requested_cores),
    10L
  )
  expect_equal(unique(summary$bootstrap_intervals$bootstrap.cores), 1L)
  expect_setequal(
    unique(summary$interval_evidence$interval_method),
    c("wald", "profile", "parametric_bootstrap")
  )
})

test_that("Phase 18 skew-normal grid writer creates table artifacts", {
  source_phase18_skew_normal_fe()
  output_dir <- tempfile("phase18-skew-normal-fe-grid-")
  withr::defer(unlink(output_dir, recursive = TRUE))

  out <- phase18_write_skew_normal_fe_grid_outputs(
    output_dir = output_dir,
    conditions = phase18_skew_normal_fe_test_conditions(),
    n_rep = 1L,
    master_seed = 228L,
    cores = 10L
  )

  expect_equal(out$surface, "skew_normal_fixed_effect_grid")
  expect_equal(out$summary$run$parallel$backend, "none")
  expect_equal(out$summary$run$parallel$requested_cores, 10L)
  expect_equal(out$summary$run$parallel$cores, 1L)
  expect_true(dir.exists(out$result_dir))
  expect_true(dir.exists(out$table_dir))
  expect_true(all(file.exists(unlist(out$paths, use.names = FALSE))))
  expect_equal(nrow(out$summary$replicates), 6L)
  expect_equal(nrow(out$summary$aggregate), 6L)
  expect_equal(nrow(utils::read.csv(out$paths$replicate_csv)), 6L)
  expect_error(
    phase18_write_skew_normal_fe_grid_outputs(
      output_dir = output_dir,
      conditions = phase18_skew_normal_fe_test_conditions(),
      n_rep = 1L,
      master_seed = 228L
    ),
    "already exists"
  )
  expect_silent(phase18_write_skew_normal_fe_grid_outputs(
    output_dir = output_dir,
    conditions = phase18_skew_normal_fe_test_conditions(),
    n_rep = 1L,
    master_seed = 228L,
    overwrite = TRUE
  ))
})

test_that("Phase 18 skew-normal runner validates cells and bootstrap nesting", {
  skip_on_os("windows")
  source_phase18_skew_normal_fe()

  bad_cell <- data.frame(cell_id = "skew_normal_fixed_effect_bad")
  expect_error(
    phase18_dgp_skew_normal_fe_cell(
      cell = bad_cell,
      seed = 229L,
      cell_id = "skew_normal_fixed_effect_bad",
      replicate = 1L
    ),
    "must contain"
  )
  expect_error(
    phase18_run_skew_normal_fe_smoke(
      conditions = phase18_skew_normal_fe_test_conditions(n = 80L),
      n_rep = 0L
    ),
    "positive whole number"
  )
  expect_error(
    phase18_run_skew_normal_fe_smoke(
      conditions = phase18_skew_normal_fe_test_conditions(),
      n_rep = 2L,
      master_seed = 230L,
      bootstrap_nsim = 2L,
      cores = 2L,
      backend = "multicore",
      bootstrap_cores = 2L,
      bootstrap_backend = "multicore"
    ),
    "either the replicate layer or the bootstrap layer"
  )
})
