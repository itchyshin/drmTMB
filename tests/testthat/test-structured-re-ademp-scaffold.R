source_structured_re_ademp_scaffold <- function(env = parent.frame()) {
  source(
    system.file("sim/R/sim_registry.R", package = "drmTMB", mustWork = TRUE),
    local = env
  )
  source(
    system.file("sim/R/sim_runner.R", package = "drmTMB", mustWork = TRUE),
    local = env
  )
  source(
    system.file(
      "sim/R/sim_structured_re_ademp.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
  source(
    system.file(
      "sim/run/sim_write_structured_re_ademp_scaffold.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
}

test_that("structured RE ADEMP conditions define q1 q2 and q4 axes", {
  source_structured_re_ademp_scaffold()

  conditions <- phase18_structured_re_ademp_conditions(
    structured_type = "phylo",
    matrix_condition = "well_conditioned",
    signal_strength = "weak",
    boundary_proximity = "interior"
  )

  expect_equal(conditions$dimension, c("q1", "q2", "q4"))
  expect_equal(
    conditions$endpoint_axes,
    c("mu;sigma", "mu1;mu2", "mu1;mu2;sigma1;sigma2")
  )
  expect_equal(conditions$coverage_claim, rep("none", 3L))
  expect_match(
    conditions$interval_policy[[3L]],
    "direct_and_derived",
    fixed = TRUE
  )
  expect_error(
    phase18_structured_re_ademp_conditions(dimensions = "q8"),
    "unsupported values"
  )
})

test_that("structured RE ADEMP registry uses Phase 18 cell seeds", {
  source_structured_re_ademp_scaffold()

  registry <- phase18_structured_re_ademp_registry(
    n_rep = 3L,
    master_seed = 20260622L,
    dimensions = c("q1", "q2"),
    structured_type = "phylo",
    matrix_condition = "well_conditioned",
    signal_strength = "weak",
    boundary_proximity = "interior"
  )

  expect_equal(registry$n_rep, 3L)
  expect_equal(nrow(registry$cells), 2L)
  expect_equal(nrow(registry$seeds), 6L)
  expect_equal(
    registry$seeds$cell_id,
    rep(registry$cells$cell_id, each = 3L)
  )
  expect_equal(length(unique(registry$seeds$seed)), 6L)
})

test_that("structured RE ADEMP MCSE policy targets 500 coverage replicates", {
  source_structured_re_ademp_scaffold()

  expect_equal(phase18_structured_re_ademp_mcse_n(), 475L)
  policy <- phase18_structured_re_ademp_mcse_policy()

  expect_equal(policy$required_n_rep, 475L)
  expect_equal(policy$planned_n_rep, 500L)
  expect_lte(policy$planned_mcse, 0.01)
  expect_match(policy$failed_fit_policy, "denominator", fixed = TRUE)
  expect_error(
    phase18_structured_re_ademp_mcse_policy(level = 1),
    "between 0 and 1"
  )
})

test_that("structured RE ADEMP denominators retain failures and unavailable intervals", {
  source_structured_re_ademp_scaffold()

  replicates <- data.frame(
    cell_id = rep("structured_re_ademp_001", 4L),
    replicate = 1:4,
    dimension = "q4",
    fit_status = c("ok", "error", "ok", "nonconverged"),
    interval_status = c("finite", "unavailable", "nonfinite", "not_evaluated"),
    covered = c(TRUE, NA, FALSE, NA),
    stringsAsFactors = FALSE
  )
  denominators <- phase18_structured_re_ademp_denominators(replicates)

  expect_equal(denominators$n_total, 4L)
  expect_equal(denominators$n_fit_ok, 2L)
  expect_equal(denominators$n_failed_fit, 2L)
  expect_equal(denominators$n_interval_finite, 1L)
  expect_equal(denominators$n_interval_unavailable, 3L)
  expect_equal(denominators$coverage_denominator, 4L)
  expect_equal(denominators$coverage_numerator, 1L)
  expect_equal(denominators$coverage_rate, 0.25)
  expect_match(
    denominators$failed_fit_policy,
    "all_replicates_in_denominator",
    fixed = TRUE
  )
  expect_error(
    phase18_structured_re_ademp_denominators(
      transform(replicates, interval_status = "covered")
    ),
    "unsupported values"
  )
})

test_that("structured RE ADEMP pilot adapters keep not-run rows in denominators", {
  source_structured_re_ademp_scaffold()

  registry <- phase18_structured_re_ademp_registry(
    n_rep = 2L,
    master_seed = 20260622L,
    dimensions = c("q1", "q4"),
    structured_type = "phylo",
    matrix_condition = "well_conditioned",
    signal_strength = "weak",
    boundary_proximity = "interior"
  )
  pilot <- phase18_structured_re_ademp_pilot_summary(registry)

  expect_equal(nrow(pilot$replicates), 4L)
  expect_equal(pilot$replicates$fit_status, rep("not_run", 4L))
  expect_equal(
    pilot$replicates$interval_status,
    rep("not_evaluated", 4L)
  )
  expect_equal(pilot$replicates$artifact_grain, rep("replicate", 4L))
  expect_equal(nrow(pilot$denominators), 2L)
  expect_equal(pilot$denominators$n_total, c(2L, 2L))
  expect_equal(pilot$denominators$n_fit_ok, c(0L, 0L))
  expect_equal(pilot$denominators$n_failed_fit, c(2L, 2L))
  expect_equal(pilot$denominators$n_interval_unavailable, c(2L, 2L))
  expect_match(pilot$claim_boundary, "no coverage claim", fixed = TRUE)
})

test_that("structured RE ADEMP scaffold writer stages resumable artifacts", {
  source_structured_re_ademp_scaffold()

  output_dir <- tempfile("structured-re-ademp-scaffold-")
  withr::defer(unlink(output_dir, recursive = TRUE))
  conditions <- phase18_structured_re_ademp_conditions(
    dimensions = "q1",
    structured_type = "phylo",
    matrix_condition = "well_conditioned",
    signal_strength = "weak",
    boundary_proximity = "interior"
  )
  out <- phase18_write_structured_re_ademp_scaffold(
    output_dir = output_dir,
    conditions = conditions,
    n_rep = 2L,
    master_seed = 20260622L
  )

  expect_equal(out$surface, "structured_re_ademp_scaffold")
  expect_true(all(file.exists(unlist(out$paths, use.names = FALSE))))
  expect_equal(nrow(utils::read.csv(out$paths$cells_csv)), 1L)
  expect_equal(nrow(utils::read.csv(out$paths$seeds_csv)), 2L)
  expect_equal(nrow(utils::read.csv(out$paths$mcse_policy_csv)), 1L)
  expect_equal(nrow(utils::read.csv(out$paths$pilot_replicates_csv)), 2L)
  expect_equal(nrow(utils::read.csv(out$paths$pilot_denominators_csv)), 1L)
  expect_equal(nrow(out$pilot_replicates), 2L)
  expect_equal(out$pilot_denominators$n_total, 2L)
  expect_equal(nrow(out$artifact_manifest), length(out$paths))
  expect_true(all(out$artifact_manifest$exists))
  expect_error(
    phase18_write_structured_re_ademp_scaffold(
      output_dir = output_dir,
      conditions = conditions,
      n_rep = 2L
    ),
    "already exists"
  )
})
