phase18_structured_workflow_registry_script <- function() {
  candidates <- c(
    testthat::test_path(
      "..",
      "..",
      "inst",
      "sim",
      "run",
      "sim_phase18_structured_workflow_registry.R"
    ),
    system.file(
      "sim",
      "run",
      "sim_phase18_structured_workflow_registry.R",
      package = "drmTMB"
    )
  )
  candidates <- candidates[nzchar(candidates)]
  candidates <- candidates[file.exists(candidates)]
  testthat::expect_true(
    length(candidates) > 0L,
    info = "Could not find Phase 18 structured workflow registry helper"
  )
  normalizePath(candidates[[1]], winslash = "/", mustWork = TRUE)
}

phase18_structured_workflow_registry_csv <- function() {
  candidates <- c(
    testthat::test_path(
      "..",
      "..",
      "inst",
      "sim",
      "registry",
      "phase18_structured_workflow_registry.csv"
    ),
    system.file(
      "sim",
      "registry",
      "phase18_structured_workflow_registry.csv",
      package = "drmTMB"
    )
  )
  candidates <- candidates[nzchar(candidates)]
  candidates <- candidates[file.exists(candidates)]
  testthat::expect_true(
    length(candidates) > 0L,
    info = "Could not find Phase 18 structured workflow registry CSV"
  )
  normalizePath(candidates[[1]], winslash = "/", mustWork = TRUE)
}

phase18_actions_runner_script_for_registry <- function() {
  candidates <- c(
    testthat::test_path(
      "..",
      "..",
      "inst",
      "sim",
      "run",
      "sim_run_actions_cell.R"
    ),
    system.file(
      "sim",
      "run",
      "sim_run_actions_cell.R",
      package = "drmTMB"
    )
  )
  candidates <- candidates[nzchar(candidates)]
  candidates <- candidates[file.exists(candidates)]
  testthat::expect_true(
    length(candidates) > 0L,
    info = "Could not find Phase 18 Actions runner"
  )
  normalizePath(candidates[[1]], winslash = "/", mustWork = TRUE)
}

test_that("Phase 18 structured workflow registry validates current rows", {
  env <- new.env(parent = globalenv())
  source(phase18_structured_workflow_registry_script(), local = env)

  registry <- env$phase18_read_structured_workflow_registry(
    path = phase18_structured_workflow_registry_csv()
  )
  status_counts <- table(registry$admission_status)

  expect_equal(nrow(registry), 34L)
  expect_equal(unname(status_counts[["ready_grid"]]), 18L)
  expect_equal(unname(status_counts[["blocked"]]), 4L)
  expect_equal(unname(status_counts[["design_only"]]), 1L)
  expect_equal(anyDuplicated(registry$lane_id), 0L)
})

test_that("Phase 18 structured workflow registry path prefers checkout files", {
  env <- new.env(parent = globalenv())
  source(phase18_structured_workflow_registry_script(), local = env)

  path <- env$phase18_structured_workflow_registry_path()

  expected <- normalizePath(
    phase18_structured_workflow_registry_csv(),
    winslash = "/",
    mustWork = TRUE
  )

  expect_equal(normalizePath(path, winslash = "/", mustWork = TRUE), expected)
})

test_that("Phase 18 structured workflow registry summarizes and filters lanes", {
  env <- new.env(parent = globalenv())
  source(phase18_structured_workflow_registry_script(), local = env)

  registry <- env$phase18_read_structured_workflow_registry(
    path = phase18_structured_workflow_registry_csv()
  )
  summary <- env$phase18_structured_workflow_registry_summary(registry)
  ready_random <- env$phase18_admitted_structured_workflow_rows(
    registry,
    workflow_lane = "random_slopes"
  )

  expect_equal(sum(summary$n), nrow(registry))
  expect_true(all(ready_random$workflow_lane == "random_slopes"))
  expect_true(all(
    ready_random$admission_status %in%
      env$phase18_structured_workflow_admitted_statuses()
  ))
  expect_false(any(ready_random$admission_status == "blocked"))
})

test_that("Phase 18 structured workflow registry rejects duplicated lane IDs", {
  env <- new.env(parent = globalenv())
  source(phase18_structured_workflow_registry_script(), local = env)

  registry <- env$phase18_read_structured_workflow_registry(
    path = phase18_structured_workflow_registry_csv()
  )
  registry$lane_id[[2L]] <- registry$lane_id[[1L]]

  expect_error(
    env$phase18_validate_structured_workflow_registry(registry),
    "`lane_id` values must be unique",
    fixed = TRUE
  )
})

