test_that("Phase 18 Gaussian sigma random-slope DGP is seeded and self-describing", {
  source(
    system.file("sim/R/sim_registry.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_utils.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file(
      "sim/dgp/sim_dgp_gaussian_sigma_random_slope.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )

  conditions <- phase18_gaussian_sigma_rs_conditions(
    n_group = 12L,
    n_per_group = 6L
  )
  dat <- phase18_dgp_gaussian_sigma_rs(
    n_group = 12L,
    n_per_group = 6L,
    seed = 238L,
    cell_id = "gaussian_sigma_random_slope_001",
    replicate = 1L
  )
  again <- phase18_dgp_gaussian_sigma_rs(
    n_group = 12L,
    n_per_group = 6L,
    seed = 238L,
    cell_id = "gaussian_sigma_random_slope_001",
    replicate = 1L
  )
  truth <- attr(dat, "truth")

  expect_equal(nrow(conditions), 1L)
  expect_equal(dat, again)
  expect_equal(nrow(dat), 72L)
  expect_named(
    dat,
    c(
      "y",
      "x",
      "z",
      "w",
      "id",
      "mu",
      "sigma",
      "log_sigma",
      "cell_id",
      "replicate"
    )
  )
  expect_identical(truth$surface, "gaussian_sigma_random_slope")
  expect_named(truth$beta_mu, c("(Intercept)", "x"))
  expect_named(truth$beta_sigma, c("(Intercept)", "z"))
  expect_named(truth$sd_sigma, "(0 + w | id)")
})

test_that("Phase 18 Gaussian sigma random-slope smoke runner summarises output", {
  source(
    system.file("sim/R/sim_registry.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_utils.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_runner.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_aggregate.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_uncertainty.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file(
      "sim/dgp/sim_dgp_gaussian_sigma_random_slope.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )
  source(
    system.file(
      "sim/fit/sim_summarise_gaussian_sigma_random_slope.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )
  source(
    system.file(
      "sim/run/sim_run_gaussian_sigma_random_slope_smoke.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )
  source(
    system.file(
      "sim/run/sim_summary_gaussian_sigma_random_slope_smoke.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )

  result_dir <- tempfile("phase18-gaussian-sigma-rs-")
  dir.create(result_dir)
  withr::defer(unlink(result_dir, recursive = TRUE))
  conditions <- phase18_gaussian_sigma_rs_conditions(
    n_group = 32L,
    n_per_group = 8L
  )

  out <- phase18_summarise_gaussian_sigma_rs_smoke(
    conditions = conditions,
    n_rep = 1L,
    master_seed = 238L,
    result_dir = result_dir
  )

  expect_identical(out$surface, "gaussian_sigma_random_slope")
  expect_equal(out$run$parallel$backend, "none")
  expect_equal(out$run$parallel$cores, 1L)
  expect_equal(nrow(out$run$summary), 5L)
  expect_equal(nrow(out$aggregate), 5L)
  expect_equal(nrow(out$manifest), 1L)
  expect_identical(out$manifest$status, "ok")
  expect_equal(nrow(out$failures), 0L)
  expect_equal(out$aggregate$n_replicate, rep(1L, 5L))
  expect_equal(
    out$run$summary$parameter,
    c(
      "mu:(Intercept)",
      "mu:x",
      "sigma:(Intercept)",
      "sigma:z",
      "sd:sigma:(0 + w | id)"
    )
  )
  expect_setequal(
    out$run$summary$parameter_class,
    c("fixed_mu", "fixed_sigma", "scale_random_sd")
  )
  expect_true(all(out$run$summary$converged))
  expect_type(out$run$summary$pdHess, "logical")
  expect_false(anyNA(out$run$summary$pdHess))
  expect_true(all(is.finite(out$run$summary$estimate)))
  expect_true(all(is.finite(out$run$summary$error)))
  expect_true(file.exists(phase18_result_path(
    result_dir,
    "gaussian_sigma_random_slope_001",
    1L
  )))
})

test_that("Phase 18 Gaussian sigma random-slope helpers reject malformed inputs", {
  source(
    system.file("sim/R/sim_registry.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_utils.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_runner.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file(
      "sim/dgp/sim_dgp_gaussian_sigma_random_slope.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )
  source(
    system.file(
      "sim/run/sim_run_gaussian_sigma_random_slope_smoke.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )

  expect_error(
    phase18_dgp_gaussian_sigma_rs(0L, 7L),
    "positive whole number"
  )
  expect_error(
    phase18_dgp_gaussian_sigma_rs(12L, 7L, sd_sigma_w = 0),
    "positive finite number"
  )
  expect_error(
    phase18_dgp_gaussian_sigma_rs_cell(
      data.frame(cell_id = "bad"),
      seed = 238L,
      cell_id = "bad",
      replicate = 1L
    ),
    "must contain"
  )
})
