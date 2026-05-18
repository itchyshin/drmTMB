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