test_that("Phase 18 structured workflow registry rejects blocked task promotion", {
  env <- new.env(parent = globalenv())
  source(phase18_structured_workflow_registry_script(), local = env)

  registry <- env$phase18_read_structured_workflow_registry(
    path = phase18_structured_workflow_registry_csv()
  )
  blocked <- which(registry$admission_status == "blocked")[[1L]]
  registry$existing_actions_task[[blocked]] <- "first_wave_summary"

  expect_error(
    env$phase18_validate_structured_workflow_registry(registry),
    "Rows marked `blocked` or `design_only` must not name an Actions task",
    fixed = TRUE
  )
})

test_that("Phase 18 structured workflow registry rejects unknown Actions tasks", {
  env <- new.env(parent = globalenv())
  source(phase18_structured_workflow_registry_script(), local = env)

  registry <- env$phase18_read_structured_workflow_registry(
    path = phase18_structured_workflow_registry_csv()
  )
  row <- which(registry$existing_actions_task != "none")[[1L]]
  registry$existing_actions_task[[row]] <- "made_up_actions_task"

  expect_error(
    env$phase18_validate_structured_workflow_registry(registry),
    "known Phase 18 Actions task",
    fixed = TRUE
  )
})

test_that("Phase 18 structured workflow registry uses runner task choices", {
  actions_env <- new.env(parent = globalenv())
  source(phase18_actions_runner_script_for_registry(), local = actions_env)
  registry_env <- new.env(parent = actions_env)
  source(phase18_structured_workflow_registry_script(), local = registry_env)

  expect_setequal(
    registry_env$phase18_structured_workflow_actions_tasks(),
    actions_env$phase18_actions_task_choices()
  )
})

test_that("Phase 18 random-slope workflow plan returns admitted rows", {
  env <- new.env(parent = globalenv())
  source(phase18_structured_workflow_registry_script(), local = env)

  registry <- env$phase18_read_structured_workflow_registry(
    path = phase18_structured_workflow_registry_csv()
  )
  plan <- env$phase18_random_slope_workflow_plan(registry)

  expect_equal(nrow(plan), 9L)
  expect_true(all(
    plan$admission_status %in%
      c(
        "ready_grid",
        "ready_source_test"
      )
  ))
  expect_false(any(
    plan$admission_status %in%
      c(
        "blocked",
        "design_only",
        "diagnostic_only"
      )
  ))
  expect_true(all(plan$dependence == "ordinary_group"))
  expect_true(all(nzchar(plan$audit_focus)))
})

test_that("Phase 18 random-slope workflow plan dispatches the bivariate slope task", {
  env <- new.env(parent = globalenv())
  source(phase18_structured_workflow_registry_script(), local = env)

  registry <- env$phase18_read_structured_workflow_registry(
    path = phase18_structured_workflow_registry_csv()
  )
  plan <- env$phase18_random_slope_workflow_plan(registry)
  bivariate <- plan$lane_id == "bivariate_gaussian_slope_only"

  expect_true(any(bivariate))
  expect_equal(plan$dispatch_status[bivariate], "ready_existing_task")
  expect_equal(plan$workflow_helper[bivariate], "phase18_actions_main")
  expect_equal(plan$actions_task[bivariate], "biv_gaussian_mu_slope")
  expect_true(all(
    plan$dispatch_status[!bivariate] %in%
      c("ready_existing_task", "source_test_audit")
  ))
  expect_false(any(is.na(plan$actions_task)))
})

test_that("Phase 18 random-slope workflow plan no longer has needed targets", {
  env <- new.env(parent = globalenv())
  source(phase18_structured_workflow_registry_script(), local = env)

  registry <- env$phase18_read_structured_workflow_registry(
    path = phase18_structured_workflow_registry_csv()
  )
  plan <- env$phase18_random_slope_workflow_plan(
    registry,
    include_needed = FALSE
  )

  expect_equal(nrow(plan), 9L)
  expect_true("bivariate_gaussian_slope_only" %in% plan$lane_id)
  expect_false(any(is.na(plan$actions_task)))
})

