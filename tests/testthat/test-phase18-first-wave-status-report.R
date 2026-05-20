test_that("Phase 18 first-wave status report template is installed", {
  path <- system.file(
    "sim/reports/phase18-first-wave-status-report.Rmd",
    package = "drmTMB",
    mustWork = TRUE
  )
  lines <- readLines(path, warn = FALSE)
  text <- paste(lines, collapse = "\n")

  expect_true(file.exists(path))
  expect_true(any(grepl("Phase 18 First-Wave Artifact Status", lines)))
  expect_true(grepl("artifact preflight", text, fixed = TRUE))
  expect_true(grepl("artifact_manifest_csv", text, fixed = TRUE))
  expect_true(grepl("artifact_status_csv", text, fixed = TRUE))
  expect_true(grepl("require_complete", text, fixed = TRUE))
  expect_true(grepl("Surface Status", text, fixed = TRUE))
  expect_true(grepl("Missing Or Empty Artifacts", text, fixed = TRUE))
  expect_true(grepl("Reader Checks", text, fixed = TRUE))
  expect_true(grepl("Interpretation Boundary", text, fixed = TRUE))
})

test_that("Phase 18 first-wave status report renders complete artifacts", {
  skip_if_not_installed("rmarkdown")
  skip_if_not(rmarkdown::pandoc_available())

  path <- system.file(
    "sim/reports/phase18-first-wave-status-report.Rmd",
    package = "drmTMB",
    mustWork = TRUE
  )
  output_dir <- tempfile("phase18-first-wave-status-report-")
  dir.create(output_dir)
  withr::defer(unlink(output_dir, recursive = TRUE))

  artifact_manifest_csv <- file.path(output_dir, "artifact-manifest.csv")
  artifact_status_csv <- file.path(output_dir, "artifact-status.csv")
  write.csv(
    data.frame(
      surface = c("gaussian_ls_grid", "student_shape_grid"),
      artifact = c("aggregate_csv", "failures_csv"),
      path = c("gaussian-aggregate.csv", "student-failures.csv"),
      exists = c(TRUE, TRUE),
      n_row = c(6L, 0L)
    ),
    artifact_manifest_csv,
    row.names = FALSE
  )
  write.csv(
    data.frame(
      surface = c("gaussian_ls_grid", "student_shape_grid"),
      n_artifact = c(1L, 1L),
      n_present = c(1L, 1L),
      n_missing = c(0L, 0L),
      n_empty_csv = c(0L, 1L),
      n_total_csv_rows = c(6L, 0L),
      artifact_grain = "grid_artifact_status"
    ),
    artifact_status_csv,
    row.names = FALSE
  )

  out <- rmarkdown::render(
    input = path,
    output_file = "phase18-first-wave-status.html",
    output_dir = output_dir,
    intermediates_dir = output_dir,
    quiet = TRUE,
    params = list(
      artifact_manifest_csv = artifact_manifest_csv,
      artifact_status_csv = artifact_status_csv,
      require_complete = TRUE,
      notes = "status render smoke"
    )
  )

  expect_true(file.exists(out))
  html <- paste(readLines(out, warn = FALSE), collapse = "\n")
  expect_true(grepl("status render smoke", html, fixed = TRUE))
  expect_true(grepl("gaussian_ls_grid", html, fixed = TRUE))
})

test_that("Phase 18 first-wave status report stops on missing artifacts", {
  skip_if_not_installed("rmarkdown")
  skip_if_not(rmarkdown::pandoc_available())

  path <- system.file(
    "sim/reports/phase18-first-wave-status-report.Rmd",
    package = "drmTMB",
    mustWork = TRUE
  )
  output_dir <- tempfile("phase18-first-wave-status-fail-")
  dir.create(output_dir)
  withr::defer(unlink(output_dir, recursive = TRUE))

  artifact_manifest_csv <- file.path(output_dir, "artifact-manifest.csv")
  artifact_status_csv <- file.path(output_dir, "artifact-status.csv")
  write.csv(
    data.frame(
      surface = "student_shape_grid",
      artifact = "bootstrap_intervals_csv",
      path = "student-bootstrap.csv",
      exists = FALSE,
      n_row = NA_integer_
    ),
    artifact_manifest_csv,
    row.names = FALSE
  )
  write.csv(
    data.frame(
      surface = "student_shape_grid",
      n_artifact = 1L,
      n_present = 0L,
      n_missing = 1L,
      n_empty_csv = 0L,
      n_total_csv_rows = 0L
    ),
    artifact_status_csv,
    row.names = FALSE
  )

  expect_error(
    rmarkdown::render(
      input = path,
      output_file = "phase18-first-wave-status.html",
      output_dir = output_dir,
      intermediates_dir = output_dir,
      quiet = TRUE,
      params = list(
        artifact_manifest_csv = artifact_manifest_csv,
        artifact_status_csv = artifact_status_csv,
        require_complete = TRUE,
        notes = ""
      )
    ),
    "missing artifacts for: student_shape_grid"
  )
})
