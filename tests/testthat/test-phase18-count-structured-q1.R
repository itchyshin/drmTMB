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

count_structured_q1_gate_rows <- function(
  cell_id,
  replicate,
  family = "nbinom2",
  structured_type = "spatial",
  hessian_status = "ok",
  sd_boundary_status = "ok",
  fit_diagnostic_status = "ok",
  warning_count = 0L,
  warnings = "",
  sd_structured = 0.60
) {
  data.frame(
    surface = "count_structured_q1",
    family = family,
    structured_type = structured_type,
    group = ifelse(structured_type == "spatial", "site", "id"),
    cell_id = cell_id,
    replicate = replicate,
    parameter = c("mu:(Intercept)", "mu:x", "sd:mu:structured"),
    parameter_class = c("fixed_mu", "fixed_mu", "structured_sd"),
    truth = c(1.0, 0.2, sd_structured),
    n_level = 16L,
    n_per_level = 8L,
    mean_count = 3.0,
    sigma_baseline = 0.45,
    geometry = "ring",
    matrix_decay = 0.4,
    converged = TRUE,
    pdHess = hessian_status == "ok",
    warning_count = warning_count,
    warnings = warnings,
    fit_diagnostic_status = fit_diagnostic_status,
    fit_diagnostic_message = ifelse(
      fit_diagnostic_status == "ok",
      "Selected fit-level diagnostics are ok.",
      "Selected fit-level diagnostics have warnings."
    ),
    hessian_status = hessian_status,
    hessian_message = ifelse(
      hessian_status == "ok",
      "Hessian is positive definite.",
      "Hessian is not positive definite."
    ),
    sd_boundary_status = sd_boundary_status,
    sd_boundary_message = ifelse(
      sd_boundary_status == "ok",
      "Random-effect SDs are away from the lower boundary.",
      "Random-effect SD is near the lower boundary."
    ),
    stringsAsFactors = FALSE
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

test_that("Phase 18 count structured q1 follow-up conditions split pilot roles", {
  source_count_structured_q1(run_files = FALSE)

  all_conditions <- phase18_count_structured_q1_followup_conditions("all")
  stable <- phase18_count_structured_q1_followup_conditions("stable")
  watch <- phase18_count_structured_q1_followup_conditions("stable_watch")
  stress <- phase18_count_structured_q1_followup_conditions("boundary_stress")

  expect_equal(nrow(all_conditions), 24L)
  expect_equal(nrow(stable), 10L)
  expect_equal(nrow(watch), 2L)
  expect_equal(nrow(stress), 12L)
  role_counts <- table(all_conditions$pilot_condition_role)
  expect_equal(
    as.integer(role_counts[c("boundary_stress", "stable", "stable_watch")]),
    c(12L, 10L, 2L)
  )
  expect_true(all(stable$sd_structured == 0.60))
  expect_true(all(stable$pilot_sd_boundary_status == "none"))
  expect_true(all(watch$pilot_sd_boundary_status == "lower_rate_warning"))
  expect_true(all(stress$sd_structured == 0.25))
  expect_equal(
    sum(stress$pilot_sd_boundary_status == "condition_trigger"),
    6L
  )
  expect_equal(unique(all_conditions$pilot_source_run), "26631771105")
})

test_that("Phase 18 count structured q1 profile trace plan uses selected examples", {
  source_count_structured_q1()

  plan <- phase18_count_structured_q1_profile_trace_plan()

  expect_equal(nrow(plan), 6L)
  expect_equal(
    unique(plan$cell_id),
    c(
      "count_structured_q1_006",
      "count_structured_q1_003",
      "count_structured_q1_001"
    )
  )
  expect_equal(
    unique(plan$example_role),
    c(
      "minimum_nonfinite_estimate",
      "minimum_crossing_estimate",
      "larger_crossing_estimate"
    )
  )
  expect_true(all(!is.na(plan$seed)))
  expect_equal(
    unique(plan$seed),
    c(932584520L, 461195966L, 32713190L)
  )
  expect_equal(unique(plan$profile_parameters), "log_sd_phylo")
  expect_equal(unique(plan$profile_level), 0.70)
  expect_equal(sort(unique(plan$ystep)), c(0.25, 0.50))
  expect_equal(unique(plan$profile_pass), c("current", "smaller_ystep"))
})

test_that("Phase 18 count structured q1 profile trace plan writes a table", {
  source_count_structured_q1()

  output_dir <- tempfile("phase18-count-structured-q1-trace-plan-")
  withr::defer(unlink(output_dir, recursive = TRUE))

  out <- phase18_write_count_structured_q1_profile_trace_plan(output_dir)
  written <- utils::read.csv(out$path)

  expect_equal(out$surface, "count_structured_q1_profile_trace_plan")
  expect_true(file.exists(out$path))
  expect_equal(nrow(written), 6L)
  expect_equal(
    unique(written$seed),
    c(932584520L, 461195966L, 32713190L)
  )
  expect_error(
    phase18_write_count_structured_q1_profile_trace_plan(output_dir),
    "already exists"
  )
})

test_that("Phase 18 count structured q1 profile trace result records traces", {
  source_count_structured_q1()

  plan_row <- phase18_count_structured_q1_profile_trace_plan()[
    1L,
    ,
    drop = FALSE
  ]
  fake_fit <- structure(list(), class = "drmTMB")
  fake_profile <- function(object, parm, level, ystep) {
    data.frame(
      profile_value = c(0.10, 0.20),
      delta_deviance = c(1.0, 0.0),
      stringsAsFactors = FALSE
    )
  }

  out <- phase18_count_structured_q1_profile_trace_result(
    fake_fit,
    plan_row,
    profile_fun = fake_profile
  )

  expect_equal(nrow(out), 2L)
  expect_equal(unique(out$trace_status), "ok")
  expect_equal(unique(out$cell_id), "count_structured_q1_006")
  expect_equal(unique(out$seed), 932584520L)
  expect_equal(out$profile_value, c(0.10, 0.20))
  expect_true(all(is.finite(out$trace_elapsed)))
})

test_that("Phase 18 count structured q1 profile trace result records failures", {
  source_count_structured_q1()

  plan_row <- phase18_count_structured_q1_profile_trace_plan()[
    1L,
    ,
    drop = FALSE
  ]
  fake_fit <- structure(list(), class = "drmTMB")
  failing_profile <- function(object, parm, level, ystep) {
    stop("profile failed", call. = FALSE)
  }

  out <- phase18_count_structured_q1_profile_trace_result(
    fake_fit,
    plan_row,
    profile_fun = failing_profile
  )

  expect_equal(nrow(out), 1L)
  expect_equal(out$trace_status, "failed")
  expect_match(out$trace_message, "profile failed")
  expect_equal(out$cell_id, "count_structured_q1_006")
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

test_that("Phase 18 count structured q1 boundary replicate exposes fit diagnostics", {
  source_count_structured_q1()

  conditions <- phase18_count_structured_q1_conditions(
    family = c("poisson", "nbinom2"),
    structured_type = c("spatial", "animal", "relmat"),
    n_level = c(10L, 16L),
    n_per_level = 8L,
    sd_structured = c(0.25, 0.60),
    mean_count = 3.0,
    sigma_baseline = 0.45,
    geometry = "ring"
  )
  cell <- conditions[
    conditions$family == "nbinom2" &
      conditions$structured_type == "spatial" &
      conditions$n_level == 16L &
      conditions$sd_structured == 0.60,
    ,
    drop = FALSE
  ]
  dat <- phase18_dgp_count_structured_q1_cell(
    cell = cell,
    seed = 1409019402L,
    cell_id = "count_structured_q1_020",
    replicate = 2L
  )
  fit <- phase18_fit_count_structured_q1(dat, cell)
  out <- suppressWarnings(
    phase18_summarise_count_structured_q1_fit(
      fit = fit,
      truth = dat,
      cell_id = "count_structured_q1_020",
      replicate = 2L
    )
  )
  structured <- out[
    out$parameter_class == "structured_sd",
    ,
    drop = FALSE
  ]

  expect_equal(unique(out$fit_diagnostic_status), "warning")
  expect_equal(unique(out$sd_boundary_status), "warning")
  expect_match(
    structured$sd_boundary_message,
    "near the lower boundary",
    fixed = TRUE
  )
  expect_lt(structured$estimate, 1e-4)
  expect_equal(structured$diagnostic_status, "ok")
  expect_equal(
    unique(out$hessian_status),
    if (isTRUE(fit$sdr$pdHess)) "ok" else "warning"
  )
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

  audit <- phase18_audit_count_structured_q1_boundary_gate(
    output_dir,
    require_complete = TRUE
  )

  expect_equal(audit$surface, "count_structured_q1_boundary_gate_audit")
  expect_equal(nrow(audit$boundary_gate$fits), 1L)
  expect_equal(audit$boundary_gate$decision$decision, "propose_next_pilot")
  expect_true("sd_structured" %in% names(out$summary$replicates))
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

test_that("Phase 18 count structured q1 profile audit reads artifacts", {
  source_count_structured_q1()

  output_dir <- tempfile("phase18-count-structured-q1-profile-audit-")
  withr::defer(unlink(output_dir, recursive = TRUE))
  table_dir <- file.path(output_dir, "tables")
  result_dir <- file.path(output_dir, "results", "count_structured_q1_001")
  dir.create(table_dir, recursive = TRUE)
  dir.create(result_dir, recursive = TRUE)
  paths <- phase18_count_structured_q1_grid_paths(table_dir)
  result_path <- file.path(result_dir, "replicate_0007.rds")
  saveRDS(
    list(
      surface = "count_structured_q1",
      summary = data.frame(
        parameter = "sd:mu:spatial(1 | site)",
        parameter_class = "structured_sd",
        truth = 0.60,
        estimate = 0.24,
        profile.conf.low = NA_real_,
        profile.conf.high = 0.42,
        profile.status = "failed",
        profile.message = "nonfinite_interval",
        profile_target_status = "ready",
        profile_target_parameter = "log_sd_phylo",
        stringsAsFactors = FALSE
      )
    ),
    result_path
  )
  utils::write.csv(
    data.frame(
      cell_id = "count_structured_q1_001",
      replicate = 7L,
      interval_status = "failed",
      interval_message = "nonfinite_interval",
      stringsAsFactors = FALSE
    ),
    paths$profile_intervals_csv,
    row.names = FALSE
  )

  audit <- phase18_audit_count_structured_q1_profile_gate(output_dir)

  expect_equal(audit$surface, "count_structured_q1_profile_gate_audit")
  expect_true("replicate_csv" %in% audit$missing_artifacts)
  expect_equal(audit$profile_gate$overall$n_interval, 1L)
  expect_equal(audit$profile_gate$decision$decision, "hold_interval_diagnostic")
  expect_equal(
    audit$profile_gate$failure_summary$example_result_path,
    normalizePath(result_path, mustWork = TRUE)
  )
  expect_true(audit$profile_gate$failure_summary$example_result_exists)
  expect_equal(
    audit$profile_gate$failure_summary$example_profile_detail_status,
    "ok"
  )
  expect_equal(
    audit$profile_gate$failure_summary$example_parameter,
    "sd:mu:spatial(1 | site)"
  )
  expect_equal(
    audit$profile_gate$failure_summary$example_profile_status,
    "failed"
  )
  expect_equal(
    audit$profile_gate$failure_summary$example_profile_target_parameter,
    "log_sd_phylo"
  )
  expect_equal(
    audit$profile_gate$failure_summary$example_profile_conf_high,
    0.42
  )
  expect_equal(nrow(audit$profile_gate$example_geometry_summary), 1L)
  expect_equal(
    audit$profile_gate$example_geometry_summary$failure_class,
    "nonfinite_interval"
  )
  expect_equal(audit$profile_gate$example_geometry_summary$failed_interval, 1L)
  expect_equal(
    audit$profile_gate$example_geometry_summary$n_missing_lower_endpoint,
    1L
  )
  expect_equal(
    audit$profile_gate$example_geometry_summary$n_missing_upper_endpoint,
    0L
  )
  expect_equal(
    audit$profile_gate$example_geometry_summary$min_example_estimate,
    0.24
  )
  expect_equal(
    audit$profile_gate$example_geometry_summary$max_example_estimate_over_truth,
    0.4
  )
  expect_equal(
    audit$profile_gate$example_geometry_summary$min_example_cell_id,
    "count_structured_q1_001"
  )
  expect_equal(
    audit$profile_gate$example_geometry_summary$min_example_replicate,
    7L
  )
})

test_that("Phase 18 count structured q1 boundary gate holds failed pilots", {
  source_count_structured_q1()

  replicates <- rbind(
    count_structured_q1_gate_rows("count_structured_q1_001", 1L),
    count_structured_q1_gate_rows(
      "count_structured_q1_001",
      2L,
      sd_boundary_status = "warning",
      fit_diagnostic_status = "warning"
    ),
    count_structured_q1_gate_rows(
      "count_structured_q1_002",
      1L,
      hessian_status = "warning",
      fit_diagnostic_status = "warning",
      warning_count = 1L,
      warnings = "optimizer stalled"
    ),
    count_structured_q1_gate_rows(
      "count_structured_q1_002",
      2L,
      sd_boundary_status = "warning",
      fit_diagnostic_status = "warning"
    )
  )
  failures <- data.frame(
    cell_id = "count_structured_q1_002",
    replicate = 1L,
    seed = 12L,
    status = "ok",
    severity = "warning",
    message = "optimizer stalled",
    skipped = FALSE,
    stringsAsFactors = FALSE
  )

  gate <- phase18_count_structured_q1_boundary_gate_summary(
    replicates,
    failures = failures
  )

  expect_equal(nrow(gate$fits), 4L)
  expect_equal(gate$overall$n_fit, 4L)
  expect_equal(gate$overall$hessian_warning, 1L)
  expect_equal(gate$overall$sd_boundary_warning, 2L)
  expect_equal(gate$fits$sd_structured, rep(0.60, 4L))
  expect_equal(gate$decision$decision, "hold_diagnostic")
  expect_equal(
    gate$checks$status[gate$checks$check == "hessian_rate"],
    "failed"
  )
  expect_equal(
    gate$checks$status[gate$checks$check == "sd_boundary_rate"],
    "failed"
  )
  expect_equal(
    gate$checks$status[gate$checks$check == "unexplained_warning_ledger"],
    "failed"
  )
})

test_that("Phase 18 count structured q1 boundary gate allows clean pilots", {
  source_count_structured_q1()

  rows <- list()
  index <- 0L
  for (cell in seq_len(5L)) {
    for (replicate in seq_len(2L)) {
      index <- index + 1L
      rows[[index]] <- count_structured_q1_gate_rows(
        sprintf("count_structured_q1_%03d", cell),
        replicate,
        structured_type = ifelse(cell %% 2L == 0L, "animal", "spatial"),
        sd_boundary_status = ifelse(index == 1L, "warning", "ok"),
        fit_diagnostic_status = ifelse(index == 1L, "warning", "ok")
      )
    }
  }
  gate <- phase18_count_structured_q1_boundary_gate_summary(do.call(
    rbind,
    rows
  ))

  expect_equal(nrow(gate$fits), 10L)
  expect_equal(gate$overall$sd_boundary_warning, 1L)
  expect_true(all(gate$checks$status == "ok"))
  expect_equal(gate$decision$decision, "propose_next_pilot")
})

test_that("Phase 18 count structured q1 profile gate holds failed intervals", {
  source_count_structured_q1()

  intervals <- rbind(
    data.frame(
      cell_id = "count_structured_q1_001",
      family = "poisson",
      structured_type = "spatial",
      n_level = 10L,
      sd_structured = 0.60,
      replicate = seq_len(89L),
      interval_status = "ok",
      stringsAsFactors = FALSE
    ),
    data.frame(
      cell_id = "count_structured_q1_001",
      family = "poisson",
      structured_type = "spatial",
      n_level = 10L,
      sd_structured = 0.60,
      replicate = 90:100,
      interval_status = "failed",
      stringsAsFactors = FALSE
    ),
    data.frame(
      cell_id = "count_structured_q1_003",
      family = "nbinom2",
      structured_type = "animal",
      n_level = 10L,
      sd_structured = 0.60,
      replicate = seq_len(94L),
      interval_status = "ok",
      stringsAsFactors = FALSE
    ),
    data.frame(
      cell_id = "count_structured_q1_003",
      family = "nbinom2",
      structured_type = "animal",
      n_level = 10L,
      sd_structured = 0.60,
      replicate = 95:100,
      interval_status = "failed",
      stringsAsFactors = FALSE
    )
  )
  intervals$interval_message <- "ok"
  intervals$interval_message[
    intervals$cell_id == "count_structured_q1_001" &
      intervals$interval_status == "failed"
  ] <- "nonfinite_interval"
  intervals$interval_message[
    intervals$cell_id == "count_structured_q1_003" &
      intervals$interval_status == "failed"
  ] <- "missing_crossing"

  gate <- phase18_count_structured_q1_profile_gate_summary(
    intervals,
    watch_cells = c("count_structured_q1_003")
  )

  expect_equal(gate$surface, "count_structured_q1_profile_gate")
  expect_equal(gate$overall$n_interval, 200L)
  expect_equal(gate$overall$failed_interval, 17L)
  expect_equal(gate$decision$decision, "hold_interval_diagnostic")
  expect_equal(
    gate$checks$status[gate$checks$check == "profile_interval_rate"],
    "failed"
  )
  expect_equal(
    gate$checks$status[
      gate$checks$check == "profile_condition_failure_rate"
    ],
    "failed"
  )
  expect_equal(
    gate$checks$status[gate$checks$check == "watch_profile_failure_rate"],
    "ok"
  )
  expect_equal(nrow(gate$failure_summary), 2L)
  expect_equal(gate$failure_summary$cell_id[1], "count_structured_q1_001")
  expect_equal(gate$failure_summary$failed_interval[1], 11L)
  expect_equal(gate$failure_summary$n_interval[1], 100L)
  expect_equal(gate$failure_summary$failure_class[1], "nonfinite_interval")
  expect_equal(
    gate$failure_summary$example_interval_message[1],
    "nonfinite_interval"
  )
  expect_equal(gate$failure_summary$example_replicate[1], 90L)
})

test_that("Phase 18 count structured q1 profile gate allows clean pilots", {
  source_count_structured_q1()

  intervals <- data.frame(
    cell_id = rep(
      c("count_structured_q1_001", "count_structured_q1_002"),
      each = 100L
    ),
    family = rep(c("poisson", "nbinom2"), each = 100L),
    structured_type = rep(c("spatial", "animal"), each = 100L),
    n_level = rep(10L, 200L),
    sd_structured = rep(0.60, 200L),
    replicate = rep(seq_len(100L), 2L),
    interval_status = "ok",
    stringsAsFactors = FALSE
  )
  intervals$interval_status[c(4, 55, 132)] <- "failed"
  intervals <- rbind(
    intervals,
    data.frame(
      cell_id = "count_structured_q1_002",
      family = "nbinom2",
      structured_type = "animal",
      n_level = 10L,
      sd_structured = 0.60,
      replicate = 101L,
      interval_status = "not_requested",
      stringsAsFactors = FALSE
    )
  )

  gate <- phase18_count_structured_q1_profile_gate_summary(
    intervals,
    watch_cells = c("count_structured_q1_002")
  )

  expect_equal(gate$overall$n_interval, 200L)
  expect_equal(gate$overall$failed_interval, 3L)
  expect_true(all(gate$checks$status == "ok"))
  expect_equal(gate$decision$decision, "propose_next_pilot")
})
