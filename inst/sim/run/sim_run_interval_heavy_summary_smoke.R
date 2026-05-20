phase18_run_interval_heavy_summary_smoke <- function(
  output_dir,
  n_rep = 1L,
  master_seed = 20260531L,
  cores = 1L,
  backend = "none",
  overwrite = FALSE,
  render = TRUE,
  require_complete = TRUE,
  profile_parameters = character(),
  profile_level = 0.70,
  profile_args = list(ystep = 0.50),
  bootstrap_nsim = 0L,
  bootstrap_level = 0.70,
  bootstrap_cores = 1L,
  bootstrap_backend = "none",
  notes = NULL
) {
  phase18_assert_interval_heavy_summary_smoke_inputs(
    output_dir = output_dir,
    n_rep = n_rep,
    master_seed = master_seed,
    notes = notes
  )
  if (is.null(notes)) {
    notes <- paste0(
      "Phase 18 interval-heavy summary smoke with n_rep = ",
      as.integer(n_rep),
      "."
    )
  }

  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  output_dir <- normalizePath(output_dir, mustWork = TRUE)

  student <- phase18_write_student_shape_grid_outputs(
    output_dir = file.path(output_dir, "student-shape"),
    conditions = phase18_student_shape_conditions(
      n = 240L,
      nu_intercept = log(6),
      nu_slope = 0.20,
      sigma_slope = 0.20,
      rho_xw = 0.1
    ),
    n_rep = as.integer(n_rep),
    master_seed = as.integer(master_seed) + 1L,
    overwrite = overwrite,
    profile_parameters = profile_parameters,
    profile_level = profile_level,
    profile_args = profile_args,
    bootstrap_nsim = bootstrap_nsim,
    bootstrap_level = bootstrap_level,
    bootstrap_cores = bootstrap_cores,
    bootstrap_backend = bootstrap_backend,
    cores = cores,
    backend = backend
  )
  biv_rho12 <- phase18_write_biv_rho12_grid_outputs(
    output_dir = file.path(output_dir, "biv-rho12"),
    conditions = phase18_biv_rho12_conditions(
      n = 180L,
      delta0 = atanh(0.20),
      delta1 = 0.20,
      sigma_ratio = 1.1,
      rho_xw = 0.1
    ),
    n_rep = as.integer(n_rep),
    master_seed = as.integer(master_seed) + 2L,
    overwrite = overwrite,
    profile_parameters = profile_parameters,
    profile_level = profile_level,
    profile_args = profile_args,
    bootstrap_nsim = bootstrap_nsim,
    bootstrap_level = bootstrap_level,
    bootstrap_cores = bootstrap_cores,
    bootstrap_backend = bootstrap_backend,
    cores = cores,
    backend = backend
  )

  report <- phase18_render_first_wave_summary_report(
    output_dir = file.path(output_dir, "interval-heavy-summary"),
    grid_outputs = list(student, biv_rho12),
    overwrite = overwrite,
    render = render,
    require_complete = require_complete,
    notes = notes
  )
  parallel_summary <- phase18_interval_heavy_parallel_summary(
    student = student,
    biv_rho12 = biv_rho12
  )
  paths <- list(
    parallel_summary_csv = file.path(
      output_dir,
      "interval-heavy-parallel-summary.csv"
    )
  )
  utils::write.csv(
    parallel_summary,
    paths$parallel_summary_csv,
    row.names = FALSE
  )

  list(
    surface = "phase18_interval_heavy_summary_smoke",
    output_dir = output_dir,
    paths = paths,
    student = student,
    biv_rho12 = biv_rho12,
    report = report,
    parallel_summary = parallel_summary
  )
}

phase18_assert_interval_heavy_summary_smoke_inputs <- function(
  output_dir,
  n_rep,
  master_seed,
  notes
) {
  if (
    !is.character(output_dir) || length(output_dir) != 1L || !nzchar(output_dir)
  ) {
    stop("`output_dir` must be one non-empty path string.", call. = FALSE)
  }
  if (
    !is.numeric(n_rep) ||
      length(n_rep) != 1L ||
      !is.finite(n_rep) ||
      n_rep < 1L ||
      n_rep != as.integer(n_rep)
  ) {
    stop("`n_rep` must be one positive integer.", call. = FALSE)
  }
  if (
    !is.numeric(master_seed) ||
      length(master_seed) != 1L ||
      !is.finite(master_seed) ||
      master_seed != as.integer(master_seed)
  ) {
    stop("`master_seed` must be one integer.", call. = FALSE)
  }
  if (
    !is.null(notes) &&
      (!is.character(notes) || length(notes) != 1L || is.na(notes))
  ) {
    stop("`notes` must be NULL or one character string.", call. = FALSE)
  }
  invisible(TRUE)
}

phase18_interval_heavy_parallel_summary <- function(student, biv_rho12) {
  out <- do.call(
    rbind,
    list(
      phase18_interval_heavy_parallel_summary_row(
        "student_shape_grid",
        student$summary$run$parallel
      ),
      phase18_interval_heavy_parallel_summary_row(
        "biv_rho12_grid",
        biv_rho12$summary$run$parallel
      )
    )
  )
  row.names(out) <- NULL
  out
}

phase18_interval_heavy_parallel_summary_row <- function(surface, parallel) {
  data.frame(
    surface = surface,
    backend = parallel$backend,
    requested_cores = parallel$requested_cores,
    cores = parallel$cores,
    stringsAsFactors = FALSE
  )
}