test_that("Phase 18 random-slope wrapper target plan is empty after wiring", {
  env <- new.env(parent = globalenv())
  source(phase18_structured_workflow_registry_script(), local = env)

  registry <- env$phase18_read_structured_workflow_registry(
    path = phase18_structured_workflow_registry_csv()
  )
  targets <- env$phase18_random_slope_wrapper_target_plan(registry)

  expect_equal(nrow(targets), 0L)
  expect_true("artifact_writer" %in% names(targets))
})

test_that("Phase 18 random-slope workflow plan excludes blocked rows", {
  env <- new.env(parent = globalenv())
  source(phase18_structured_workflow_registry_script(), local = env)

  registry <- env$phase18_read_structured_workflow_registry(
    path = phase18_structured_workflow_registry_csv()
  )
  blocked <- registry[registry$lane_id == "gaussian_ordinary_mu_slopes", ]
  blocked$lane_id <- "mock_blocked_random_slope"
  blocked$admission_status <- "blocked"
  blocked$existing_actions_task <- "none"
  registry <- rbind(registry, blocked)

  plan <- env$phase18_random_slope_workflow_plan(registry)

  expect_false("mock_blocked_random_slope" %in% plan$lane_id)
  expect_equal(nrow(plan), 9L)
})

test_that("Phase 18 random-slope operating-characteristic plan is a planning table", {
  env <- new.env(parent = globalenv())
  source(phase18_structured_workflow_registry_script(), local = env)

  registry <- env$phase18_read_structured_workflow_registry(
    path = phase18_structured_workflow_registry_csv()
  )
  plan <- env$phase18_random_slope_operating_characteristic_plan(registry)
  required <- c(
    "lane_id",
    "family_group",
    "family_route",
    "dpar",
    "dependence",
    "admission_status",
    "existing_actions_task",
    "accuracy_status",
    "coverage_status",
    "power_status",
    "minimum_estimands",
    "boundary_note"
  )

  expect_equal(nrow(plan), 9L)
  expect_true(all(required %in% names(plan)))
  expect_false(any(
    plan$admission_status %in%
      c(
        "blocked",
        "design_only",
        "diagnostic_only"
      )
  ))
  expect_true(all(plan$coverage_status == "planned_not_estimated"))
  expect_true(all(plan$power_status == "planned_not_estimated"))
  expect_true(all(nzchar(plan$minimum_estimands)))
  expect_true(all(nzchar(plan$boundary_note)))
})

test_that("Phase 18 random-slope operating-characteristic plan can omit source-test rows", {
  env <- new.env(parent = globalenv())
  source(phase18_structured_workflow_registry_script(), local = env)

  registry <- env$phase18_read_structured_workflow_registry(
    path = phase18_structured_workflow_registry_csv()
  )
  plan <- env$phase18_random_slope_operating_characteristic_plan(
    registry,
    include_source_test = FALSE
  )

  expect_equal(nrow(plan), 5L)
  expect_false(any(plan$admission_status == "ready_source_test"))
  expect_true(all(
    plan$accuracy_status != "source_tests_exist_artifact_lane_needed"
  ))
})

test_that("Phase 18 structured-dependence workflow plan returns audit rows", {
  env <- new.env(parent = globalenv())
  source(phase18_structured_workflow_registry_script(), local = env)

  registry <- env$phase18_read_structured_workflow_registry(
    path = phase18_structured_workflow_registry_csv()
  )
  plan <- env$phase18_structured_dependence_workflow_plan(registry)

  expect_equal(nrow(plan), 7L)
  expect_equal(sum(plan$admission_status == "ready_grid"), 4L)
  expect_equal(sum(plan$admission_status == "smoke_formal_admission"), 1L)
  expect_equal(sum(plan$admission_status == "hold_smoke_only"), 1L)
  expect_equal(sum(plan$admission_status == "diagnostic_only"), 1L)
  expect_false(any(plan$admission_status %in% c("blocked", "design_only")))
  expect_true(all(nzchar(plan$audit_focus)))
})

