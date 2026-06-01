test_that("Phase 18 count gallery template is installed and reader-facing", {
  path <- system.file(
    "sim/reports/phase18-count-mu-gallery.Rmd",
    package = "drmTMB",
    mustWork = TRUE
  )
  lines <- readLines(path, warn = FALSE)
  text <- paste(lines, collapse = "\n")

  expect_true(file.exists(path))
  expect_true(any(grepl("Phase 18 Count Pilot Figure Gallery", lines)))
  expect_true(grepl("not a final simulation report", text, fixed = TRUE))
  expect_true(grepl("Bias", text, fixed = TRUE))
  expect_true(grepl("RMSE", text, fixed = TRUE))
  expect_true(grepl("Interval Coverage", text, fixed = TRUE))
  expect_true(grepl("Florence Checks", text, fixed = TRUE))
  expect_true(grepl("No warning/error ledger CSV supplied", text, fixed = TRUE))
  expect_true(grepl("phase18_count_gallery_theme", text, fixed = TRUE))
  expect_true(grepl("phase18_plot_count_bias", text, fixed = TRUE))
  expect_true(grepl("replicate_csv", text, fixed = TRUE))
  expect_true(grepl("artifact_grain", text, fixed = TRUE))
  expect_true(grepl(
    'as.character(data$artifact_grain) == "replicate"',
    text,
    fixed = TRUE
  ))
  expect_true(grepl("replicate-level errors", text, fixed = TRUE))
  expect_true(grepl("phase18_plot_count_rmse", text, fixed = TRUE))
  expect_true(grepl("Monte Carlo uncertainty", text, fixed = TRUE))
  expect_true(grepl("bias_mcse", text, fixed = TRUE))
  expect_true(grepl("rmse_mcse", text, fixed = TRUE))
  expect_true(grepl(
    "RMSE needs its own uncertainty display",
    text,
    fixed = TRUE
  ))
})

test_that("Phase 18 count gallery template renders with CSV inputs", {
  skip_if_not_installed("rmarkdown")
  skip_if_not(rmarkdown::pandoc_available())

  path <- system.file(
    "sim/reports/phase18-count-mu-gallery.Rmd",
    package = "drmTMB",
    mustWork = TRUE
  )
  output_dir <- tempfile("phase18-count-gallery-")
  dir.create(output_dir)
  withr::defer(unlink(output_dir, recursive = TRUE))

  aggregate_csv <- file.path(output_dir, "aggregate.csv")
  replicate_csv <- file.path(output_dir, "replicates.csv")
  coverage_csv <- file.path(output_dir, "coverage.csv")
  manifest_csv <- file.path(output_dir, "manifest.csv")
  failures_csv <- file.path(output_dir, "failures.csv")
  write.csv(
    data.frame(
      family = c("Poisson", "NB2"),
      parameter_class = c("fixed_effect", "random_sd"),
      dpar = c("mu", "mu"),
      term = c("x", "(1 | id)"),
      replicate = c(1L, 1L),
      error = c(0.01, -0.02),
      artifact_grain = "replicate"
    ),
    replicate_csv,
    row.names = FALSE
  )
  write.csv(
    data.frame(
      family = c("Poisson", "NB2"),
      parameter_class = c("fixed_effect", "random_sd"),
      dpar = c("mu", "mu"),
      term = c("x", "(1 | id)"),
      bias = c(0.01, -0.02),
      rmse = c(0.04, 0.08),
      bias_mcse = c(0.005, 0.006),
      rmse_mcse = c(0.004, 0.007)
    ),
    aggregate_csv,
    row.names = FALSE
  )
  write.csv(
    data.frame(
      family = c("Poisson", "NB2"),
      interval_method = c("wald", "profile"),
      dpar = c("mu", "mu"),
      term = c("x", "(1 | id)"),
      coverage = c(1, 1)
    ),
    coverage_csv,
    row.names = FALSE
  )
  write.csv(
    data.frame(cell_id = "cell_001", replicate = 1L, status = "ok"),
    manifest_csv,
    row.names = FALSE
  )
  write.csv(
    data.frame(
      cell_id = character(),
      severity = character(),
      message = character()
    ),
    failures_csv,
    row.names = FALSE
  )

  out <- rmarkdown::render(
    input = path,
    output_file = "phase18-count-gallery.html",
    output_dir = output_dir,
    intermediates_dir = output_dir,
    quiet = TRUE,
    params = list(
      aggregate_csv = aggregate_csv,
      replicate_csv = replicate_csv,
      coverage_csv = coverage_csv,
      manifest_csv = manifest_csv,
      failures_csv = failures_csv,
      notes = "render smoke"
    )
  )

  expect_true(file.exists(out))
  html <- paste(readLines(out, warn = FALSE), collapse = "\n")
  expect_true(grepl("render smoke", html, fixed = TRUE))
  expect_true(grepl("Florence Checks", html, fixed = TRUE))
})

test_that("Phase 18 count gallery does not fake clouds from aggregate grain", {
  skip_if_not_installed("rmarkdown")
  skip_if_not(rmarkdown::pandoc_available())

  path <- system.file(
    "sim/reports/phase18-count-mu-gallery.Rmd",
    package = "drmTMB",
    mustWork = TRUE
  )
  output_dir <- tempfile("phase18-count-gallery-no-cloud-")
  dir.create(output_dir)
  withr::defer(unlink(output_dir, recursive = TRUE))

  aggregate_csv <- file.path(output_dir, "aggregate.csv")
  replicate_csv <- file.path(output_dir, "replicates.csv")
  coverage_csv <- file.path(output_dir, "coverage.csv")
  manifest_csv <- file.path(output_dir, "manifest.csv")
  failures_csv <- file.path(output_dir, "failures.csv")
  write.csv(
    data.frame(
      family = "Poisson",
      parameter_class = "fixed_effect",
      dpar = "mu",
      term = "x",
      replicate = 1L,
      error = 0.01,
      artifact_grain = "aggregate"
    ),
    replicate_csv,
    row.names = FALSE
  )
  write.csv(
    data.frame(
      family = "Poisson",
      parameter_class = "fixed_effect",
      dpar = "mu",
      term = "x",
      bias = 0.01,
      rmse = 0.04,
      bias_mcse = 0.005,
      rmse_mcse = 0.004
    ),
    aggregate_csv,
    row.names = FALSE
  )
  write.csv(
    data.frame(
      family = "Poisson",
      interval_method = "wald",
      dpar = "mu",
      term = "x",
      coverage = 1
    ),
    coverage_csv,
    row.names = FALSE
  )
  write.csv(
    data.frame(cell_id = "cell_001", replicate = 1L, status = "ok"),
    manifest_csv,
    row.names = FALSE
  )
  write.csv(
    data.frame(
      cell_id = character(),
      severity = character(),
      message = character()
    ),
    failures_csv,
    row.names = FALSE
  )

  out <- rmarkdown::render(
    input = path,
    output_file = "phase18-count-gallery-no-cloud.html",
    output_dir = output_dir,
    intermediates_dir = output_dir,
    quiet = TRUE,
    params = list(
      aggregate_csv = aggregate_csv,
      replicate_csv = replicate_csv,
      coverage_csv = coverage_csv,
      manifest_csv = manifest_csv,
      failures_csv = failures_csv,
      notes = "aggregate grain smoke"
    )
  )

  expect_true(file.exists(out))
  html <- paste(readLines(out, warn = FALSE), collapse = "\n")
  expect_true(grepl("aggregate grain smoke", html, fixed = TRUE))
})
