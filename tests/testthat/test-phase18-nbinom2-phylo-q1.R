source_phase18_nbinom2_phylo_q1 <- function(env = parent.frame()) {
  paths <- c(
    "sim/R/sim_registry.R",
    "sim/R/sim_utils.R",
    "sim/R/sim_runner.R",
    "sim/R/sim_aggregate.R",
    "sim/R/sim_uncertainty.R",
    "sim/dgp/sim_dgp_nbinom2_phylo_q1.R",
    "sim/fit/sim_summarise_nbinom2_phylo_q1.R",
    "sim/run/sim_run_nbinom2_phylo_q1_smoke.R",
    "sim/run/sim_summary_nbinom2_phylo_q1_smoke.R",
    "sim/run/sim_write_nbinom2_phylo_q1_grid.R"
  )
  for (path in paths) {
    source(system.file(path, package = "drmTMB", mustWork = TRUE), local = env)
  }
}

test_that("Phase 18 NB2 phylogenetic q1 DGP is seeded and self-describing", {
  source_phase18_nbinom2_phylo_q1()

  conditions <- phase18_nbinom2_phylo_q1_conditions(
    n_species = c(8L, 10L),
    n_per_species = 5L,
    sd_phylo = c(0, 0.35),
    mean_count = 2.5,
    sigma_baseline = c(0.45, 0.80),
    tree_shape = c("balanced", "mildly_uneven")
  )
  dat <- phase18_dgp_nbinom2_phylo_q1(
    n_species = 10L,
    n_per_species = 6L,
    sd_phylo = 0.35,
    seed = 526L,
    cell_id = "nbinom2_phylo_q1_001",
    replicate = 1L
  )
  again <- phase18_dgp_nbinom2_phylo_q1(
    n_species = 10L,
    n_per_species = 6L,
    sd_phylo = 0.35,
    seed = 526L,
    cell_id = "nbinom2_phylo_q1_001",
    replicate = 1L
  )
  truth <- attr(dat, "truth")

  expect_equal(nrow(conditions), 16L)
  expect_named(
    conditions,
    c(
      "n_species",
      "n_per_species",
      "sd_phylo",
      "mean_count",
      "sigma_baseline",
      "beta_mu_x",
      "beta_sigma_z",
      "tree_shape"
    )
  )
  expect_equal(dat, again)
  expect_equal(nrow(dat), 60L)
  expect_named(
    dat,
    c(
      "count",
      "x",
      "z",
      "species",
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
  expect_true(all(dat$sigma > 0))
  expect_s3_class(truth$tree, "phylo")
  expect_identical(truth$surface, "nbinom2_phylo_q1")
  expect_named(truth$beta_mu, c("(Intercept)", "x"))
  expect_named(truth$beta_sigma, c("(Intercept)", "z"))
  expect_named(truth$sd, "phylo(1 | species)")
  expect_named(truth$comparator_sd, "(1 | species)")
  expect_equal(length(truth$tree$tip.label), 10L)
})

test_that("Phase 18 NB2 phylogenetic q1 smoke runner summarises output", {
  source_phase18_nbinom2_phylo_q1()
  result_dir <- tempfile("phase18-nbinom2-phylo-q1-")
  dir.create(result_dir)
  withr::defer(unlink(result_dir, recursive = TRUE))
  conditions <- phase18_nbinom2_phylo_q1_conditions(
    n_species = 16L,
    n_per_species = 8L,
    sd_phylo = 0.35,
    mean_count = 4.0,
    sigma_baseline = 0.45,
    tree_shape = "balanced"
  )

  out <- phase18_summarise_nbinom2_phylo_q1_smoke(
    conditions = conditions,
    n_rep = 1L,
    master_seed = 527L,
    result_dir = result_dir,
    cores = 10L
  )

  expect_identical(out$surface, "nbinom2_phylo_q1")
  expect_equal(out$run$parallel$backend, "none")
  expect_equal(out$run$parallel$requested_cores, 10L)
  expect_equal(out$run$parallel$cores, 1L)
  expect_equal(nrow(out$run$summary), 6L)
  expect_equal(nrow(out$aggregate), 6L)
  expect_equal(nrow(out$manifest), 1L)
  expect_identical(out$manifest$status, "ok")
  expect_equal(nrow(out$failures), 0L)
  expect_equal(nrow(out$wald_intervals), 6L)
  expect_equal(nrow(out$wald_coverage), 4L)
  expect_equal(nrow(out$profile_targets), 1L)
  expect_equal(nrow(out$profile_intervals), 1L)
  expect_equal(nrow(out$profile_coverage), 0L)
  expect_equal(nrow(out$interval_evidence), 7L)
  expect_equal(out$aggregate$n_replicate, rep(1L, 6L))
  expect_equal(
    out$wald_intervals$interval_status,
    c("ok", "ok", "ok", "ok", "failed", "failed")
  )
  expect_equal(
    out$wald_intervals$interval_scale,
    c(
      "formula_coefficient",
      "formula_coefficient",
      "formula_coefficient",
      "formula_coefficient",
      "public_sd",
      "public_sd"
    )
  )
  expect_equal(out$profile_targets$profile_target_status, "ready")
  expect_equal(out$profile_targets$profile_target_parameter, "log_sd_phylo")
  expect_equal(out$profile_targets$artifact_grain, "profile_target")
  expect_equal(out$profile_intervals$interval_status, "not_requested")
  expect_setequal(
    out$run$summary$parameter_class,
    c("fixed_mu", "fixed_sigma", "phylo_sd", "grouped_comparator_sd")
  )
  expect_equal(
    out$run$summary$parameter,
    c(
      "mu:(Intercept)",
      "mu:x",
      "sigma:(Intercept)",
      "sigma:z",
      "sd:mu:phylo(1 | species)",
      "comparator:sd:mu:(1 | species)"
    )
  )
  expect_equal(
    out$run$summary$comparator,
    c(
      "phylo_q1",
      "phylo_q1",
      "phylo_q1",
      "phylo_q1",
      "phylo_q1",
      "ordinary_grouped"
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
  expect_equal(
    phase18_nbinom2_phylo_q1_profile_parameter_map("log_sd_phylo"),
    c("sd:mu:phylo(1 | species)" = "sd:mu:phylo(1 | species)")
  )
  expect_true(file.exists(phase18_result_path(
    result_dir,
    "nbinom2_phylo_q1_001",
    1L
  )))
})

test_that("Phase 18 NB2 phylogenetic q1 grid writer creates artifacts", {
  source_phase18_nbinom2_phylo_q1()
  output_dir <- tempfile("phase18-nbinom2-phylo-q1-grid-")
  withr::defer(unlink(output_dir, recursive = TRUE))

  out <- phase18_write_nbinom2_phylo_q1_grid_outputs(
    output_dir = output_dir,
    conditions = phase18_nbinom2_phylo_q1_conditions(
      n_species = 16L,
      n_per_species = 8L,
      sd_phylo = 0.35,
      mean_count = 4.0,
      sigma_baseline = 0.45,
      tree_shape = "balanced"
    ),
    n_rep = 1L,
    master_seed = 528L,
    cores = 10L
  )

  expect_equal(out$surface, "nbinom2_phylo_q1_grid")
  expect_equal(out$summary$run$parallel$requested_cores, 10L)
  expect_equal(out$summary$run$parallel$cores, 1L)
  expect_equal(nrow(out$artifact_manifest), length(out$paths))
  expect_true(all(out$artifact_manifest$exists))
  expect_true(dir.exists(out$result_dir))
  expect_true(dir.exists(out$table_dir))
  expect_true(all(file.exists(unlist(out$paths, use.names = FALSE))))
  expect_equal(nrow(out$summary$aggregate), 6L)
  expect_equal(nrow(out$summary$replicates), 6L)
  expect_equal(nrow(out$summary$manifest), 1L)
  expect_equal(nrow(utils::read.csv(out$paths$profile_targets_csv)), 1L)
  expect_equal(nrow(utils::read.csv(out$paths$profile_intervals_csv)), 1L)
  expect_equal(
    unique(out$summary$aggregate$surface),
    "nbinom2_phylo_q1"
  )
  expect_error(
    phase18_write_nbinom2_phylo_q1_grid_outputs(
      output_dir = output_dir,
      conditions = phase18_nbinom2_phylo_q1_conditions(
        n_species = 16L,
        n_per_species = 8L,
        sd_phylo = 0.35,
        mean_count = 4.0,
        sigma_baseline = 0.45,
        tree_shape = "balanced"
      ),
      n_rep = 1L,
      master_seed = 528L
    ),
    "already exists"
  )
})

test_that("Phase 18 NB2 phylogenetic q1 helpers reject malformed inputs", {
  source_phase18_nbinom2_phylo_q1()

  expect_error(
    phase18_dgp_nbinom2_phylo_q1(1L, 5L),
    "at least 2"
  )
  expect_error(
    phase18_dgp_nbinom2_phylo_q1(8L, 5L, sd_phylo = -0.2),
    "non-negative"
  )
  expect_error(
    phase18_dgp_nbinom2_phylo_q1(8L, 5L, tree_shape = "ladder"),
    "balanced"
  )
  expect_error(
    phase18_dgp_nbinom2_phylo_q1_cell(
      data.frame(cell_id = "bad"),
      seed = 246L,
      cell_id = "bad",
      replicate = 1L
    ),
    "must contain"
  )
  expect_error(
    phase18_write_nbinom2_phylo_q1_grid_outputs(output_dir = ""),
    "output_dir"
  )
  expect_error(
    phase18_write_nbinom2_phylo_q1_grid_outputs(
      output_dir = tempfile(),
      overwrite = NA
    ),
    "overwrite"
  )
  expect_error(
    phase18_nbinom2_phylo_q1_profile_parameter_map(c("log_sd_phylo", "")),
    "parameters"
  )
})

test_that("Phase 18 NB2 phylogenetic q1 formal wrapper and QA read artifacts", {
  source_phase18_nbinom2_phylo_q1()
  output_dir <- tempfile("phase18-nbinom2-phylo-q1-formal-")
  withr::defer(unlink(output_dir, recursive = TRUE))
  conditions <- phase18_nbinom2_phylo_q1_conditions(
    n_species = 16L,
    n_per_species = 8L,
    sd_phylo = 0.35,
    mean_count = 4.0,
    sigma_baseline = 0.45,
    tree_shape = "balanced"
  )

  out <- phase18_write_nbinom2_phylo_q1_formal_grid_outputs(
    output_dir = output_dir,
    conditions = conditions,
    n_rep = 1L,
    master_seed = 529L
  )
  read_back <- phase18_read_nbinom2_phylo_q1_grid_outputs(
    output_dir,
    require_complete = TRUE
  )
  qa <- phase18_qa_nbinom2_phylo_q1_grid_outputs(
    read_back$tables,
    expected_n_rep = 1L
  )
  decision <- phase18_nbinom2_phylo_q1_promotion_decision(
    qa,
    formal_spec = out$formal_spec
  )

  expect_equal(out$surface, "nbinom2_phylo_q1_formal_grid")
  expect_equal(nrow(out$formal_spec), 1L)
  expect_false(out$formal_spec$formal_recovery_gate)
  expect_true(out$formal_spec$overdispersion_confounding_explicit)
  expect_true(file.exists(out$paths$formal_spec_csv))
  expect_equal(read_back$surface, "nbinom2_phylo_q1_grid_read")
  expect_true(all(qa$status %in% c("ok", "not_checked")))
  expect_equal(qa$status[qa$check == "expected_replicates"], "ok")
  expect_equal(qa$status[qa$check == "comparator_rows"], "ok")
  expect_equal(decision$decision, "hold_smoke_only")
})

test_that("Phase 18 NB2 phylogenetic q1 formal Actions task plans", {
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
      "--task=nbinom2_phylo_q1_formal",
      "--dry-run=true",
      "--profile-parameters=log_sd_phylo"
    )),
    "nbinom2_phylo_q1_formal"
  )
})