test_that("Phase 18 structured-dependence plan separates wrapper and task rows", {
  env <- new.env(parent = globalenv())
  source(phase18_structured_workflow_registry_script(), local = env)

  registry <- env$phase18_read_structured_workflow_registry(
    path = phase18_structured_workflow_registry_csv()
  )
  plan <- env$phase18_structured_dependence_workflow_plan(registry)
  gaussian <- plan$family_group == "continuous_gaussian"
  poisson <- plan$lane_id == "poisson_phylo_q1_formal"
  nbinom2 <- plan$lane_id == "nbinom2_phylo_q1_formal"
  count <- plan$lane_id == "count_structured_q1"

  expect_equal(sum(gaussian), 4L)
  expect_true(all(
    plan$dispatch_status[gaussian] == "ready_existing_task"
  ))
  expect_true(all(
    plan$workflow_helper[gaussian] == "phase18_actions_main"
  ))
  expect_setequal(
    plan$actions_task[gaussian],
    c(
      "phylo_mu_slope",
      "spatial_mu_slope",
      "animal_mu_slope",
      "relmat_mu_slope"
    )
  )
  expect_equal(plan$dispatch_status[poisson], "formal_admission_task")
  expect_equal(plan$actions_task[poisson], "poisson_phylo_q1_formal")
  expect_equal(plan$dispatch_status[nbinom2], "hold_smoke_audit")
  expect_equal(plan$actions_task[nbinom2], "nbinom2_phylo_q1_formal")
  expect_equal(plan$dispatch_status[count], "diagnostic_audit")
  expect_equal(plan$actions_task[count], "count_structured_q1")
})

test_that("Phase 18 structured-dependence plan can omit held rows", {
  env <- new.env(parent = globalenv())
  source(phase18_structured_workflow_registry_script(), local = env)

  registry <- env$phase18_read_structured_workflow_registry(
    path = phase18_structured_workflow_registry_csv()
  )
  plan <- env$phase18_structured_dependence_workflow_plan(
    registry,
    include_held = FALSE
  )

  expect_equal(nrow(plan), 5L)
  expect_false(any(
    plan$admission_status %in%
      c(
        "hold_smoke_only",
        "diagnostic_only"
      )
  ))
})

test_that("Phase 18 structured-dependence plan excludes blocked rows", {
  env <- new.env(parent = globalenv())
  source(phase18_structured_workflow_registry_script(), local = env)

  registry <- env$phase18_read_structured_workflow_registry(
    path = phase18_structured_workflow_registry_csv()
  )
  blocked <- registry[registry$lane_id == "gaussian_phylo_mu_one_slope", ]
  blocked$lane_id <- "mock_blocked_structured_dependence"
  blocked$admission_status <- "blocked"
  blocked$existing_actions_task <- "none"
  registry <- rbind(registry, blocked)

  plan <- env$phase18_structured_dependence_workflow_plan(registry)

  expect_false("mock_blocked_structured_dependence" %in% plan$lane_id)
  expect_equal(nrow(plan), 7L)
})

test_that("Phase 18 correlation-block workflow plan separates interval states", {
  env <- new.env(parent = globalenv())
  source(phase18_structured_workflow_registry_script(), local = env)

  registry <- env$phase18_read_structured_workflow_registry(
    path = phase18_structured_workflow_registry_csv()
  )
  plan <- env$phase18_correlation_block_workflow_plan(registry)

  expect_equal(nrow(plan), 6L)
  expect_equal(sum(plan$admission_status == "ready_grid"), 3L)
  expect_equal(sum(plan$admission_status == "ready_or_smoke"), 1L)
  expect_equal(sum(plan$admission_status == "diagnostic_only"), 2L)
  expect_false(any(plan$admission_status %in% c("blocked", "design_only")))
  expect_true(all(nzchar(plan$audit_focus)))
})

test_that("Phase 18 correlation-block plan protects residual and q4 policies", {
  env <- new.env(parent = globalenv())
  source(phase18_structured_workflow_registry_script(), local = env)

  registry <- env$phase18_read_structured_workflow_registry(
    path = phase18_structured_workflow_registry_csv()
  )
  plan <- env$phase18_correlation_block_workflow_plan(registry)
  rho12 <- plan$lane_id == "bivariate_gaussian_rho12"
  group_q4 <- plan$lane_id == "bivariate_gaussian_group_q4"
  structured_q4 <- plan$lane_id == "structured_gaussian_q4"

  expect_equal(plan$dispatch_status[rho12], "ready_existing_task")
  expect_equal(plan$actions_task[rho12], "interval_heavy_summary")
  expect_equal(plan$interval_policy[rho12], "direct_residual_rho12")
  expect_equal(
    plan$interval_policy[group_q4],
    "q4_derived_interval_unavailable"
  )
  expect_equal(
    plan$interval_policy[structured_q4],
    "q4_derived_interval_unavailable"
  )
  expect_true(all(
    plan$dispatch_status[group_q4 | structured_q4] == "diagnostic_audit"
  ))
  expect_true(all(
    plan$actions_task[group_q4 | structured_q4] == "correlation_block_status"
  ))
})

