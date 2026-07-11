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

test_that("Phase 18 Poisson phylogenetic q1 grid writer creates artifacts", {
  # Heavy opt-in recovery-grid simulation (requests multiple cores, writes
  # artifacts). The Poisson + phylogenetic recovery is numerically fragile near
  # the variance boundary, so the `failures == 0` assertion is not reproducible
  # across BLAS/LAPACK builds (false-failed on the R-hub clang container while
  # passing on the reference platform). Skip on CRAN, consistent with the rest
  # of the phase-18 grid-writer suite; still runs locally (NOT_CRAN=true).
  skip_on_cran()
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
  source(
    system.file(
      "sim/run/sim_write_poisson_phylo_q1_grid.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )

  output_dir <- tempfile("phase18-poisson-phylo-q1-grid-")
  withr::defer(unlink(output_dir, recursive = TRUE))
  conditions <- phase18_poisson_phylo_q1_conditions(
    n_species = 8L,
    n_per_species = 6L,
    sd_phylo = 0.35,
    mean_count = 3.0,
    tree_shape = "balanced"
  )

  out <- phase18_write_poisson_phylo_q1_grid_outputs(
    output_dir = output_dir,
    conditions = conditions,
    n_rep = 1L,
    master_seed = 243L,
    profile_parameters = "log_sd_phylo",
    cores = 10L
  )

  expect_equal(out$surface, "poisson_phylo_q1_grid")
  expect_equal(out$summary$run$parallel$requested_cores, 10L)
  expect_equal(out$summary$run$parallel$cores, 1L)
  expect_true(all(out$artifact_manifest$exists))
  expect_true(all(file.exists(unlist(out$paths, use.names = FALSE))))
  expect_equal(nrow(out$summary$replicates), 3L)
  expect_equal(nrow(out$summary$aggregate), 3L)
  expect_equal(nrow(out$summary$manifest), 1L)
  expect_equal(nrow(out$summary$failures), 0L)
  expect_equal(nrow(out$summary$wald_intervals), 3L)
  expect_equal(nrow(out$summary$wald_coverage), 2L)
  expect_equal(nrow(out$summary$profile_targets), 1L)
  expect_equal(nrow(out$summary$profile_intervals), 1L)
  expect_equal(nrow(out$summary$profile_coverage), 1L)
  expect_equal(nrow(out$summary$interval_evidence), 4L)
  expect_equal(nrow(out$summary$interval_diagnostics), 4L)
  expect_true(all(
    out$summary$profile_intervals$interval_status %in%
      c(
        "ok",
        "failed"
      )
  ))
  expect_equal(nrow(utils::read.csv(out$paths$replicate_csv)), 3L)
  expect_equal(nrow(utils::read.csv(out$paths$aggregate_csv)), 3L)
  expect_equal(nrow(utils::read.csv(out$paths$manifest_csv)), 1L)
  expect_equal(nrow(utils::read.csv(out$paths$failures_csv)), 0L)
  expect_equal(nrow(utils::read.csv(out$paths$wald_intervals_csv)), 3L)
  expect_equal(nrow(utils::read.csv(out$paths$wald_coverage_csv)), 2L)
  expect_equal(nrow(utils::read.csv(out$paths$profile_targets_csv)), 1L)
  expect_equal(nrow(utils::read.csv(out$paths$profile_intervals_csv)), 1L)
  expect_equal(nrow(utils::read.csv(out$paths$profile_coverage_csv)), 1L)
  expect_equal(nrow(utils::read.csv(out$paths$interval_evidence_csv)), 4L)
  expect_equal(nrow(utils::read.csv(out$paths$interval_diagnostics_csv)), 4L)
  expect_error(
    phase18_write_poisson_phylo_q1_grid_outputs(
      output_dir = output_dir,
      conditions = conditions,
      n_rep = 1L,
      master_seed = 243L
    ),
    "already exists"
  )
})

test_that("Phase 18 Poisson phylogenetic q1 grid writer validates inputs", {
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
      "sim/run/sim_write_poisson_phylo_q1_grid.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )

  expect_error(
    phase18_write_poisson_phylo_q1_grid_outputs(output_dir = ""),
    "output_dir"
  )
  expect_error(
    phase18_write_poisson_phylo_q1_grid_outputs(
      output_dir = tempfile(),
      overwrite = NA
    ),
    "overwrite"
  )
})

test_that("Phase 18 Poisson phylogenetic q1 formal wrapper and QA read artifacts", {
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
  source(
    system.file(
      "sim/run/sim_write_poisson_phylo_q1_grid.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )

  output_dir <- tempfile("phase18-poisson-phylo-q1-formal-")
  withr::defer(unlink(output_dir, recursive = TRUE))
  conditions <- phase18_poisson_phylo_q1_conditions(
    n_species = 8L,
    n_per_species = 6L,
    sd_phylo = 0.35,
    mean_count = 3.0,
    tree_shape = "balanced"
  )

  out <- phase18_write_poisson_phylo_q1_formal_grid_outputs(
    output_dir = output_dir,
    conditions = conditions,
    n_rep = 1L,
    master_seed = 244L
  )
  read_back <- phase18_read_poisson_phylo_q1_grid_outputs(
    output_dir,
    require_complete = TRUE
  )
  qa <- phase18_qa_poisson_phylo_q1_grid_outputs(
    read_back$tables,
    expected_n_rep = 1L
  )
  decision <- phase18_poisson_phylo_q1_promotion_decision(
    qa,
    formal_spec = out$formal_spec
  )

  expect_equal(out$surface, "poisson_phylo_q1_formal_grid")
  expect_equal(nrow(out$formal_spec), 1L)
  expect_false(out$formal_spec$formal_recovery_gate)
  expect_true(file.exists(out$paths$formal_spec_csv))
  expect_equal(read_back$surface, "poisson_phylo_q1_grid_read")
  expect_true(all(qa$status %in% c("ok", "not_checked")))
  expect_equal(qa$status[qa$check == "expected_replicates"], "ok")
  expect_equal(decision$decision, "hold_smoke_only")
})

test_that("Phase 18 Poisson phylogenetic q1 formal Actions task plans", {
  source(
    system.file(
      "sim/run/sim_run_actions_cell.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )

  expect_output(
    phase18_actions_main(c(
      "--task=poisson_phylo_q1_formal",
      "--dry-run=true",
      "--profile-parameters=log_sd_phylo"
    )),
    "poisson_phylo_q1_formal"
  )
})
