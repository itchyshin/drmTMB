test_that("Phase 18 Gaussian mu random-slope DGP is seeded and self-describing", {
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
      "sim/dgp/sim_dgp_gaussian_mu_random_slope.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )

  conditions <- phase18_gaussian_mu_rs_conditions(
    n_group = 12L,
    n_per_group = 6L
  )
  dat <- phase18_dgp_gaussian_mu_rs(
    n_group = 12L,
    n_per_group = 6L,
    seed = 237L,
    cell_id = "gaussian_mu_random_slope_001",
    replicate = 1L
  )
  again <- phase18_dgp_gaussian_mu_rs(
    n_group = 12L,
    n_per_group = 6L,
    seed = 237L,
    cell_id = "gaussian_mu_random_slope_001",
    replicate = 1L
  )
  truth <- attr(dat, "truth")

  expect_equal(nrow(conditions), 1L)
  expect_equal(dat, again)
  expect_equal(nrow(dat), 72L)
  expect_named(
    dat,
    c("y", "x1", "x2", "id", "mu", "sigma", "cell_id", "replicate")
  )
  expect_identical(truth$surface, "gaussian_mu_random_slope")
  expect_named(truth$beta_mu, c("(Intercept)", "x1", "x2"))
  expect_named(
    truth$sd,
    c(
      "(1 + x1 + x2 | id):(Intercept)",
      "(1 + x1 + x2 | id):x1",
      "(1 + x1 + x2 | id):x2"
    )
  )
  expect_named(
    truth$cor,
    c(
      "cor((Intercept),x1 | id)",
      "cor((Intercept),x2 | id)",
      "cor(x1,x2 | id)"
    )
  )
})

test_that("Phase 18 Gaussian mu random-slope smoke runner summarises q=3 output", {
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
      "sim/dgp/sim_dgp_gaussian_mu_random_slope.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )
  source(
    system.file(
      "sim/fit/sim_summarise_gaussian_mu_random_slope.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )
  source(
    system.file(
      "sim/run/sim_run_gaussian_mu_random_slope_smoke.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )
  source(
    system.file(
      "sim/run/sim_summary_gaussian_mu_random_slope_smoke.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )

  result_dir <- tempfile("phase18-gaussian-mu-rs-")
  dir.create(result_dir)
  withr::defer(unlink(result_dir, recursive = TRUE))
  conditions <- phase18_gaussian_mu_rs_conditions(
    n_group = 24L,
    n_per_group = 7L
  )

  out <- phase18_summarise_gaussian_mu_rs_smoke(
    conditions = conditions,
    n_rep = 1L,
    master_seed = 237L,
    result_dir = result_dir
  )

  expect_identical(out$surface, "gaussian_mu_random_slope")
  expect_equal(nrow(out$run$summary), 10L)
  expect_equal(nrow(out$aggregate), 10L)
  expect_equal(nrow(out$manifest), 1L)
  expect_identical(out$manifest$status, "ok")
  expect_equal(nrow(out$failures), 0L)
  expect_equal(out$aggregate$n_replicate, rep(1L, 10L))
  expect_setequal(
    out$run$summary$parameter_class,
    c("fixed_mu", "residual_sigma", "random_sd", "random_correlation")
  )
  expect_equal(
    out$run$summary$parameter,
    c(
      "mu:(Intercept)",
      "mu:x1",
      "mu:x2",
      "sigma",
      "sd:mu:(1 + x1 + x2 | id):(Intercept)",
      "sd:mu:(1 + x1 + x2 | id):x1",
      "sd:mu:(1 + x1 + x2 | id):x2",
      "cor:re_cov:cor((Intercept),x1 | id)",
      "cor:re_cov:cor((Intercept),x2 | id)",
      "cor:re_cov:cor(x1,x2 | id)"
    )
  )
  expect_true(all(out$run$summary$converged))
  expect_type(out$run$summary$pdHess, "logical")
  expect_false(anyNA(out$run$summary$pdHess))
  expect_true(all(is.finite(out$run$summary$estimate)))
  expect_true(all(is.finite(out$run$summary$error)))
  expect_true(all(
    is.na(out$run$summary$std.error) | out$run$summary$std.error > 0
  ))
  expect_true(file.exists(phase18_result_path(
    result_dir,
    "gaussian_mu_random_slope_001",
    1L
  )))
})

test_that("Phase 18 Gaussian mu random-slope helpers reject malformed inputs", {
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
      "sim/dgp/sim_dgp_gaussian_mu_random_slope.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )
  source(
    system.file(
      "sim/run/sim_run_gaussian_mu_random_slope_smoke.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )

  expect_error(phase18_dgp_gaussian_mu_rs(0L, 7L), "positive whole number")
  expect_error(
    phase18_dgp_gaussian_mu_rs(
      12L,
      7L,
      cor = c(0.99, 0.99, -0.99)
    ),
    "positive-definite"
  )
  expect_error(
    phase18_dgp_gaussian_mu_rs_cell(
      data.frame(cell_id = "bad"),
      seed = 237L,
      cell_id = "bad",
      replicate = 1L
    ),
    "must contain"
  )
})
