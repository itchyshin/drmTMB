source_count_structured_q1 <- function(run_files = TRUE) {
  source(
    system.file("sim/R/sim_registry.R", package = "drmTMB", mustWork = TRUE),
    local = parent.frame()
  )
  source(
    system.file("sim/R/sim_utils.R", package = "drmTMB", mustWork = TRUE),
    local = parent.frame()
  )
  source(
    system.file(
      "sim/dgp/sim_dgp_count_structured_q1.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = parent.frame()
  )
  if (!run_files) {
    return(invisible())
  }
  source(
    system.file("sim/R/sim_runner.R", package = "drmTMB", mustWork = TRUE),
    local = parent.frame()
  )
  source(
    system.file("sim/R/sim_aggregate.R", package = "drmTMB", mustWork = TRUE),
    local = parent.frame()
  )
  source(
    system.file("sim/R/sim_uncertainty.R", package = "drmTMB", mustWork = TRUE),
    local = parent.frame()
  )
  source(
    system.file(
      "sim/fit/sim_summarise_count_structured_q1.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = parent.frame()
  )
  source(
    system.file(
      "sim/run/sim_run_count_structured_q1_smoke.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = parent.frame()
  )
  source(
    system.file(
      "sim/run/sim_summary_count_structured_q1_smoke.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = parent.frame()
  )
  source(
    system.file(
      "sim/run/sim_write_count_structured_q1_grid.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = parent.frame()
  )
}

test_that("Phase 18 count structured q1 DGP is seeded and self-describing", {
  source_count_structured_q1(run_files = FALSE)

  conditions <- phase18_count_structured_q1_conditions(
    family = c("poisson", "nbinom2"),
    structured_type = c("spatial", "animal", "relmat"),
    n_level = 8L,
    n_per_level = 5L,
    sd_structured = 0.35,
    mean_count = 3.0,
    sigma_baseline = 0.45,
    geometry = "ring"
  )
  dat <- phase18_dgp_count_structured_q1(
    family = "nbinom2",
    structured_type = "relmat",
    n_level = 8L,
    n_per_level = 5L,
    sd_structured = 0.35,
    seed = 282L,
    cell_id = "count_structured_q1_001",
    replicate = 1L
  )
  again <- phase18_dgp_count_structured_q1(
    family = "nbinom2",
    structured_type = "relmat",
    n_level = 8L,
    n_per_level = 5L,
    sd_structured = 0.35,
    seed = 282L,
    cell_id = "count_structured_q1_001",
    replicate = 1L
  )
  truth <- attr(dat, "truth")

  expect_equal(nrow(conditions), 6L)
  expect_equal(dat, again)
  expect_equal(nrow(dat), 40L)
  expect_named(
    dat,
    c(
      "count",
      "x",
      "z",
      "site",
      "id",
      "eta_mu",
      "eta_sigma",
      "mu",
      "sigma",
      "cell_id",
      "replicate"
    )
  )
  expect_type(dat$count, "integer")
  expect_true(all(dat$count >= 0))
  expect_identical(truth$surface, "count_structured_q1")
  expect_identical(truth$family, "nbinom2")
  expect_identical(truth$structured_type, "relmat")
  expect_named(truth$beta_mu, c("(Intercept)", "x"))
  expect_named(truth$beta_sigma, c("(Intercept)", "z"))
  expect_named(truth$sd, "relmat(1 | id)")
  expect_equal(nrow(truth$Q), 8L)
})

test_that("Phase 18 count structured q1 smoke runner summarises output", {
  source_count_structured_q1()

  conditions <- phase18_count_structured_q1_conditions(
    family = c("poisson", "nbinom2"),
    structured_type = c("spatial", "relmat"),
    n_level = 10L,
    n_per_level = 10L,
    sd_structured = 0.35,
    mean_count = 3.5,
    sigma_baseline = 0.40,
    geometry = "ring"
  )
  conditions <- conditions[
    (conditions$family == "poisson" & conditions$structured_type == "spatial") |
      (conditions$family == "nbinom2" & conditions$structured_type == "relmat"),
    ,
    drop = FALSE
  ]
  result_dir <- tempfile("phase18-count-structured-q1-")
  dir.create(result_dir)
  withr::defer(unlink(result_dir, recursive = TRUE))

  out <- phase18_summarise_count_structured_q1_smoke(
    conditions = conditions,
    n_rep = 1L,
    master_seed = 282L,
    result_dir = result_dir
  )
  structured_rows <- out$run$summary[
    out$run$summary$parameter_class == "structured_sd",
    ,
    drop = FALSE
  ]

  expect_identical(out$surface, "count_structured_q1")
  expect_equal(out$run$parallel$backend, "none")
  expect_equal(out$run$parallel$cores, 1L)
  expect_equal(nrow(out$run$summary), 8L)
  expect_equal(nrow(out$aggregate), 8L)
  expect_equal(nrow(out$manifest), 2L)
  expect_equal(nrow(out$failures), 0L)
  expect_equal(nrow(out$wald_intervals), 8L)
  expect_equal(nrow(out$profile_targets), 2L)
  expect_equal(nrow(out$profile_intervals), 2L)
  expect_equal(nrow(out$interval_evidence), 10L)
  expect_equal(out$manifest$status, rep("ok", 2L))
  expect_equal(
    out$run$summary$parameter_class,
    c(
      "fixed_mu",
      "fixed_mu",
      "structured_sd",
      "fixed_mu",
      "fixed_mu",
      "fixed_sigma",
      "fixed_sigma",
      "structured_sd"
    )
  )
  expect_equal(structured_rows$profile_target_status, rep("ready", 2L))
  expect_equal(
    structured_rows$profile_target_parameter,
    rep("log_sd_phylo", 2L)
  )
  expect_equal(structured_rows$diagnostic_status, rep("ok", 2L))
  expect_true(all(out$run$summary$converged))
  expect_type(out$run$summary$pdHess, "logical")
  expect_false(anyNA(out$run$summary$pdHess))
  expect_true(all(is.finite(out$run$summary$estimate)))
  expect_true(all(is.finite(out$run$summary$error)))
})

test_that("Phase 18 count structured q1 helpers reject malformed inputs", {
  source_count_structured_q1()

  expect_error(
    phase18_dgp_count_structured_q1(
      family = "zip",
      structured_type = "spatial",
      n_level = 8L,
      n_per_level = 5L
    ),
    "arg"
  )
  expect_error(
    phase18_dgp_count_structured_q1(
      family = "poisson",
      structured_type = "spatial",
      n_level = 2L,
      n_per_level = 5L
    ),
    "at least 3"
  )
  expect_error(
    phase18_dgp_count_structured_q1(
      family = "poisson",
      structured_type = "animal",
      n_level = 8L,
      n_per_level = 5L,
      sd_structured = -0.2
    ),
    "non-negative"
  )
  expect_error(
    phase18_dgp_count_structured_q1_cell(
      data.frame(cell_id = "bad"),
      seed = 282L,
      cell_id = "bad",
      replicate = 1L
    ),
    "must contain"
  )
})

test_that("Phase 18 count structured q1 grid writer creates artifacts", {
  source_count_structured_q1()

  output_dir <- tempfile("phase18-count-structured-q1-grid-")
  withr::defer(unlink(output_dir, recursive = TRUE))
  conditions <- phase18_count_structured_q1_conditions(
    family = "poisson",
    structured_type = "animal",
    n_level = 10L,
    n_per_level = 10L,
    sd_structured = 0.35,
    mean_count = 3.5,
    sigma_baseline = 0.40,
    geometry = "ring"
  )

  out <- phase18_write_count_structured_q1_grid_outputs(
    output_dir = output_dir,
    conditions = conditions,
    n_rep = 1L,
    master_seed = 283L,
    cores = 10L
  )

  expect_equal(out$surface, "count_structured_q1_grid")
  expect_equal(out$summary$run$parallel$requested_cores, 10L)
  expect_equal(out$summary$run$parallel$cores, 1L)
  expect_true(all(out$artifact_manifest$exists))
  expect_true(all(file.exists(unlist(out$paths, use.names = FALSE))))
  expect_equal(nrow(out$summary$replicates), 3L)
  expect_equal(nrow(out$summary$aggregate), 3L)
  expect_equal(nrow(out$summary$manifest), 1L)
  expect_equal(nrow(out$summary$failures), 0L)
  expect_equal(nrow(out$summary$wald_intervals), 3L)
  expect_equal(nrow(out$summary$profile_targets), 1L)
  expect_equal(nrow(out$summary$profile_intervals), 1L)
  expect_equal(nrow(out$summary$interval_evidence), 4L)
  expect_equal(nrow(utils::read.csv(out$paths$replicate_csv)), 3L)
  expect_equal(nrow(utils::read.csv(out$paths$aggregate_csv)), 3L)
  expect_equal(nrow(utils::read.csv(out$paths$manifest_csv)), 1L)
  expect_equal(nrow(utils::read.csv(out$paths$failures_csv)), 0L)
  expect_equal(nrow(utils::read.csv(out$paths$wald_intervals_csv)), 3L)
  expect_equal(nrow(utils::read.csv(out$paths$profile_targets_csv)), 1L)
  expect_equal(nrow(utils::read.csv(out$paths$profile_intervals_csv)), 1L)
  expect_equal(nrow(utils::read.csv(out$paths$interval_evidence_csv)), 4L)
  expect_error(
    phase18_write_count_structured_q1_grid_outputs(
      output_dir = output_dir,
      conditions = conditions,
      n_rep = 1L,
      master_seed = 283L
    ),
    "already exists"
  )
})