test_that("Phase 18 correlation-block plan routes q2 status artifacts", {
  env <- new.env(parent = globalenv())
  source(phase18_structured_workflow_registry_script(), local = env)

  registry <- env$phase18_read_structured_workflow_registry(
    path = phase18_structured_workflow_registry_csv()
  )
  plan <- env$phase18_correlation_block_workflow_plan(registry)
  structured_q2 <- plan$lane_id == "structured_gaussian_q2"

  expect_equal(plan$dispatch_status[structured_q2], "ready_or_smoke_audit")
  expect_equal(
    plan$workflow_helper[structured_q2],
    "phase18_actions_main"
  )
  expect_equal(
    plan$interval_policy[structured_q2],
    "direct_or_layer_specific_q2"
  )
  expect_equal(plan$actions_task[structured_q2], "correlation_block_status")
})

test_that("Phase 18 correlation-block plan can omit diagnostic rows", {
  env <- new.env(parent = globalenv())
  source(phase18_structured_workflow_registry_script(), local = env)

  registry <- env$phase18_read_structured_workflow_registry(
    path = phase18_structured_workflow_registry_csv()
  )
  plan <- env$phase18_correlation_block_workflow_plan(
    registry,
    include_diagnostic = FALSE
  )

  expect_equal(nrow(plan), 4L)
  expect_false(any(plan$admission_status == "diagnostic_only"))
  expect_false(any(grepl("q4", plan$block_q, fixed = TRUE)))
})

test_that("Phase 18 correlation-block plan excludes blocked rows", {
  env <- new.env(parent = globalenv())
  source(phase18_structured_workflow_registry_script(), local = env)

  registry <- env$phase18_read_structured_workflow_registry(
    path = phase18_structured_workflow_registry_csv()
  )
  plan <- env$phase18_correlation_block_workflow_plan(registry)

  expect_false("count_labelled_q2_q4" %in% plan$lane_id)
  expect_equal(nrow(plan), 6L)
})

test_that("Phase 18 correlation-block wrapper target plan is read-only", {
  env <- new.env(parent = globalenv())
  source(phase18_structured_workflow_registry_script(), local = env)

  registry <- env$phase18_read_structured_workflow_registry(
    path = phase18_structured_workflow_registry_csv()
  )
  wrapper_rows <- registry$lane_id %in%
    c(
      "structured_gaussian_q2",
      "bivariate_gaussian_group_q4",
      "structured_gaussian_q4"
    )
  registry$existing_actions_task[wrapper_rows] <-
    "needed:correlation_block_wrapper"
  targets <- env$phase18_correlation_block_wrapper_target_plan(registry)

  expect_equal(nrow(targets), 3L)
  expect_setequal(
    targets$lane_id,
    c(
      "structured_gaussian_q2",
      "bivariate_gaussian_group_q4",
      "structured_gaussian_q4"
    )
  )
  expect_true(all(targets$workflow_helper == "correlation_block_wrapper"))
  expect_true(all(is.na(targets$actions_task)))
  expect_true(all(
    targets$dispatch_mode == "read_only_no_models_or_actions"
  ))
  expect_true(all(nzchar(targets$required_evidence)))
})

test_that("Phase 18 correlation-block wrapper target plan labels q2 and q4", {
  env <- new.env(parent = globalenv())
  source(phase18_structured_workflow_registry_script(), local = env)

  registry <- env$phase18_read_structured_workflow_registry(
    path = phase18_structured_workflow_registry_csv()
  )
  wrapper_rows <- registry$lane_id %in%
    c(
      "structured_gaussian_q2",
      "bivariate_gaussian_group_q4",
      "structured_gaussian_q4"
    )
  registry$existing_actions_task[wrapper_rows] <-
    "needed:correlation_block_wrapper"
  targets <- env$phase18_correlation_block_wrapper_target_plan(registry)
  q2 <- targets$lane_id == "structured_gaussian_q2"
  q4 <- targets$block_q %in%
    c(
      "q4_intercept_corpairs",
      "q4_structured_corpairs"
    )

  expect_equal(
    targets$target_status[q2],
    "q2_interval_provenance_needed"
  )
  expect_true(all(targets$target_status[q4] == "q4_diagnostic_only"))
  expect_true(all(
    targets$interval_policy[q4] == "q4_derived_interval_unavailable"
  ))
})

