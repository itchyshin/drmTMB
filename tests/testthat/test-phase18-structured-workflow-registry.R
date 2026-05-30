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
