artifact_file <- commandArgs(FALSE)
artifact_file <- artifact_file[startsWith(artifact_file, "--file=")]
artifact_file <- sub("^--file=", "", artifact_file[[1L]])
artifact_dir <- dirname(normalizePath(artifact_file, mustWork = TRUE))

devtools::load_all(".", quiet = TRUE)
source("inst/sim/R/sim_registry.R")
source("inst/sim/R/sim_utils.R")
source("inst/sim/R/sim_runner.R")
source("inst/sim/R/sim_aggregate.R")
source("inst/sim/R/sim_uncertainty.R")
source("inst/sim/R/sim_bootstrap.R")
source("inst/sim/dgp/sim_dgp_student_shape.R")
source("inst/sim/fit/sim_summarise_student_shape.R")
source("inst/sim/run/sim_run_student_shape_smoke.R")
source("inst/sim/run/sim_summary_student_shape_smoke.R")
source("inst/sim/run/sim_write_student_shape_grid.R")

master_seed <- 20260618L
n_rep <- 25L
conditions <- phase18_student_shape_conditions(
  n = 180L,
  nu_intercept = log(c(0.8, 6)),
  nu_slope = 0,
  sigma_slope = 0.20,
  rho_xw = 0.2
)
conditions$cell_id <- sprintf("student_shape_%03d", seq_len(nrow(conditions)))
conditions$cell_label <- c("low_nu_boundary", "ordinary_nu")
conditions$nu_at_w0 <- 2 + exp(conditions$nu_intercept)

started <- Sys.time()
out <- phase18_write_student_shape_grid_outputs(
  output_dir = artifact_dir,
  conditions = conditions[
    c("n", "nu_intercept", "nu_slope", "sigma_slope", "rho_xw",
      "beta_mu_intercept", "beta_mu_x", "beta_sigma_intercept")
  ],
  n_rep = n_rep,
  master_seed = master_seed,
  overwrite = TRUE,
  cores = 1L
)
elapsed_seconds <- as.numeric(difftime(Sys.time(), started, units = "secs"))

fit_rows <- unique(out$summary$replicates[
  c(
    "cell_id",
    "replicate",
    "converged",
    "pdHess",
    "warning_count",
    "fit_diagnostic_status",
    "student_nu_status",
    "student_nu_value",
    "student_nu_message"
  )
])
fit_rows <- merge(
  conditions[c("cell_id", "cell_label", "nu_at_w0")],
  fit_rows,
  by = "cell_id",
  all.y = TRUE,
  sort = FALSE
)

status_counts <- as.data.frame.matrix(table(
  fit_rows$cell_id,
  fit_rows$student_nu_status
))
status_counts$cell_id <- rownames(status_counts)
rownames(status_counts) <- NULL
for (status in c("error", "note", "ok", "warning")) {
  if (!status %in% names(status_counts)) {
    status_counts[[status]] <- 0L
  }
}

fit_summary <- stats::aggregate(
  cbind(
    converged = as.integer(converged),
    pdHess = as.integer(pdHess),
    warning_rate = as.integer(warning_count > 0),
    mean_warning_count = warning_count
  ) ~ cell_id,
  fit_rows,
  mean
)
fit_summary <- merge(fit_summary, status_counts, by = "cell_id", sort = FALSE)
fit_summary <- merge(
  conditions[c("cell_id", "cell_label", "nu_at_w0")],
  fit_summary,
  by = "cell_id",
  all.x = TRUE,
  sort = FALSE
)
fit_summary$fit_replicates <- as.integer(table(fit_rows$cell_id)[
  fit_summary$cell_id
])
fit_summary$student_nu_warning_rate <- fit_summary$warning /
  fit_summary$fit_replicates
fit_summary$student_nu_error_rate <- fit_summary$error /
  fit_summary$fit_replicates
fit_summary$student_nu_note_rate <- fit_summary$note /
  fit_summary$fit_replicates
fit_summary$student_nu_ok_rate <- fit_summary$ok /
  fit_summary$fit_replicates

run_summary <- data.frame(
  surface = "student_nu_boundary_diagnostic_pilot",
  interpretation_label = "diagnostic_pilot",
  master_seed = master_seed,
  n_conditions = nrow(conditions),
  n_rep = n_rep,
  fit_attempts = nrow(fit_rows),
  elapsed_seconds = elapsed_seconds,
  min_convergence_rate = min(fit_summary$converged),
  min_pdHess_rate = min(fit_summary$pdHess),
  max_student_nu_warning_rate = max(fit_summary$student_nu_warning_rate),
  max_student_nu_error_rate = max(fit_summary$student_nu_error_rate),
  max_warning_rate = max(fit_summary$warning_rate),
  stringsAsFactors = FALSE
)

utils::write.csv(
  conditions,
  file.path(artifact_dir, "tables", "student-nu-conditions.csv"),
  row.names = FALSE
)
utils::write.csv(
  fit_rows,
  file.path(artifact_dir, "tables", "student-nu-fit-status.csv"),
  row.names = FALSE
)
utils::write.csv(
  fit_summary,
  file.path(artifact_dir, "tables", "student-nu-status-summary.csv"),
  row.names = FALSE
)
utils::write.csv(
  out$summary$aggregate,
  file.path(artifact_dir, "tables", "student-nu-parameter-aggregate.csv"),
  row.names = FALSE
)
utils::write.csv(
  run_summary,
  file.path(artifact_dir, "student-nu-boundary-run-summary.csv"),
  row.names = FALSE
)
writeLines(capture.output(sessionInfo()), file.path(artifact_dir, "session-info.txt"))
unlink(file.path(artifact_dir, "results"), recursive = TRUE)

print(run_summary)
print(fit_summary)
