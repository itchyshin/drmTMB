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

test_that("Phase 18 random-slope workflow plan separates needed targets", {
  env <- new.env(parent = globalenv())
  source(phase18_structured_workflow_registry_script(), local = env)

  registry <- env$phase18_read_structured_workflow_registry(
    path = phase18_structured_workflow_registry_csv()
  )
  plan <- env$phase18_random_slope_workflow_plan(registry)
  needed <- plan$lane_id == "bivariate_gaussian_slope_only"

  expect_true(any(needed))
  expect_equal(plan$dispatch_status[needed], "needs_wrapper_target")
  expect_equal(plan$workflow_helper[needed], "random_slope_wrapper")
  expect_true(is.na(plan$actions_task[needed]))
  expect_true(all(
    plan$dispatch_status[!needed] %in%
      c("ready_existing_task", "source_test_audit")
  ))
  expect_false(any(is.na(plan$actions_task[!needed])))
})

test_that("Phase 18 random-slope workflow plan can omit needed targets", {
  env <- new.env(parent = globalenv())
  source(phase18_structured_workflow_registry_script(), local = env)

  registry <- env$phase18_read_structured_workflow_registry(
    path = phase18_structured_workflow_registry_csv()
  )
  plan <- env$phase18_random_slope_workflow_plan(
    registry,
    include_needed = FALSE
  )

  expect_equal(nrow(plan), 8L)
  expect_false("bivariate_gaussian_slope_only" %in% plan$lane_id)
  expect_false(any(is.na(plan$actions_task)))
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
  expect_true(all(plan$dispatch_status[gaussian] == "needs_wrapper_target"))
  expect_true(all(is.na(plan$actions_task[gaussian])))
  expect_true(all(
    plan$workflow_helper[gaussian] == "structured_dependence_wrapper"
  ))
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
    plan$dispatch_status[group_q4 | structured_q4] ==
      "diagnostic_wrapper_target"
  ))
})

test_that("Phase 18 correlation-block plan separates q2 wrapper targets", {
  env <- new.env(parent = globalenv())
  source(phase18_structured_workflow_registry_script(), local = env)

  registry <- env$phase18_read_structured_workflow_registry(
    path = phase18_structured_workflow_registry_csv()
  )
  plan <- env$phase18_correlation_block_workflow_plan(registry)
  structured_q2 <- plan$lane_id == "structured_gaussian_q2"

  expect_equal(plan$dispatch_status[structured_q2], "needs_wrapper_target")
  expect_equal(
    plan$workflow_helper[structured_q2],
    "correlation_block_wrapper"
  )
  expect_equal(
    plan$interval_policy[structured_q2],
    "direct_or_layer_specific_q2"
  )
  expect_true(is.na(plan$actions_task[structured_q2]))
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
  expect_equal(counts$wrapper_targets[random], 1L)
  expect_equal(counts$wrapper_targets[structured], 4L)
  expect_equal(counts$wrapper_targets[correlation], 3L)
  expect_equal(counts$diagnostic_only[correlation], 2L)
})
