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

structured_re_ademp_artifact_path <- function(...) {
  parts <- c(...)
  candidates <- c(
    do.call(testthat::test_path, as.list(c("..", "..", parts))),
    do.call(file.path, as.list(c(getwd(), parts)))
  )
  candidates <- candidates[file.exists(candidates)]
  testthat::skip_if(
    length(candidates) == 0L,
    paste(
      "artifact source file not available:",
      do.call(file.path, as.list(parts))
    )
  )
  normalizePath(candidates[[1L]], winslash = "/", mustWork = TRUE)
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

test_that("structured RE ADEMP calibration gate blocks undersized pilots", {
  source_structured_re_ademp_scaffold()

  registry <- phase18_structured_re_ademp_registry(
    n_rep = 2L,
    master_seed = 20260622L,
    dimensions = "q1",
    structured_type = "phylo",
    matrix_condition = "well_conditioned",
    signal_strength = "weak",
    boundary_proximity = "interior"
  )
  pilot <- phase18_structured_re_ademp_pilot_summary(registry)
  gate <- phase18_structured_re_ademp_calibration_gate(pilot$replicates)

  expect_equal(nrow(gate), 1L)
  expect_equal(gate$gate_status, "blocked")
  expect_equal(gate$planned_n_rep, 500L)
  expect_match(gate$blocked_reasons, "planned_n_rep_not_met", fixed = TRUE)
  expect_match(gate$blocked_reasons, "fit_rows_not_run", fixed = TRUE)
  expect_match(gate$blocked_reasons, "interval_rows_not_evaluated", fixed = TRUE)
  expect_match(gate$blocked_reasons, "no_finite_intervals", fixed = TRUE)
  expect_match(gate$claim_boundary, "no coverage claim", fixed = TRUE)
})

test_that("structured RE ADEMP calibration gate names review eligibility", {
  source_structured_re_ademp_scaffold()

  replicates <- data.frame(
    cell_id = rep("structured_re_ademp_001", 4L),
    replicate = 1:4,
    dimension = "q1",
    structured_type = "phylo",
    fit_status = "ok",
    interval_status = "finite",
    covered = c(TRUE, TRUE, FALSE, FALSE),
    estimate = NA_real_,
    truth = NA_real_,
    elapsed = NA_real_,
    artifact_grain = "replicate",
    stringsAsFactors = FALSE
  )
  policy <- phase18_structured_re_ademp_mcse_policy(
    target_mcse = 0.25,
    planned_n_rep = 4L
  )
  gate <- phase18_structured_re_ademp_calibration_gate(
    replicates,
    policy = policy
  )

  expect_equal(gate$gate_status, "eligible_for_review")
  expect_equal(gate$blocked_reasons, "none")
  expect_equal(gate$n_total, 4L)
  expect_equal(gate$n_interval_finite, 4L)
  expect_equal(gate$coverage_rate, 0.5)
  expect_equal(gate$coverage_mcse, 0.25)
  expect_match(gate$claim_boundary, "no coverage claim", fixed = TRUE)
})

test_that("structured RE ADEMP q4 interval diagnostic plan keeps targets separate", {
  source_structured_re_ademp_scaffold()

  plan <- phase18_structured_re_q4_interval_diagnostic_plan(
    planned_n_rep = 500L
  )

  expect_equal(nrow(plan), 10L)
  expect_named(
    plan,
    c(
      "diagnostic_id",
      "slice_id",
      "target",
      "target_kind",
      "axis_pair",
      "direct_sd_target",
      "derived_correlation_target",
      "interval_methods",
      "required_fit_evidence",
      "required_interval_evidence",
      "denominator_fields",
      "current_blocker",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_setequal(plan$target_kind, c("direct_sd", "derived_correlation"))
  direct <- plan[plan$target_kind == "direct_sd", , drop = FALSE]
  derived <- plan[plan$target_kind == "derived_correlation", , drop = FALSE]
  expect_equal(nrow(direct), 4L)
  expect_equal(nrow(derived), 6L)
  expect_setequal(
    direct$direct_sd_target,
    c("sd_mu1", "sd_mu2", "sd_sigma1", "sd_sigma2")
  )
  expect_equal(derived$direct_sd_target, rep("not_direct", 6L))
  expect_true(all(grepl("coverage_mcse<=0.01", plan$required_interval_evidence)))
  expect_true(all(grepl("coverage_denominator", plan$denominator_fields)))
  expect_equal(plan$status, rep("planned", nrow(plan)))
  expect_true(all(grepl("no q4 interval reliability", plan$claim_boundary)))
  expect_true(all(grepl("interval coverage", plan$claim_boundary)))
})

test_that("structured RE ADEMP q4 interval diagnostic status keeps pilot failures visible", {
  source_structured_re_ademp_scaffold()

  pilot_rows <- utils::read.csv(structured_re_ademp_artifact_path(
    "docs",
    "dev-log",
    "simulation-artifacts",
    "2026-06-22-structured-coverage-unblock-pilots",
    "tables",
    "structured-coverage-pilot-rows.csv"
  ))
  status <- phase18_structured_re_q4_interval_diagnostic_status(pilot_rows)

  expect_equal(nrow(status), 10L)
  expect_named(
    status,
    c(
      "diagnostic_id",
      "slice_id",
      "target",
      "target_kind",
      "axis_pair",
      "direct_sd_target",
      "derived_correlation_target",
      "source_artifact",
      "observed_target_rows",
      "n_fit_ok",
      "n_converged",
      "n_pdhess",
      "n_finite_intervals",
      "interval_status",
      "failure_class",
      "interval_claim_status",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  direct <- status[status$target_kind == "direct_sd", , drop = FALSE]
  derived <- status[status$target_kind == "derived_correlation", , drop = FALSE]
  expect_equal(nrow(direct), 4L)
  expect_equal(nrow(derived), 6L)
  expect_equal(direct$observed_target_rows, rep(2L, 4L))
  expect_equal(direct$n_fit_ok, rep(2L, 4L))
  expect_equal(direct$n_converged, rep(0L, 4L))
  expect_equal(direct$n_pdhess, rep(0L, 4L))
  expect_equal(direct$n_finite_intervals, rep(0L, 4L))
  expect_equal(direct$interval_status, rep("wald_unavailable", 4L))
  expect_match(direct$failure_class, "no_finite_wald_intervals")
  expect_equal(derived$observed_target_rows, rep(0L, 6L))
  expect_equal(
    derived$failure_class,
    rep("derived_correlation_interval_reconstruction_not_available", 6L)
  )
  expect_equal(status$interval_claim_status, rep("blocked", nrow(status)))
  expect_equal(status$status, rep("covered", nrow(status)))
  expect_true(all(grepl("no q4 interval reliability", status$claim_boundary)))
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
  expect_equal(
    nrow(utils::read.csv(out$paths$q4_interval_diagnostic_plan_csv)),
    10L
  )
  expect_equal(nrow(utils::read.csv(out$paths$pilot_replicates_csv)), 2L)
  expect_equal(nrow(utils::read.csv(out$paths$pilot_denominators_csv)), 1L)
  expect_equal(nrow(utils::read.csv(out$paths$calibration_gate_csv)), 1L)
  expect_equal(nrow(out$q4_interval_diagnostic_plan), 10L)
  expect_equal(nrow(out$pilot_replicates), 2L)
  expect_equal(out$pilot_denominators$n_total, 2L)
  expect_equal(out$calibration_gate$gate_status, "blocked")
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
