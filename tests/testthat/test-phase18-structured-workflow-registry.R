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
