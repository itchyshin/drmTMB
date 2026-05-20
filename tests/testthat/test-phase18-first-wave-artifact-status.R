source_phase18_first_wave_artifact_status <- function(env = parent.frame()) {
  source(
    system.file("sim/R/sim_runner.R", package = "drmTMB", mustWork = TRUE),
    local = env
  )
  source(
    system.file(
      "sim/run/sim_write_first_wave_artifact_status.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
}

test_that("Phase 18 first-wave artifact status writer stages manifests", {
  source_phase18_first_wave_artifact_status()
  output_dir <- tempfile("phase18-first-wave-status-")
  withr::defer(unlink(output_dir, recursive = TRUE))

  first <- data.frame(
    surface = "gaussian_ls_grid",
    artifact = c("aggregate_csv", "failures_csv"),
    path = c("gaussian-aggregate.csv", "gaussian-failures.csv"),
    exists = c(TRUE, TRUE),
    n_row = c(6L, 0L),
    stringsAsFactors = FALSE
  )
  second <- list(
    artifact_manifest = data.frame(
      surface = "student_shape_grid",
      artifact = c("aggregate_csv", "bootstrap_intervals_csv"),
      path = c("student-aggregate.csv", "student-bootstrap.csv"),
      exists = c(TRUE, FALSE),
      n_row = c(8L, NA_integer_),
      stringsAsFactors = FALSE
    )
  )

  out <- phase18_write_first_wave_artifact_status(
    output_dir = output_dir,
    grid_outputs = list(first, second)
  )

  expect_equal(out$surface, "phase18_first_wave_artifact_status")
  expect_true(all(file.exists(unlist(out$paths, use.names = FALSE))))
  expect_equal(nrow(out$manifest), 4L)
  expect_equal(nrow(out$status), 2L)
  expect_equal(
    out$status$n_missing[out$status$surface == "student_shape_grid"],
    1L
  )
  expect_equal(
    out$status$n_empty_csv[out$status$surface == "gaussian_ls_grid"],
    1L
  )
  expect_equal(nrow(utils::read.csv(out$paths$artifact_manifest_csv)), 4L)
  expect_equal(nrow(utils::read.csv(out$paths$artifact_status_csv)), 2L)
  expect_equal(nrow(out$artifact_manifest), length(out$paths))
  expect_true(all(out$artifact_manifest$exists))
  expect_error(
    phase18_write_first_wave_artifact_status(
      output_dir = output_dir,
      grid_outputs = list(first)
    ),
    "already exists"
  )
  expect_silent(phase18_write_first_wave_artifact_status(
    output_dir = output_dir,
    grid_outputs = list(first, second),
    overwrite = TRUE
  ))
})

test_that("Phase 18 first-wave artifact status writer validates inputs", {
  source_phase18_first_wave_artifact_status()

  expect_error(
    phase18_write_first_wave_artifact_status(
      output_dir = "",
      grid_outputs = list(data.frame())
    ),
    "output_dir"
  )
  expect_error(
    phase18_write_first_wave_artifact_status(
      output_dir = tempfile(),
      grid_outputs = list(data.frame()),
      overwrite = NA
    ),
    "overwrite"
  )
  expect_error(
    phase18_write_first_wave_artifact_status(
      output_dir = tempfile(),
      grid_outputs = list()
    ),
    "non-empty list"
  )
  expect_error(
    phase18_write_first_wave_artifact_status(
      output_dir = tempfile(),
      grid_outputs = list(list(not_manifest = TRUE))
    ),
    "artifact manifest"
  )
})