test_that("Phase 18 correlation-block wrapper target plan can omit diagnostics", {
  env <- new.env(parent = globalenv())
  source(phase18_structured_workflow_registry_script(), local = env)

  registry <- env$phase18_read_structured_workflow_registry(
    path = phase18_structured_workflow_registry_csv()
  )
  wrapper_rows <- registry$lane_id %in%
    c(
      "structured_gaussian_q2",
      "bivariate_gaussian_group_q4",
      "structured_gaussian_q4"
    )
  registry$existing_actions_task[wrapper_rows] <-
    "needed:correlation_block_wrapper"
  targets <- env$phase18_correlation_block_wrapper_target_plan(
    registry,
    include_diagnostic = FALSE
  )

  expect_equal(nrow(targets), 1L)
  expect_equal(targets$lane_id, "structured_gaussian_q2")
  expect_equal(
    targets$target_status,
    "q2_interval_provenance_needed"
  )
})

test_that("Phase 18 correlation-block wrapper target plan is empty when wired", {
  env <- new.env(parent = globalenv())
  source(phase18_structured_workflow_registry_script(), local = env)

  registry <- env$phase18_read_structured_workflow_registry(
    path = phase18_structured_workflow_registry_csv()
  )
  targets <- env$phase18_correlation_block_wrapper_target_plan(registry)

  expect_equal(nrow(targets), 0L)
  expect_true("required_evidence" %in% names(targets))
  expect_true("dispatch_mode" %in% names(targets))
})

test_that("Phase 18 family-surface workflow plan keeps blocked rows visible", {
  env <- new.env(parent = globalenv())
  source(phase18_structured_workflow_registry_script(), local = env)

  registry <- env$phase18_read_structured_workflow_registry(
    path = phase18_structured_workflow_registry_csv()
  )
  plan <- env$phase18_family_surface_workflow_plan(registry)

  expect_equal(nrow(plan), 11L)
  expect_equal(sum(plan$admission_status == "ready_grid"), 6L)
  expect_equal(sum(plan$admission_status == "ready_smoke"), 1L)
  expect_equal(sum(plan$admission_status == "blocked"), 3L)
  expect_equal(sum(plan$admission_status == "design_only"), 1L)
  expect_true(all(nzchar(plan$audit_focus)))
})

test_that("Phase 18 family-surface plan separates admitted and blocked states", {
  env <- new.env(parent = globalenv())
  source(phase18_structured_workflow_registry_script(), local = env)

  registry <- env$phase18_read_structured_workflow_registry(
    path = phase18_structured_workflow_registry_csv()
  )
  plan <- env$phase18_family_surface_workflow_plan(registry)
  ready_grid <- plan$admission_status == "ready_grid"
  blocked <- plan$admission_status == "blocked"
  design <- plan$admission_status == "design_only"

  expect_true(all(plan$admission_category[ready_grid] == "admitted"))
  expect_true(all(plan$dispatch_status[ready_grid] == "ready_existing_task"))
  expect_false(any(is.na(plan$actions_task[ready_grid])))
  expect_true(all(plan$admission_category[blocked] == "blocked"))
  expect_true(all(
    plan$dispatch_status[blocked] == "blocked_design_required"
  ))
  expect_true(all(is.na(plan$actions_task[blocked])))
  expect_equal(plan$admission_category[design], "design_only")
  expect_equal(plan$dispatch_status[design], "design_required")
})

