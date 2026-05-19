source_phase18_interval_evidence <- function(env = parent.frame()) {
  sim_path <- function(file) {
    path <- system.file(file.path("sim/R", file), package = "drmTMB")
    if (nzchar(path)) {
      return(path)
    }
    testthat::test_path("..", "..", "inst", "sim", "R", file)
  }
  source(sim_path("sim_uncertainty.R"), local = env)
  source(sim_path("sim_bootstrap.R"), local = env)
}

test_that("Phase 18 extracts profile-style interval columns as evidence rows", {
  source_phase18_interval_evidence()

  summary <- data.frame(
    surface = "biv_rho12",
    cell_id = "biv_rho12_001",
    replicate = 1L,
    parameter = c("mu1:(Intercept)", "rho12:x", "sigma1:z", "sigma2:z"),
    truth = c(0.20, 0.40, 0.70, 0.90),
    profile.conf.low = c(0.10, 0.25, 0.50, NA_real_),
    profile.conf.high = c(0.30, 0.55, 0.90, NA_real_),
    profile.conf.level = 0.70,
    profile.method = "profile",
    profile.interval_scale = "formula_coefficient",
    profile.status = c("profile", "ok", "not_requested", "failed"),
    profile.message = c("", "", "planned for later slice", "profile failed"),
    stringsAsFactors = FALSE
  )

  out <- phase18_intervals_from_columns(
    summary,
    prefix = "profile",
    interval_scale = "profile_public"
  )

  expect_equal(out$conf.low, summary$profile.conf.low)
  expect_equal(out$conf.high, summary$profile.conf.high)
  expect_equal(out$conf.level, rep(0.70, 4L))
  expect_equal(out$interval_method, rep("profile", 4L))
  expect_equal(out$interval_scale, rep("profile_public", 4L))
  expect_equal(
    out$interval_status,
    c("ok", "ok", "not_requested", "failed")
  )
  expect_equal(out$interval_message, summary$profile.message)
})

test_that("Phase 18 combines Wald, profile, and bootstrap interval evidence", {
  source_phase18_interval_evidence()

  wald <- data.frame(
    surface = "gaussian_ls",
    cell_id = "gaussian_ls_001",
    replicate = c(1L, 2L),
    parameter = c("mu:x", "sigma:z"),
    truth = c(0.10, 0.50),
    conf.low = c(0.00, NA_real_),
    conf.high = c(0.20, NA_real_),
    conf.level = 0.95,
    interval_method = "wald",
    interval_scale = "public",
    interval_status = c("ok", "failed"),
    interval_message = c("", "missing standard error"),
    stringsAsFactors = FALSE
  )

  profile_columns <- data.frame(
    surface = "gaussian_ls",
    cell_id = "gaussian_ls_001",
    replicate = c(1L, 2L),
    parameter = c("mu:(Intercept)", "sigma:(Intercept)"),
    truth = c(0.25, 0.70),
    profile.conf.low = c(0.15, 0.40),
    profile.conf.high = c(0.35, 1.00),
    profile.conf.level = 0.70,
    profile.method = "profile",
    profile.interval_scale = "formula_coefficient",
    profile.status = c("ok", "not_requested"),
    profile.message = c("", "not profiled in this smoke run"),
    stringsAsFactors = FALSE
  )
  profile <- phase18_intervals_from_columns(profile_columns, prefix = "profile")

  draws <- data.frame(
    parameter = c(rep("mu:x", 3L), "sigma:z"),
    estimate = c(0.05, 0.10, 0.15, 0.55),
    status = "ok",
    stringsAsFactors = FALSE
  )
  bootstrap <- phase18_bootstrap_percentile_intervals(
    draws,
    conf.level = 0.80
  )

  evidence <- phase18_interval_evidence_table(wald, profile, bootstrap)

  expect_equal(nrow(evidence), 6L)
  expect_equal(evidence$artifact_grain, rep("interval_evidence", 6L))
  expect_setequal(
    evidence$interval_method,
    c("wald", "profile", "parametric_bootstrap")
  )
  expect_true("n_bootstrap" %in% names(evidence))
  expect_true(all(is.na(
    evidence$n_bootstrap[seq_len(nrow(wald) + nrow(profile))]
  )))
  expect_equal(
    evidence$interval_status,
    c("ok", "failed", "ok", "not_requested", "ok", "failed")
  )

  failures <- phase18_interval_failures(evidence)
  expect_equal(
    failures$parameter,
    c("sigma:z", "sigma:(Intercept)", "sigma:z")
  )
  expect_equal(
    failures$interval_failure_status,
    c("failed", "not_requested", "failed")
  )
})

test_that("Phase 18 coverage excludes planned and unavailable intervals", {
  source_phase18_interval_evidence()

  evidence <- data.frame(
    surface = "meta_v",
    known_v_type = "dense",
    cell_id = "meta_v_dense_001",
    parameter = "sigma",
    truth = c(0.50, 0.50, 0.50, 0.50),
    conf.low = c(0.40, 0.40, 0.40, NA_real_),
    conf.high = c(0.60, 0.60, 0.60, NA_real_),
    interval_status = c("ok", "not_requested", "failed", "failed"),
    interval_message = c("", "planned", "profile failed", "bootstrap failed"),
    stringsAsFactors = FALSE
  )

  coverage <- phase18_summarise_interval_coverage(evidence)

  expect_equal(coverage$n_replicate, 4L)
  expect_equal(coverage$n_interval, 1L)
  expect_equal(coverage$coverage, 0.25)
  expect_equal(coverage$mean_interval_width, 0.20)
})

test_that("Phase 18 interval diagnostics separate failures from misses", {
  source_phase18_interval_evidence()

  evidence <- data.frame(
    surface = "student_shape",
    cell_id = "student_shape_001",
    parameter = "nu:w",
    interval_method = c("profile", "profile", "profile", "bootstrap"),
    truth = c(0.25, 0.25, 0.25, 0.25),
    conf.low = c(0.10, 0.40, NA_real_, 0.40),
    conf.high = c(0.30, 0.60, NA_real_, 0.60),
    interval_status = c("ok", "ok", "failed", "ok"),
    interval_message = c("", "", "profile failed", ""),
    stringsAsFactors = FALSE
  )

  diagnostics <- phase18_summarise_interval_evidence(
    evidence,
    by = c("surface", "cell_id", "parameter", "interval_method")
  )
  diagnostics <- diagnostics[order(diagnostics$interval_method), ]
  row.names(diagnostics) <- NULL

  expect_equal(diagnostics$interval_method, c("bootstrap", "profile"))
  expect_equal(diagnostics$n_replicate, c(1L, 3L))
  expect_equal(diagnostics$n_interval, c(1L, 2L))
  expect_equal(diagnostics$n_covered, c(0L, 1L))
  expect_equal(diagnostics$n_interval_missed, c(1L, 1L))
  expect_equal(diagnostics$n_interval_unusable, c(0L, 1L))
  expect_equal(diagnostics$n_ok, c(1L, 2L))
  expect_equal(diagnostics$n_failed, c(0L, 1L))
  expect_equal(diagnostics$interval_success_rate, c(1, 2 / 3))
  expect_equal(diagnostics$coverage, c(0, 1 / 3))
  expect_equal(
    diagnostics$artifact_grain,
    rep("interval_diagnostics", 2L)
  )
})
