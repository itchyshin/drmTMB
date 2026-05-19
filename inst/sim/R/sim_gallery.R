phase18_write_count_mu_re_gallery_inputs <- function(
  pilot,
  output_dir,
  overwrite = FALSE
) {
  if (
    !is.character(output_dir) || length(output_dir) != 1L || !nzchar(output_dir)
  ) {
    stop("`output_dir` must be one non-empty path string.", call. = FALSE)
  }
  if (!isTRUE(overwrite) && !identical(overwrite, FALSE)) {
    stop("`overwrite` must be TRUE or FALSE.", call. = FALSE)
  }
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  output_dir <- normalizePath(output_dir, mustWork = TRUE)

  plot_data <- phase18_count_mu_re_plot_data(pilot)
  plot_data$failures <- phase18_gallery_failure_table(plot_data$failures)
  paths <- list(
    aggregate_csv = file.path(output_dir, "count-mu-aggregate.csv"),
    replicate_csv = file.path(output_dir, "count-mu-replicates.csv"),
    coverage_csv = file.path(output_dir, "count-mu-coverage.csv"),
    manifest_csv = file.path(output_dir, "count-mu-manifest.csv"),
    failures_csv = file.path(output_dir, "count-mu-failures.csv")
  )
  phase18_assert_gallery_overwrite(paths, overwrite)

  utils::write.csv(plot_data$aggregate, paths$aggregate_csv, row.names = FALSE)
  utils::write.csv(
    plot_data$replicates,
    paths$replicate_csv,
    row.names = FALSE
  )
  utils::write.csv(plot_data$coverage, paths$coverage_csv, row.names = FALSE)
  utils::write.csv(plot_data$manifest, paths$manifest_csv, row.names = FALSE)
  utils::write.csv(plot_data$failures, paths$failures_csv, row.names = FALSE)

  paths$plot_data <- plot_data
  paths
}

phase18_render_count_mu_re_gallery <- function(
  pilot,
  output_dir,
  output_file = "phase18-count-mu-gallery.html",
  notes = "",
  overwrite = FALSE,
  template = system.file(
    "sim/reports/phase18-count-mu-gallery.Rmd",
    package = "drmTMB",
    mustWork = TRUE
  )
) {
  if (!requireNamespace("rmarkdown", quietly = TRUE)) {
    stop("Rendering the count pilot gallery requires rmarkdown.", call. = FALSE)
  }
  if (!rmarkdown::pandoc_available()) {
    stop("Rendering the count pilot gallery requires Pandoc.", call. = FALSE)
  }
  if (
    !is.character(output_file) ||
      length(output_file) != 1L ||
      !nzchar(output_file)
  ) {
    stop("`output_file` must be one non-empty file name.", call. = FALSE)
  }
  if (!is.character(notes) || length(notes) != 1L) {
    stop("`notes` must be one string.", call. = FALSE)
  }

  if (
    !is.character(output_dir) || length(output_dir) != 1L || !nzchar(output_dir)
  ) {
    stop("`output_dir` must be one non-empty path string.", call. = FALSE)
  }
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  output_dir <- normalizePath(output_dir, mustWork = TRUE)
  output_path <- file.path(output_dir, output_file)
  if (!overwrite && file.exists(output_path)) {
    stop("Gallery output already exists: ", output_path, call. = FALSE)
  }

  inputs <- phase18_write_count_mu_re_gallery_inputs(
    pilot = pilot,
    output_dir = output_dir,
    overwrite = overwrite
  )

  rendered <- rmarkdown::render(
    input = template,
    output_file = output_file,
    output_dir = output_dir,
    intermediates_dir = output_dir,
    quiet = TRUE,
    params = list(
      aggregate_csv = inputs$aggregate_csv,
      replicate_csv = inputs$replicate_csv,
      coverage_csv = inputs$coverage_csv,
      manifest_csv = inputs$manifest_csv,
      failures_csv = inputs$failures_csv,
      notes = notes
    )
  )

  list(
    output_file = rendered,
    inputs = inputs
  )
}

phase18_assert_gallery_overwrite <- function(paths, overwrite) {
  path_values <- unlist(paths, use.names = FALSE)
  existing <- path_values[file.exists(path_values)]
  if (!overwrite && length(existing) > 0L) {
    stop(
      "Gallery input file already exists: ",
      paste(existing, collapse = ", "),
      call. = FALSE
    )
  }
  invisible(paths)
}

phase18_gallery_failure_table <- function(x) {
  if (is.data.frame(x) && ncol(x) > 0L) {
    return(x)
  }
  data.frame(
    cell_id = character(),
    replicate = integer(),
    seed = integer(),
    status = character(),
    severity = character(),
    message = character(),
    skipped = logical(),
    stringsAsFactors = FALSE
  )
}
