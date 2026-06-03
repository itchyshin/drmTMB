source_phase18_correlation_block_status <- function(env = parent.frame()) {
  source(
    system.file("sim/R/sim_runner.R", package = "drmTMB", mustWork = TRUE),
    local = env
  )
  source(
    system.file(
      "sim/run/sim_run_actions_cell.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
  source(
    system.file(
      "sim/run/sim_phase18_structured_workflow_registry.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
  source(
    system.file(
      "sim/run/sim_write_correlation_block_status.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
}

test_that("Phase 18 correlation-block status writer stages plan tables", {
  source_phase18_correlation_block_status()
  output_dir <- tempfile("phase18-correlation-block-status-")
  withr::defer(unlink(output_dir, recursive = TRUE))

  out <- phase18_write_correlation_block_status_outputs(
    output_dir = output_dir
  )

  expect_equal(out$surface, "phase18_correlation_block_status")
  expect_true(all(file.exists(unlist(out$paths, use.names = FALSE))))
  expect_equal(nrow(out$plan), 7L)
  expect_equal(nrow(out$dispatch), 7L)
  expect_equal(nrow(out$wrapper_targets), 0L)
  expect_equal(nrow(out$registry_summary), 4L)
  expect_equal(nrow(out$artifact_manifest), length(out$paths))
  expect_true(all(out$artifact_manifest$exists))
  expect_true("ready_or_smoke" %in% out$registry_summary$admission_status)
  expect_equal(
    unique(out$dispatch$actions_task[
      out$dispatch$lane_id == "structured_gaussian_q2"
    ]),
    "correlation_block_status"
  )
  expect_error(
    phase18_write_correlation_block_status_outputs(output_dir = output_dir),
    "already exists"
  )
  expect_silent(phase18_write_correlation_block_status_outputs(
    output_dir = output_dir,
    overwrite = TRUE
  ))
})

test_that("Phase 18 correlation-block status writer validates inputs", {
  source_phase18_correlation_block_status()

  expect_error(
    phase18_write_correlation_block_status_outputs(output_dir = ""),
    "output_dir"
  )
  expect_error(
    phase18_write_correlation_block_status_outputs(
      output_dir = tempfile(),
      overwrite = NA
    ),
    "overwrite"
  )
})
