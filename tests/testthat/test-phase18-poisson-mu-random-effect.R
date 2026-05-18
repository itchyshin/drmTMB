test_that("Phase 18 Poisson mu random-effect DGP is seeded and self-describing", {
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
      "sim/dgp/sim_dgp_poisson_mu_random_effect.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )

  conditions <- phase18_poisson_mu_re_conditions(
    n_group = 10L,
    n_per_group = 6L
  )
  dat <- phase18_dgp_poisson_mu_re(
    n_group = 10L,
    n_per_group = 6L,
    seed = 242L,
    cell_id = "poisson_mu_random_effect_001",
    replicate = 1L
  )
  again <- phase18_dgp_poisson_mu_re(
    n_group = 10L,
    n_per_group = 6L,
    seed = 242L,
    cell_id = "poisson_mu_random_effect_001",
    replicate = 1L
  )
  truth <- attr(dat, "truth")

  expect_equal(nrow(conditions), 1L)
  expect_equal(dat, again)
  expect_equal(nrow(dat), 60L)
  expect_named(
    dat,
    c("count", "x", "id", "eta_mu", "mu", "cell_id", "replicate")
  )
  expect_type(dat$count, "integer")
  expect_true(all(dat$count >= 0))
  expect_identical(truth$surface, "poisson_mu_random_effect")
  expect_named(truth$beta_mu, c("(Intercept)", "x"))
  expect_named(truth$sd, c("(1 | id)", "(0 + x | id)"))
})

test_that("Phase 18 Poisson mu random-effect smoke runner summarises output", {
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
      "sim/dgp/sim_dgp_poisson_mu_random_effect.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )
  source(
    system.file(
      "sim/fit/sim_summarise_poisson_mu_random_effect.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )
  source(
    system.file(
      "sim/run/sim_run_poisson_mu_random_effect_smoke.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )
  source(
    system.file(
      "sim/run/sim_summary_poisson_mu_random_effect_smoke.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )

  result_dir <- tempfile("phase18-poisson-mu-re-")
  dir.create(result_dir)
  withr::defer(unlink(result_dir, recursive = TRUE))
  conditions <- phase18_poisson_mu_re_conditions(
    n_group = 36L,
    n_per_group = 9L
  )

  out <- phase18_summarise_poisson_mu_re_smoke(
    conditions = conditions,
    n_rep = 1L,
    master_seed = 242L,
    result_dir = result_dir
  )

  expect_identical(out$surface, "poisson_mu_random_effect")
  expect_equal(nrow(out$run$summary), 4L)
  expect_equal(nrow(out$aggregate), 4L)
  expect_equal(nrow(out$manifest), 1L)
  expect_identical(out$manifest$status, "ok")
  expect_equal(nrow(out$failures), 0L)
  expect_equal(out$aggregate$n_replicate, rep(1L, 4L))
  expect_setequal(
    out$run$summary$parameter_class,
    c("fixed_mu", "random_sd")
  )
  expect_equal(
    out$run$summary$parameter,
    c(
      "mu:(Intercept)",
      "mu:x",
      "sd:mu:(1 | id)",
      "sd:mu:(0 + x | id)"
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
    "poisson_mu_random_effect_001",
    1L
  )))
})

test_that("Phase 18 Poisson mu random-effect helpers reject malformed inputs", {
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
      "sim/dgp/sim_dgp_poisson_mu_random_effect.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )
  source(
    system.file(
      "sim/run/sim_run_poisson_mu_random_effect_smoke.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )

  expect_error(
    phase18_dgp_poisson_mu_re(0L, 5L),
    "positive whole number"
  )
  expect_error(
    phase18_dgp_poisson_mu_re(8L, 5L, sd = c(0.4, -0.2)),
    "positive"
  )
  expect_error(
    phase18_dgp_poisson_mu_re_cell(
      data.frame(cell_id = "bad"),
      seed = 242L,
      cell_id = "bad",
      replicate = 1L
    ),
    "must contain"
  )
})
