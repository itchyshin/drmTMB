source_phase18_first_wave_table_bundle <- function(env = parent.frame()) {
  source(
    system.file("sim/R/sim_runner.R", package = "drmTMB", mustWork = TRUE),
    local = env
  )
  source(
    system.file(
      "sim/run/sim_write_first_wave_table_bundle.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
}

test_that("Phase 18 first-wave table bundle collects grid artifact tables", {
  source_phase18_first_wave_table_bundle()
  root <- tempfile("phase18-first-wave-tables-")
  dir.create(root)
  withr::defer(unlink(root, recursive = TRUE))

  first_aggregate <- file.path(root, "first-aggregate.csv")
  second_aggregate <- file.path(root, "second-aggregate.csv")
  first_failures <- file.path(root, "first-failures.csv")
  write.csv(
    data.frame(parameter = "mu:x", bias = 0.02),
    first_aggregate,
    row.names = FALSE
  )
  write.csv(
    data.frame(parameter = "sigma:z", rmse = 0.11),
    second_aggregate,
    row.names = FALSE
  )
  write.csv(
    data.frame(
      cell_id = character(),
      severity = character(),
      message = character()
    ),
    first_failures,
    row.names = FALSE
  )
  grid_outputs <- list(
    list(
      surface = "gaussian_ls_grid",
      paths = list(
        aggregate_csv = first_aggregate,
        failures_csv = first_failures
      )
    ),
    list(
      surface = "student_shape_grid",
      paths = list(aggregate_csv = second_aggregate)
    )
  )

  out <- phase18_write_first_wave_table_bundle(
    output_dir = file.path(root, "bundle"),
    grid_outputs = grid_outputs,
    artifacts = c("aggregate_csv", "failures_csv", "wald_coverage_csv")
  )

  aggregate <- out$tables$aggregate_csv
  failures <- out$tables$failures_csv
  missing <- out$tables$wald_coverage_csv

  expect_equal(out$surface, "phase18_first_wave_table_bundle")
  expect_equal(nrow(aggregate), 2L)
  expect_equal(
    aggregate$source_surface,
    c("gaussian_ls_grid", "student_shape_grid")
  )
  expect_equal(aggregate$source_artifact, rep("aggregate_csv", 2L))
  expect_equal(
    names(aggregate)[seq_len(2L)],
    c("source_surface", "source_artifact")
  )
  expect_true("bias" %in% names(aggregate))
  expect_true("rmse" %in% names(aggregate))
  expect_true(is.na(aggregate$rmse[[1L]]))
  expect_true(is.na(aggregate$bias[[2L]]))
  expect_equal(nrow(failures), 0L)
  expect_equal(names(failures), c("source_surface", "source_artifact"))
  expect_equal(nrow(missing), 0L)
  expect_true(all(file.exists(unlist(out$paths, use.names = FALSE))))
  expect_equal(nrow(out$artifact_manifest), length(out$paths))
  expect_error(
    phase18_write_first_wave_table_bundle(
      output_dir = file.path(root, "bundle"),
      grid_outputs = grid_outputs,
      artifacts = "aggregate_csv"
    ),
    "already exists"
  )
  expect_silent(phase18_write_first_wave_table_bundle(
    output_dir = file.path(root, "bundle"),
    grid_outputs = grid_outputs,
    artifacts = "aggregate_csv",
    overwrite = TRUE
  ))
})

test_that("Phase 18 first-wave table bundle validates inputs", {
  source_phase18_first_wave_table_bundle()

  expect_error(
    phase18_write_first_wave_table_bundle(
      output_dir = "",
      grid_outputs = list(list(paths = list()))
    ),
    "output_dir"
  )
  expect_error(
    phase18_write_first_wave_table_bundle(
      output_dir = tempfile(),
      grid_outputs = list(list(paths = list())),
      overwrite = NA
    ),
    "overwrite"
  )
  expect_error(
    phase18_write_first_wave_table_bundle(
      output_dir = tempfile(),
      grid_outputs = list()
    ),
    "grid_outputs"
  )
  expect_error(
    phase18_write_first_wave_table_bundle(
      output_dir = tempfile(),
      grid_outputs = list(list(paths = list())),
      artifacts = character()
    ),
    "artifacts"
  )
  expect_error(
    phase18_collect_first_wave_table(
      grid_outputs = list(list(not_paths = TRUE)),
      artifact = "aggregate_csv"
    ),
    "paths"
  )
})
