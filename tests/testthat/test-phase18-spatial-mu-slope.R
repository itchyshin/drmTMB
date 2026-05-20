test_that("Phase 18 spatial mu slope DGP is seeded and self-describing", {
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
      "sim/dgp/sim_dgp_spatial_mu_slope.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )

  conditions <- phase18_spatial_mu_slope_conditions(
    n_site = 8L,
    n_each = 5L
  )
  dat <- phase18_dgp_spatial_mu_slope(
    n_site = 8L,
    n_each = 5L,
    seed = 241L,
    cell_id = "spatial_mu_slope_001",
    replicate = 1L
  )
  again <- phase18_dgp_spatial_mu_slope(
    n_site = 8L,
    n_each = 5L,
    seed = 241L,
    cell_id = "spatial_mu_slope_001",
    replicate = 1L
  )
  truth <- attr(dat, "truth")

  expect_equal(nrow(conditions), 1L)
  expect_equal(dat, again)
  expect_equal(nrow(dat), 40L)
  expect_named(
    dat,
    c("y", "x", "site", "mu", "sigma", "cell_id", "replicate")
  )
  expect_identical(truth$surface, "spatial_mu_slope")
  expect_named(truth$beta_mu, c("(Intercept)", "x"))
  expect_named(
    truth$sd,
    c("spatial(1 | site)", "spatial(0 + x | site)")
  )
  expect_equal(nrow(truth$coords), 8L)
  expect_equal(row.names(truth$coords), paste0("site_", seq_len(8L)))
})

test_that("Phase 18 spatial mu slope smoke runner summarises output", {
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
      "sim/dgp/sim_dgp_spatial_mu_slope.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )
  source(
    system.file(
      "sim/fit/sim_summarise_spatial_mu_slope.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )
  source(
    system.file(
      "sim/run/sim_run_spatial_mu_slope_smoke.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )
  source(
    system.file(
      "sim/run/sim_summary_spatial_mu_slope_smoke.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )

  result_dir <- tempfile("phase18-spatial-mu-slope-")
  dir.create(result_dir)
  withr::defer(unlink(result_dir, recursive = TRUE))
  conditions <- phase18_spatial_mu_slope_conditions(
    n_site = 12L,
    n_each = 8L
  )

  out <- phase18_summarise_spatial_mu_slope_smoke(
    conditions = conditions,
    n_rep = 1L,
    master_seed = 241L,
    result_dir = result_dir
  )

  expect_identical(out$surface, "spatial_mu_slope")
  expect_equal(out$run$parallel$backend, "none")
  expect_equal(out$run$parallel$cores, 1L)
  expect_equal(nrow(out$run$summary), 5L)
  expect_equal(nrow(out$aggregate), 5L)
  expect_equal(nrow(out$manifest), 1L)
  expect_identical(out$manifest$status, "ok")
  expect_equal(nrow(out$failures), 0L)
  expect_equal(out$aggregate$n_replicate, rep(1L, 5L))
  expect_setequal(
    out$run$summary$parameter_class,
    c("fixed_mu", "residual_sigma", "spatial_sd")
  )
  expect_equal(
    out$run$summary$parameter,
    c(
      "mu:(Intercept)",
      "mu:x",
      "sigma",
      "sd:mu:spatial(1 | site)",
      "sd:mu:spatial(0 + x | site)"
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
    "spatial_mu_slope_001",
    1L
  )))
})

test_that("Phase 18 spatial mu slope helpers reject malformed inputs", {
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
      "sim/dgp/sim_dgp_spatial_mu_slope.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )
  source(
    system.file(
      "sim/run/sim_run_spatial_mu_slope_smoke.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )

  expect_error(
    phase18_dgp_spatial_mu_slope(0L, 5L),
    "positive whole number"
  )
  expect_error(
    phase18_dgp_spatial_mu_slope(8L, 5L, sd = c(0.4, -0.2)),
    "positive"
  )
  expect_error(
    phase18_dgp_spatial_mu_slope_cell(
      data.frame(cell_id = "bad"),
      seed = 241L,
      cell_id = "bad",
      replicate = 1L
    ),
    "must contain"
  )
})
