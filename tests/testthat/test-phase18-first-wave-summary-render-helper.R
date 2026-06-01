source_phase18_first_wave_summary_render_helper <- function(
  env = parent.frame()
) {
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
  source(
    system.file(
      "sim/run/sim_write_first_wave_table_bundle.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
  source(
    system.file(
      "sim/run/sim_render_first_wave_summary_report.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
}

phase18_fake_first_wave_grid_output <- function(root) {
  table_dir <- file.path(root, "tables")
  dir.create(table_dir, recursive = TRUE)
  paths <- list(
    aggregate_csv = file.path(table_dir, "aggregate.csv"),
    manifest_csv = file.path(table_dir, "manifest.csv"),
    failures_csv = file.path(table_dir, "failures.csv"),
    interval_diagnostics_csv = file.path(table_dir, "interval-diagnostics.csv"),
    interval_failures_csv = file.path(table_dir, "interval-failures.csv")
  )
  write.csv(
    data.frame(
      parameter = "mu:x",
      bias = 0.01,
      rmse = 0.05,
      artifact_grain = "aggregate"
    ),
    paths$aggregate_csv,
    row.names = FALSE
  )
  write.csv(
    data.frame(cell_id = "cell_001", replicate = 1L, status = "ok"),
    paths$manifest_csv,
    row.names = FALSE
  )
  write.csv(
    data.frame(
      cell_id = character(),
      severity = character(),
      message = character()
    ),
    paths$failures_csv,
    row.names = FALSE
  )
  write.csv(
    data.frame(interval_method = "wald", interval_status = "ok", coverage = 1),
    paths$interval_diagnostics_csv,
    row.names = FALSE
  )
  write.csv(
    data.frame(interval_method = character(), interval_status = character()),
    paths$interval_failures_csv,
    row.names = FALSE
  )
  list(
    surface = "gaussian_ls_grid",
    paths = paths,
    artifact_manifest = data.frame(
      surface = "gaussian_ls_grid",
      artifact = names(paths),
      path = unlist(paths, use.names = FALSE),
      exists = file.exists(unlist(paths, use.names = FALSE)),
      n_row = c(1L, 1L, 0L, 1L, 0L),
      stringsAsFactors = FALSE
    )
  )
}

test_that("Phase 18 first-wave summary render helper stages report inputs", {
  source_phase18_first_wave_summary_render_helper()
  root <- tempfile("phase18-first-wave-summary-helper-")
  dir.create(root)
  withr::defer(unlink(root, recursive = TRUE))

  grid_output <- phase18_fake_first_wave_grid_output(file.path(root, "grid"))
  out <- phase18_render_first_wave_summary_report(
    output_dir = file.path(root, "out"),
    grid_outputs = list(grid_output),
    artifacts = c(
      "aggregate_csv",
      "manifest_csv",
      "failures_csv",
      "interval_diagnostics_csv",
      "interval_failures_csv"
    ),
    render = FALSE,
    notes = "staging only"
  )

  expect_equal(out$surface, "phase18_first_wave_summary_report")
  expect_null(out$report_path)
  expect_true(file.exists(out$status$paths$artifact_status_csv))
  expect_true(file.exists(out$tables$paths$aggregate_csv))
  expect_true(file.exists(out$tables$paths$artifact_grain_status_csv))
  expect_equal(nrow(out$tables$tables$aggregate_csv), 1L)
  expect_equal(
    out$tables$tables$aggregate_csv$source_surface,
    "gaussian_ls_grid"
  )
  expect_equal(
    out$tables$grain_status$grain_status[
      out$tables$grain_status$source_artifact == "aggregate_csv"
    ],
    "aggregate_only"
  )
  params <- phase18_first_wave_summary_report_params(
    out$status,
    out$tables,
    require_complete = TRUE,
    notes = "staging only"
  )
  expect_equal(params$artifact_status_csv, out$status$paths$artifact_status_csv)
  expect_equal(
    params$artifact_grain_status_csv,
    out$tables$paths$artifact_grain_status_csv
  )
  expect_equal(params$aggregate_csv, out$tables$paths$aggregate_csv)
  expect_null(phase18_first_wave_optional_path(list(), "aggregate_csv"))
})

test_that("Phase 18 first-wave summary render helper renders HTML", {
  skip_if_not_installed("rmarkdown")
  skip_if_not(rmarkdown::pandoc_available())
  source_phase18_first_wave_summary_render_helper()
  root <- tempfile("phase18-first-wave-summary-render-")
  dir.create(root)
  withr::defer(unlink(root, recursive = TRUE))

  grid_output <- phase18_fake_first_wave_grid_output(file.path(root, "grid"))
  out <- phase18_render_first_wave_summary_report(
    output_dir = file.path(root, "out"),
    grid_outputs = list(grid_output),
    artifacts = c(
      "aggregate_csv",
      "manifest_csv",
      "failures_csv",
      "interval_diagnostics_csv",
      "interval_failures_csv"
    ),
    render = TRUE,
    notes = "helper render smoke"
  )

  expect_true(file.exists(out$report_path))
  html <- paste(readLines(out$report_path, warn = FALSE), collapse = "\n")
  expect_true(grepl("helper render smoke", html, fixed = TRUE))
  expect_error(
    phase18_render_first_wave_summary_report(
      output_dir = file.path(root, "out"),
      grid_outputs = list(grid_output),
      artifacts = "aggregate_csv",
      render = TRUE
    ),
    "already exists"
  )
})

test_that("Phase 18 first-wave summary render helper validates inputs", {
  source_phase18_first_wave_summary_render_helper()

  expect_error(
    phase18_render_first_wave_summary_report(
      output_dir = "",
      grid_outputs = list(list(paths = list()))
    ),
    "output_dir"
  )
  expect_error(
    phase18_render_first_wave_summary_report(
      output_dir = tempfile(),
      grid_outputs = list(list(paths = list())),
      overwrite = NA
    ),
    "overwrite"
  )
  expect_error(
    phase18_render_first_wave_summary_report(
      output_dir = tempfile(),
      grid_outputs = list(list(paths = list())),
      render = NA
    ),
    "render"
  )
  expect_error(
    phase18_render_first_wave_summary_report(
      output_dir = tempfile(),
      grid_outputs = list(list(paths = list())),
      notes = NA_character_
    ),
    "notes"
  )
})