test_that("Phase 18 family-surface plan marks smoke-only rows", {
  env <- new.env(parent = globalenv())
  source(phase18_structured_workflow_registry_script(), local = env)

  registry <- env$phase18_read_structured_workflow_registry(
    path = phase18_structured_workflow_registry_csv()
  )
  plan <- env$phase18_family_surface_workflow_plan(registry)
  nb2_sigma <- plan$lane_id == "nbinom2_sigma_random_intercept"

  expect_equal(plan$admission_category[nb2_sigma], "smoke_only")
  expect_equal(plan$dispatch_status[nb2_sigma], "smoke_audit")
  expect_equal(plan$actions_task[nb2_sigma], "first_wave_summary")
})

test_that("Phase 18 family-surface plan can omit blocked rows", {
  env <- new.env(parent = globalenv())
  source(phase18_structured_workflow_registry_script(), local = env)

  registry <- env$phase18_read_structured_workflow_registry(
    path = phase18_structured_workflow_registry_csv()
  )
  plan <- env$phase18_family_surface_workflow_plan(
    registry,
    include_blocked = FALSE
  )

  expect_equal(nrow(plan), 7L)
  expect_false(any(plan$admission_status %in% c("blocked", "design_only")))
})

test_that("Phase 18 family-surface status tables summarize registry statuses", {
  env <- new.env(parent = globalenv())
  source(phase18_structured_workflow_registry_script(), local = env)

  registry <- env$phase18_read_structured_workflow_registry(
    path = phase18_structured_workflow_registry_csv()
  )
  tables <- env$phase18_family_surface_status_tables(registry)

  expect_named(
    tables,
    c(
      "row_summary",
      "category_summary",
      "distribution_summary"
    )
  )
  expect_equal(nrow(tables$row_summary), 11L)
  expect_true(all(tables$row_summary$status_scope == "registry_status_only"))
  expect_equal(sum(tables$category_summary$n), nrow(tables$row_summary))
  expect_equal(sum(tables$distribution_summary$n), nrow(tables$row_summary))
  expect_true(all(
    tables$category_summary$status_scope == "registry_status_only"
  ))
  expect_true(all(
    tables$distribution_summary$status_scope == "registry_status_only"
  ))

  category <- tables$category_summary
  expect_equal(
    unname(category$n[category$admission_category == "admitted"]),
    6L
  )
  expect_equal(
    unname(category$n[category$admission_category == "smoke_only"]),
    1L
  )
  expect_equal(
    unname(category$n[category$admission_category == "blocked"]),
    3L
  )
  expect_equal(
    unname(category$n[category$admission_category == "design_only"]),
    1L
  )

  distribution <- tables$distribution_summary
  counts <- distribution$family_group == "counts"
  ordinal <- distribution$family_group == "ordinal"
  expect_equal(sum(distribution$n[counts]), 2L)
  expect_equal(sum(distribution$n[ordinal]), 2L)
  expect_true("nbinom2()" %in% distribution$family_route[counts])
  expect_true(
    "zi_poisson;zi_nbinom2;hurdle_nbinom2" %in%
      distribution$family_route[counts]
  )
})

test_that("Phase 18 family-surface status tables can omit blocked rows", {
  env <- new.env(parent = globalenv())
  source(phase18_structured_workflow_registry_script(), local = env)

  registry <- env$phase18_read_structured_workflow_registry(
    path = phase18_structured_workflow_registry_csv()
  )
  tables <- env$phase18_family_surface_status_tables(
    registry,
    include_blocked = FALSE
  )

  expect_equal(nrow(tables$row_summary), 7L)
  expect_false(any(
    tables$row_summary$admission_status %in% c("blocked", "design_only")
  ))
  expect_false(any(
    tables$category_summary$admission_category %in%
      c("blocked", "design_only")
  ))
  expect_equal(sum(tables$distribution_summary$n), 7L)
})

test_that("Phase 18 family-surface status tables are empty-shaped", {
  env <- new.env(parent = globalenv())
  source(phase18_structured_workflow_registry_script(), local = env)

  registry <- env$phase18_read_structured_workflow_registry(
    path = phase18_structured_workflow_registry_csv()
  )
  registry <- registry[registry$workflow_lane != "family_surface", ]
  tables <- env$phase18_family_surface_status_tables(registry)

  expect_equal(nrow(tables$row_summary), 0L)
  expect_equal(nrow(tables$category_summary), 0L)
  expect_equal(nrow(tables$distribution_summary), 0L)
  expect_true("status_scope" %in% names(tables$row_summary))
  expect_true("status_scope" %in% names(tables$category_summary))
  expect_true("status_scope" %in% names(tables$distribution_summary))
})

