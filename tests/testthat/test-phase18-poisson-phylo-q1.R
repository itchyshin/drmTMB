test_that("Phase 18 Poisson phylogenetic q1 DGP is seeded and self-describing", {
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
      "sim/dgp/sim_dgp_poisson_phylo_q1.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )

  conditions <- phase18_poisson_phylo_q1_conditions(
    n_species = 8L,
    n_per_species = 5L,
    sd_phylo = c(0, 0.35),
    mean_count = 2.5,
    tree_shape = c("balanced", "mildly_uneven")
  )
  dat <- phase18_dgp_poisson_phylo_q1(
    n_species = 8L,
    n_per_species = 5L,
    sd_phylo = 0.35,
    seed = 243L,
    cell_id = "poisson_phylo_q1_001",
    replicate = 1L
  )
  again <- phase18_dgp_poisson_phylo_q1(
    n_species = 8L,
    n_per_species = 5L,
    sd_phylo = 0.35,
    seed = 243L,
    cell_id = "poisson_phylo_q1_001",
    replicate = 1L
  )
  truth <- attr(dat, "truth")

  expect_equal(nrow(conditions), 4L)
  expect_equal(dat, again)
  expect_equal(nrow(dat), 40L)
  expect_named(
    dat,
    c("count", "x", "species", "eta_mu", "mu", "cell_id", "replicate")
  )
  expect_type(dat$count, "integer")
  expect_true(all(dat$count >= 0))
  expect_s3_class(truth$tree, "phylo")
  expect_identical(truth$surface, "poisson_phylo_q1")
  expect_named(truth$beta_mu, c("(Intercept)", "x"))
  expect_named(truth$sd, "phylo(1 | species)")
  expect_equal(length(truth$tree$tip.label), 8L)
})

test_that("Phase 18 Poisson phylogenetic q1 smoke runner summarises output", {
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
      "sim/dgp/sim_dgp_poisson_phylo_q1.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )
  source(
    system.file(
      "sim/fit/sim_summarise_poisson_phylo_q1.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )
  source(
    system.file(
      "sim/run/sim_run_poisson_phylo_q1_smoke.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )
  source(
    system.file(
      "sim/run/sim_summary_poisson_phylo_q1_smoke.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )

  result_dir <- tempfile("phase18-poisson-phylo-q1-")
  dir.create(result_dir)
  withr::defer(unlink(result_dir, recursive = TRUE))
  conditions <- phase18_poisson_phylo_q1_conditions(
    n_species = 8L,
    n_per_species = 6L,
    sd_phylo = 0.35,
    mean_count = 3.0,
    tree_shape = "balanced"
  )

  out <- phase18_summarise_poisson_phylo_q1_smoke(
    conditions = conditions,
    n_rep = 1L,
    master_seed = 243L,
    result_dir = result_dir
  )

  expect_identical(out$surface, "poisson_phylo_q1")
  expect_equal(out$run$parallel$backend, "none")
  expect_equal(out$run$parallel$cores, 1L)
  expect_equal(nrow(out$run$summary), 3L)
  expect_equal(nrow(out$aggregate), 3L)
  expect_equal(nrow(out$manifest), 1L)
  expect_identical(out$manifest$status, "ok")
  expect_equal(nrow(out$failures), 0L)
  expect_equal(nrow(out$wald_intervals), 3L)
  expect_equal(nrow(out$wald_coverage), 2L)
  expect_equal(nrow(out$profile_targets), 1L)
  expect_equal(out$aggregate$n_replicate, rep(1L, 3L))
  expect_equal(
    out$run$summary$parameter,
    c(
      "mu:(Intercept)",
      "mu:x",
      "sd:mu:phylo(1 | species)"
    )
  )
  expect_equal(
    out$run$summary$parameter_class,
    c("fixed_mu", "fixed_mu", "phylo_sd")
  )
  expect_equal(
    out$run$summary$profile_target_status,
    c("unavailable", "unavailable", "ready")
  )
  expect_equal(
    out$profile_targets$profile_target_parameter,
    "log_sd_phylo"
  )
  expect_true(all(out$run$summary$converged))
  expect_type(out$run$summary$pdHess, "logical")
  expect_false(anyNA(out$run$summary$pdHess))
  expect_true(all(is.finite(out$run$summary$estimate)))
  expect_true(all(is.finite(out$run$summary$error)))
  expect_true(file.exists(phase18_result_path(
    result_dir,
    "poisson_phylo_q1_001",
    1L
  )))
})

test_that("Phase 18 Poisson phylogenetic q1 helpers reject malformed inputs", {
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
      "sim/dgp/sim_dgp_poisson_phylo_q1.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )
  source(
    system.file(
      "sim/run/sim_run_poisson_phylo_q1_smoke.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )

  expect_error(
    phase18_dgp_poisson_phylo_q1(1L, 5L),
    "at least 2"
  )
  expect_error(
    phase18_dgp_poisson_phylo_q1(8L, 5L, sd_phylo = -0.2),
    "non-negative"
  )
  expect_error(
    phase18_dgp_poisson_phylo_q1(8L, 5L, tree_shape = "ladder"),
    "balanced"
  )
  expect_error(
    phase18_dgp_poisson_phylo_q1_cell(
      data.frame(cell_id = "bad"),
      seed = 243L,
      cell_id = "bad",
      replicate = 1L
    ),
    "must contain"
  )
})
