test_that("Phase 18 first-wave summary report template is installed", {
  path <- system.file(
    "sim/reports/phase18-first-wave-summary-report.Rmd",
    package = "drmTMB",
    mustWork = TRUE
  )
  lines <- readLines(path, warn = FALSE)
  text <- paste(lines, collapse = "\n")

  expect_true(file.exists(path))
  expect_true(any(grepl("Phase 18 First-Wave Simulation Summary", lines)))
  expect_true(grepl("Aggregate Operating Characteristics", text, fixed = TRUE))
  expect_true(grepl("Interval Diagnostics", text, fixed = TRUE))
  expect_true(grepl("Warning And Error Ledger", text, fixed = TRUE))
  expect_true(grepl("artifact_status_csv", text, fixed = TRUE))
  expect_true(grepl("aggregate_csv", text, fixed = TRUE))
  expect_true(grepl("wald_coverage_csv", text, fixed = TRUE))
  expect_true(grepl("interval_diagnostics_csv", text, fixed = TRUE))
  expect_true(grepl("max_rows", text, fixed = TRUE))
  expect_true(grepl("phase18_select_columns", text, fixed = TRUE))
  expect_true(grepl("phase18_failure_summary", text, fixed = TRUE))
  expect_true(grepl("phase18_bias_overview_data", text, fixed = TRUE))
  expect_true(grepl("phase18_replicate_cloud_gate", text, fixed = TRUE))
  expect_true(grepl("phase18_add_replicate_cloud_gate", text, fixed = TRUE))
  expect_true(grepl("phase18_interval_coverage_summary", text, fixed = TRUE))
  expect_true(grepl("phase18_manifest_summary", text, fixed = TRUE))
  expect_true(grepl("Replicate Cloud Gate", text, fixed = TRUE))
  expect_true(grepl("Aggregate Bias Overview", text, fixed = TRUE))
  expect_true(grepl("Interval Coverage Summary", text, fixed = TRUE))
  expect_true(grepl("Run Manifest Summary", text, fixed = TRUE))
  expect_true(grepl("Warning And Error Summary", text, fixed = TRUE))
  expect_true(grepl("n_event", text, fixed = TRUE))
  expect_true(grepl("source_surface", text, fixed = TRUE))
  expect_true(grepl("Reader Checks", text, fixed = TRUE))
  expect_true(grepl("Interpretation Boundary", text, fixed = TRUE))
})

test_that("Phase 18 first-wave summary report renders bundled tables", {
  skip_if_not_installed("rmarkdown")
  skip_if_not(rmarkdown::pandoc_available())

  path <- system.file(
    "sim/reports/phase18-first-wave-summary-report.Rmd",
    package = "drmTMB",
    mustWork = TRUE
  )
  output_dir <- tempfile("phase18-first-wave-summary-")
  dir.create(output_dir)
  withr::defer(unlink(output_dir, recursive = TRUE))

  artifact_status_csv <- file.path(output_dir, "artifact-status.csv")
  artifact_grain_status_csv <- file.path(
    output_dir,
    "artifact-grain-status.csv"
  )
  aggregate_csv <- file.path(output_dir, "aggregate.csv")
  manifest_csv <- file.path(output_dir, "manifest.csv")
  failures_csv <- file.path(output_dir, "failures.csv")
  wald_coverage_csv <- file.path(output_dir, "wald-coverage.csv")
  interval_diagnostics_csv <- file.path(output_dir, "interval-diagnostics.csv")
  interval_failures_csv <- file.path(output_dir, "interval-failures.csv")
  write.csv(
    data.frame(
      surface = "gaussian_ls_grid",
      n_artifact = 4L,
      n_present = 4L,
      n_missing = 0L,
      n_empty_csv = 1L
    ),
    artifact_status_csv,
    row.names = FALSE
  )
  write.csv(
    data.frame(
      source_surface = "gaussian_ls_grid",
      source_artifact = "aggregate_csv",
      artifact_grain = "aggregate",
      grain_status = "aggregate_only",
      plot_geometry = "aggregate_points_bars_mcse_only",
      replicate_cloud_allowed = FALSE,
      n_row = 1L
    ),
    artifact_grain_status_csv,
    row.names = FALSE
  )
  write.csv(
    data.frame(
      source_surface = "gaussian_ls_grid",
      parameter = "mu:x",
      bias = 0.01,
      rmse = 0.05,
      convergence_rate = 1
    ),
    aggregate_csv,
    row.names = FALSE
  )
  write.csv(
    data.frame(
      source_surface = "gaussian_ls_grid",
      source_artifact = "wald_coverage_csv",
      parameter = "mu:x",
      n_interval = 1L,
      n_covered = 1L,
      coverage = 1
    ),
    wald_coverage_csv,
    row.names = FALSE
  )
  write.csv(
    data.frame(
      source_surface = "gaussian_ls_grid",
      interval_method = "wald",
      interval_status = "ok",
      coverage = 1
    ),
    interval_diagnostics_csv,
    row.names = FALSE
  )
  write.csv(
    data.frame(
      source_surface = character(),
      interval_method = character(),
      interval_status = character()
    ),
    interval_failures_csv,
    row.names = FALSE
  )
  write.csv(
    data.frame(
      source_surface = "gaussian_ls_grid",
      cell_id = "cell_001",
      replicate = 1L,
      status = "ok",
      skipped = FALSE,
      warning_count = 1L,
      error = "",
      elapsed = 0.2
    ),
    manifest_csv,
    row.names = FALSE
  )
  write.csv(
    data.frame(
      source_surface = "gaussian_ls_grid",
      cell_id = "cell_001",
      severity = "warning",
      message = "example warning"
    ),
    failures_csv,
    row.names = FALSE
  )

  out <- rmarkdown::render(
    input = path,
    output_file = "phase18-first-wave-summary.html",
    output_dir = output_dir,
    intermediates_dir = output_dir,
    quiet = TRUE,
    params = list(
      artifact_status_csv = artifact_status_csv,
      artifact_grain_status_csv = artifact_grain_status_csv,
      aggregate_csv = aggregate_csv,
      manifest_csv = manifest_csv,
      failures_csv = failures_csv,
      wald_coverage_csv = wald_coverage_csv,
      interval_diagnostics_csv = interval_diagnostics_csv,
      interval_failures_csv = interval_failures_csv,
      require_complete = TRUE,
      max_rows = 20,
      notes = "summary render smoke"
    )
  )

  expect_true(file.exists(out))
  html <- paste(readLines(out, warn = FALSE), collapse = "\n")
  expect_true(grepl("summary render smoke", html, fixed = TRUE))
  expect_true(grepl("gaussian_ls_grid", html, fixed = TRUE))
  expect_true(grepl("Replicate Cloud Gate", html, fixed = TRUE))
  expect_true(grepl("aggregate_only_no_clouds", html, fixed = TRUE))
  expect_true(grepl("Aggregate Bias Overview", html, fixed = TRUE))
  expect_true(grepl("Interval Coverage Summary", html, fixed = TRUE))
  expect_true(grepl("Interval Diagnostics", html, fixed = TRUE))
  expect_true(grepl("Run Manifest Summary", html, fixed = TRUE))
  expect_true(grepl("Warning And Error Summary", html, fixed = TRUE))
  expect_true(grepl("example warning", html, fixed = TRUE))
})