test_that("Phase 18 structured workflow bundle returns all plan tables", {
  env <- new.env(parent = globalenv())
  source(phase18_structured_workflow_registry_script(), local = env)

  registry <- env$phase18_read_structured_workflow_registry(
    path = phase18_structured_workflow_registry_csv()
  )
  bundle <- env$phase18_structured_workflow_plan_bundle(registry)

  expect_named(
    bundle$plans,
    c(
      "random_slopes",
      "structured_dependence",
      "correlation_blocks",
      "family_surface"
    )
  )
  expect_s3_class(bundle$registry_summary, "data.frame")
  expect_s3_class(bundle$plan_counts, "data.frame")
  expect_equal(
    bundle$plan_counts$n[
      match("random_slopes", bundle$plan_counts$workflow_plan)
    ],
    9L
  )
  expect_equal(
    bundle$plan_counts$n[
      match("structured_dependence", bundle$plan_counts$workflow_plan)
    ],
    7L
  )
  expect_equal(
    bundle$plan_counts$n[
      match("correlation_blocks", bundle$plan_counts$workflow_plan)
    ],
    6L
  )
  expect_equal(
    bundle$plan_counts$n[
      match("family_surface", bundle$plan_counts$workflow_plan)
    ],
    11L
  )
})

test_that("Phase 18 structured workflow bundle counts dispatch states", {
  env <- new.env(parent = globalenv())
  source(phase18_structured_workflow_registry_script(), local = env)

  registry <- env$phase18_read_structured_workflow_registry(
    path = phase18_structured_workflow_registry_csv()
  )
  counts <- env$phase18_structured_workflow_plan_bundle(registry)$plan_counts
  family <- counts$workflow_plan == "family_surface"
  random <- counts$workflow_plan == "random_slopes"
  structured <- counts$workflow_plan == "structured_dependence"
  correlation <- counts$workflow_plan == "correlation_blocks"

  expect_equal(counts$existing_actions_tasks[family], 7L)
  expect_equal(counts$blocked[family], 3L)
  expect_equal(counts$design_only[family], 1L)
  expect_equal(counts$existing_actions_tasks[random], 9L)
  expect_equal(counts$wrapper_targets[random], 0L)
  expect_equal(counts$existing_actions_tasks[structured], 7L)
  expect_equal(counts$wrapper_targets[structured], 0L)
  expect_equal(counts$existing_actions_tasks[correlation], 6L)
  expect_equal(counts$wrapper_targets[correlation], 0L)
  expect_equal(counts$ready_or_smoke[correlation], 1L)
  expect_equal(counts$diagnostic_only[correlation], 2L)
})

test_that("Phase 18 structured workflow dry-run formats bundle status", {
  env <- new.env(parent = globalenv())
  source(phase18_structured_workflow_registry_script(), local = env)

  registry <- env$phase18_read_structured_workflow_registry(
    path = phase18_structured_workflow_registry_csv()
  )
  bundle <- env$phase18_structured_workflow_plan_bundle(registry)
  lines <- env$phase18_format_structured_workflow_bundle_dry_run(bundle)
  text <- paste(lines, collapse = "\n")

  expect_match(text, "No simulations, GitHub Actions jobs", fixed = TRUE)
  expect_match(text, "random_slopes", fixed = TRUE)
  expect_match(text, "structured_dependence", fixed = TRUE)
  expect_match(text, "bivariate_gaussian_slope_only", fixed = TRUE)
  expect_match(text, "blocked_design_required", fixed = TRUE)
})

test_that("Phase 18 structured workflow dry-run prints plan status", {
  env <- new.env(parent = globalenv())
  source(phase18_structured_workflow_registry_script(), local = env)

  registry <- env$phase18_read_structured_workflow_registry(
    path = phase18_structured_workflow_registry_csv()
  )
  plan <- env$phase18_random_slope_workflow_plan(registry)
  out <- capture.output(
    env$phase18_print_structured_workflow_plan_dry_run(
      plan,
      plan_name = "random_slopes"
    )
  )
  text <- paste(out, collapse = "\n")

  expect_match(text, "Plan: random_slopes", fixed = TRUE)
  expect_match(text, "ready_existing_task", fixed = TRUE)
  expect_match(text, "phase18_actions_main", fixed = TRUE)
})
