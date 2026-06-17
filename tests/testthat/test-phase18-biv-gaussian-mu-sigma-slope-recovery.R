source_phase18_biv_gaussian_mu_sigma_slope_recovery <- function() {
  env <- parent.frame()
  files <- c(
    "sim/R/sim_registry.R",
    "sim/R/sim_utils.R",
    "sim/R/sim_runner.R",
    "sim/R/sim_aggregate.R",
    "sim/R/sim_uncertainty.R",
    "sim/dgp/sim_dgp_biv_gaussian_mu_sigma_slope.R",
    "sim/fit/sim_summarise_biv_gaussian_mu_sigma_slope.R",
    "sim/run/sim_run_biv_gaussian_mu_sigma_slope_smoke.R",
    "sim/run/sim_summary_biv_gaussian_mu_sigma_slope_recovery.R",
    "sim/run/sim_write_biv_gaussian_mu_sigma_slope_recovery_grid.R",
    "sim/run/sim_audit_biv_gaussian_mu_sigma_slope_hardening.R"
  )
  for (file in files) {
    source(system.file(file, package = "drmTMB", mustWork = TRUE), local = env)
  }
}

test_that("Phase 18 mu/sigma slope recovery reports bias, MCSE, and coverage", {
  source_phase18_biv_gaussian_mu_sigma_slope_recovery()

  result_dir <- tempfile("phase18-biv-gaussian-mu-sigma-slope-recovery-")
  dir.create(result_dir)
  withr::defer(unlink(result_dir, recursive = TRUE))
  conditions <- phase18_biv_gaussian_mu_sigma_slope_conditions(
    n_id = 72L,
    n_each = 10L
  )

  out <- phase18_summarise_biv_gaussian_mu_sigma_slope_recovery(
    conditions = conditions,
    n_rep = 4L,
    master_seed = 20260630L,
    result_dir = result_dir
  )

  expect_identical(out$surface, "biv_gaussian_mu_sigma_slope_recovery")

  # Recovery aggregate keeps the same 12 estimands as the smoke lane, now with
  # bias and Monte Carlo standard error columns populated over replicates.
  expect_equal(nrow(out$aggregate), 12L)
  expect_true(all(c("bias", "rmse", "empirical_se") %in% names(out$aggregate)))
  expect_true(all(c("bias_mcse", "rmse_mcse") %in% names(out$aggregate)))
  expect_true(any(is.finite(out$aggregate$bias)))
  expect_true(any(is.finite(out$aggregate$bias_mcse)))

  # Wald coverage is reported for the endpoints that carry a standard error.
  expect_true(is.data.frame(out$wald_coverage))
  expect_true(all(c("coverage", "coverage_mcse") %in% names(out$wald_coverage)))
  expect_true(is.data.frame(out$wald_intervals))
  expect_true(all(c("conf.low", "conf.high") %in% names(out$wald_intervals)))
  expect_true(any(is.finite(out$wald_intervals$conf.low)))
})

test_that("Phase 18 mu/sigma slope recovery leaves SD and correlation Wald-unavailable", {
  source_phase18_biv_gaussian_mu_sigma_slope_recovery()

  result_dir <- tempfile("phase18-biv-gaussian-mu-sigma-slope-recovery-")
  dir.create(result_dir)
  withr::defer(unlink(result_dir, recursive = TRUE))

  out <- phase18_summarise_biv_gaussian_mu_sigma_slope_recovery(
    conditions = phase18_biv_gaussian_mu_sigma_slope_conditions(
      n_id = 72L,
      n_each = 10L
    ),
    n_rep = 4L,
    master_seed = 20260630L,
    result_dir = result_dir
  )

  # The random-effect SD and derived mu/sigma correlation rows have no Wald
  # standard error, so their interval endpoints stay NA rather than being
  # reported as interval-ready. Profile or bootstrap evidence is required
  # before treating this same-response correlation as interval-supported.
  intervals <- out$wald_intervals
  derived <- grepl("^sd:|^cor:", intervals$parameter)
  expect_true(any(derived))
  expect_true(all(is.na(intervals$conf.low[derived])))
  expect_true(all(is.na(intervals$conf.high[derived])))
})

