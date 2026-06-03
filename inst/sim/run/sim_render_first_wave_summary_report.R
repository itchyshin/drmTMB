phase18_render_first_wave_summary_report <- function(
  output_dir,
  grid_outputs,
  artifacts = phase18_first_wave_table_artifacts(),
  overwrite = FALSE,
  render = TRUE,
  require_complete = FALSE,
  notes = ""
) {
  if (
    !is.character(output_dir) || length(output_dir) != 1L || !nzchar(output_dir)
  ) {
    stop("`output_dir` must be one non-empty path string.", call. = FALSE)
  }
  if (!isTRUE(overwrite) && !identical(overwrite, FALSE)) {
    stop("`overwrite` must be TRUE or FALSE.", call. = FALSE)
  }
  if (!isTRUE(render) && !identical(render, FALSE)) {
    stop("`render` must be TRUE or FALSE.", call. = FALSE)
  }
  if (!isTRUE(require_complete) && !identical(require_complete, FALSE)) {
    stop("`require_complete` must be TRUE or FALSE.", call. = FALSE)
  }
  if (!is.character(notes) || length(notes) != 1L || is.na(notes)) {
    stop("`notes` must be one character string.", call. = FALSE)
  }

  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  output_dir <- normalizePath(output_dir, mustWork = TRUE)
  status_dir <- file.path(output_dir, "status")
  table_dir <- file.path(output_dir, "tables")
  report_dir <- file.path(output_dir, "report")
  report_path <- file.path(report_dir, "phase18-first-wave-summary.html")
  if (render && file.exists(report_path) && !overwrite) {
    stop(
      "Phase 18 first-wave summary report already exists: ",
      report_path,
      call. = FALSE
    )
  }

  status <- phase18_write_first_wave_artifact_status(
    output_dir = status_dir,
    grid_outputs = grid_outputs,
    overwrite = overwrite
  )
  tables <- phase18_write_first_wave_table_bundle(
    output_dir = table_dir,
    grid_outputs = grid_outputs,
    artifacts = artifacts,
    overwrite = overwrite
  )

  rendered <- NULL
  if (render) {
    if (!requireNamespace("rmarkdown", quietly = TRUE)) {
      stop(
        "Package `rmarkdown` is required to render the report.",
        call. = FALSE
      )
    }
    if (!rmarkdown::pandoc_available()) {
      stop("Pandoc is required to render the report.", call. = FALSE)
    }
    dir.create(report_dir, recursive = TRUE, showWarnings = FALSE)
    template <- system.file(
      "sim/reports/phase18-first-wave-summary-report.Rmd",
      package = "drmTMB",
      mustWork = TRUE
    )
    rendered <- rmarkdown::render(
      input = template,
      output_file = basename(report_path),
      output_dir = report_dir,
      intermediates_dir = report_dir,
      quiet = TRUE,
      params = phase18_first_wave_summary_report_params(
        status = status,
        tables = tables,
        require_complete = require_complete,
        notes = notes
      )
    )
  }

  list(
    surface = "phase18_first_wave_summary_report",
    output_dir = output_dir,
    status = status,
    tables = tables,
    report_path = rendered
  )
}

phase18_first_wave_summary_report_params <- function(
  status,
  tables,
  require_complete,
  notes
) {
  paths <- tables$paths
  list(
    artifact_status_csv = status$paths$artifact_status_csv,
    artifact_grain_status_csv = phase18_first_wave_optional_path(
      paths,
      "artifact_grain_status_csv"
    ),
    aggregate_csv = phase18_first_wave_optional_path(paths, "aggregate_csv"),
    manifest_csv = phase18_first_wave_optional_path(paths, "manifest_csv"),
    failures_csv = phase18_first_wave_optional_path(paths, "failures_csv"),
    wald_coverage_csv = phase18_first_wave_optional_path(
      paths,
      "wald_coverage_csv"
    ),
    profile_coverage_csv = phase18_first_wave_optional_path(
      paths,
      "profile_coverage_csv"
    ),
    bootstrap_coverage_csv = phase18_first_wave_optional_path(
      paths,
      "bootstrap_coverage_csv"
    ),
    interval_diagnostics_csv = phase18_first_wave_optional_path(
      paths,
      "interval_diagnostics_csv"
    ),
    interval_failures_csv = phase18_first_wave_optional_path(
      paths,
      "interval_failures_csv"
    ),
    require_complete = require_complete,
    notes = notes
  )
}

phase18_first_wave_optional_path <- function(paths, name) {
  if (is.list(paths) && name %in% names(paths)) {
    return(paths[[name]])
  }
  NULL
}
