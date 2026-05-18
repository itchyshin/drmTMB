test_that("Phase 18 smoke report template is installed and reader-facing", {
  path <- system.file(
    "sim/reports/phase18-smoke-report-template.Rmd",
    package = "drmTMB",
    mustWork = TRUE
  )
  lines <- readLines(path, warn = FALSE)
  text <- paste(lines, collapse = "\n")

  expect_true(file.exists(path))
  expect_true(any(grepl("Phase 18 Smoke Simulation Report", lines)))
  expect_true(grepl(
    "not a comprehensive simulation report",
    text,
    fixed = TRUE
  ))
  expect_true(grepl("Aggregate Summary", text, fixed = TRUE))
  expect_true(grepl("manifest_csv", text, fixed = TRUE))
  expect_true(grepl("failures_csv", text, fixed = TRUE))
  expect_true(grepl("Run Manifest", text, fixed = TRUE))
  expect_true(grepl("Warning And Error Ledger", text, fixed = TRUE))
  expect_true(grepl(
    "No warning/error ledger CSV supplied",
    text,
    fixed = TRUE
  ))
  expect_true(grepl("Reader Checks", text, fixed = TRUE))
  expect_true(grepl("Interpretation Boundary", text, fixed = TRUE))
})

test_that("Phase 18 smoke report template renders with CSV inputs", {
  skip_if_not_installed("rmarkdown")
  skip_if_not(rmarkdown::pandoc_available())

  path <- system.file(
    "sim/reports/phase18-smoke-report-template.Rmd",
    package = "drmTMB",
    mustWork = TRUE
  )
  output_dir <- tempfile("phase18-report-render-")
  dir.create(output_dir)
  withr::defer(unlink(output_dir, recursive = TRUE))

  aggregate_csv <- file.path(output_dir, "aggregate.csv")
  manifest_csv <- file.path(output_dir, "manifest.csv")
  failures_csv <- file.path(output_dir, "failures.csv")
  write.csv(
    data.frame(parameter = "mu:x", bias = 0.01, rmse = 0.05),
    aggregate_csv,
    row.names = FALSE
  )
  write.csv(
    data.frame(cell_id = "cell_001", replicate = 1L, status = "ok"),
    manifest_csv,
    row.names = FALSE
  )
  write.csv(
    data.frame(cell_id = "cell_001", severity = "warning", message = "note"),
    failures_csv,
    row.names = FALSE
  )

  out <- rmarkdown::render(
    input = path,
    output_file = "phase18-smoke-report.html",
    output_dir = output_dir,
    intermediates_dir = output_dir,
    quiet = TRUE,
    params = list(
      surface = "toy_surface",
      aggregate_csv = aggregate_csv,
      manifest_csv = manifest_csv,
      failures_csv = failures_csv,
      notes = "render smoke"
    )
  )

  expect_true(file.exists(out))
  html <- paste(readLines(out, warn = FALSE), collapse = "\n")
  expect_true(grepl("toy_surface", html, fixed = TRUE))
  expect_true(grepl("warning", html, fixed = TRUE))
})