test_that("Phase 18 mu/sigma slope recovery grid writer emits coverage tables", {
  source_phase18_biv_gaussian_mu_sigma_slope_recovery()

  output_dir <- tempfile("phase18-biv-gaussian-mu-sigma-slope-recovery-grid-")
  withr::defer(unlink(output_dir, recursive = TRUE))

  out <- phase18_write_biv_gaussian_mu_sigma_slope_recovery_grid_outputs(
    output_dir = output_dir,
    conditions = phase18_biv_gaussian_mu_sigma_slope_conditions(
      n_id = 72L,
      n_each = 10L
    ),
    n_rep = 4L,
    master_seed = 20260630L,
    overwrite = FALSE
  )

  expect_identical(out$surface, "biv_gaussian_mu_sigma_slope_recovery_grid")
  for (path in unlist(out$paths, use.names = FALSE)) {
    expect_true(file.exists(path))
  }
  aggregate <- utils::read.csv(out$paths$aggregate_csv)
  expect_equal(nrow(aggregate), 12L)
  expect_true("bias" %in% names(aggregate))

  expect_error(
    phase18_write_biv_gaussian_mu_sigma_slope_recovery_grid_outputs(
      output_dir = output_dir,
      n_rep = 4L,
      master_seed = 20260630L,
      overwrite = FALSE
    ),
    "already exists"
  )
})

test_that("Phase 18 mu/sigma slope hardening audit reads artifacts without refit", {
  source_phase18_biv_gaussian_mu_sigma_slope_recovery()

  artifact_dir <- tempfile("phase18-biv-gaussian-mu-sigma-slope-artifact-")
  audit_dir <- tempfile("phase18-biv-gaussian-mu-sigma-slope-audit-")
  withr::defer(unlink(c(artifact_dir, audit_dir), recursive = TRUE))

  phase18_write_biv_gaussian_mu_sigma_slope_recovery_grid_outputs(
    output_dir = artifact_dir,
    conditions = phase18_biv_gaussian_mu_sigma_slope_conditions(
      n_id = 72L,
      n_each = 10L
    ),
    n_rep = 2L,
    master_seed = 20260630L,
    overwrite = FALSE
  )

  out <- phase18_audit_biv_gaussian_mu_sigma_slope_hardening(
    artifact_dir = artifact_dir,
    output_dir = audit_dir,
    conditions = phase18_biv_gaussian_mu_sigma_slope_conditions(
      n_id = 72L,
      n_each = 10L
    ),
    n_rep = 2L,
    master_seed = 20260630L,
    run_refits = FALSE,
    profile_replicates_per_cell = 0L,
    overwrite = FALSE
  )

  expect_named(
    out$paths,
    c(
      "weak_replicates_csv",
      "robust_refit_status_csv",
      "robust_refit_summaries_csv",
      "robust_combined_fixed_wald_coverage_csv",
      "original_point_recovery_by_fit_status_csv",
      "robust_vs_original_weak_estimate_deltas_csv",
      "profile_feasibility_status_csv",
      "profile_feasibility_intervals_csv",
      "profile_feasibility_targets_csv"
    )
  )
  expect_true(all(file.exists(unlist(out$paths, use.names = FALSE))))
  expect_true(is.data.frame(out$weak_replicates))
  expect_true(is.data.frame(out$robust_combined_fixed_wald_coverage))
  expect_equal(nrow(out$robust_refit$status), 0L)
  expect_equal(nrow(out$profile_feasibility$status), 0L)

  coverage <- utils::read.csv(out$paths$robust_combined_fixed_wald_coverage_csv)
  expect_true(all(
    c("coverage_all", "coverage_interval_available") %in% names(coverage)
  ))
  expect_true(all(coverage$n_replicate == 2L))

  expect_error(
    phase18_audit_biv_gaussian_mu_sigma_slope_hardening(
      artifact_dir = artifact_dir,
      output_dir = audit_dir,
      conditions = phase18_biv_gaussian_mu_sigma_slope_conditions(
        n_id = 72L,
        n_each = 10L
      ),
      n_rep = 2L,
      master_seed = 20260630L,
      run_refits = FALSE,
      profile_replicates_per_cell = 0L,
      overwrite = FALSE
    ),
    "already exists"
  )
})
