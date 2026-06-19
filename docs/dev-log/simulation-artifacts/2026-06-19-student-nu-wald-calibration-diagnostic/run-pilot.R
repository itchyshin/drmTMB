args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg)) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath(
    "docs/dev-log/simulation-artifacts/2026-06-19-student-nu-wald-calibration-diagnostic/run-pilot.R",
    mustWork = TRUE
  )
}

artifact_dir <- dirname(script_path)
repo_root <- normalizePath(
  file.path(artifact_dir, "../../../.."),
  mustWork = TRUE
)
tables_dir <- file.path(artifact_dir, "tables")
dir.create(tables_dir, recursive = TRUE, showWarnings = FALSE)

suppressPackageStartupMessages(devtools::load_all(repo_root, quiet = TRUE))
source(file.path(repo_root, "inst/sim/R/sim_registry.R"))
source(file.path(repo_root, "inst/sim/R/sim_utils.R"))
source(file.path(repo_root, "inst/sim/R/sim_runner.R"))
source(file.path(repo_root, "inst/sim/R/sim_aggregate.R"))
source(file.path(repo_root, "inst/sim/R/sim_uncertainty.R"))
source(file.path(repo_root, "inst/sim/R/sim_bootstrap.R"))
source(file.path(repo_root, "inst/sim/dgp/sim_dgp_student_shape.R"))
source(file.path(repo_root, "inst/sim/fit/sim_summarise_student_shape.R"))
source(file.path(repo_root, "inst/sim/run/sim_run_student_shape_smoke.R"))
source(file.path(repo_root, "inst/sim/run/sim_summary_student_shape_smoke.R"))
source(file.path(repo_root, "inst/sim/run/sim_write_student_shape_grid.R"))

master_seed <- 20260619L
n_rep <- 100L

git_lines <- function(...) {
  tryCatch(
    system2("git", c("-C", repo_root, ...), stdout = TRUE, stderr = TRUE),
    warning = function(w) NA_character_,
    error = function(e) NA_character_
  )
}

git_value <- function(...) {
  out <- git_lines(...)
  if (!length(out) || all(is.na(out))) {
    return(NA_character_)
  }
  out[[1L]]
}

md_table <- function(data, columns, names = columns, digits = 3L) {
  if (!nrow(data)) {
    return("_No rows._")
  }
  values <- data[columns]
  for (col in names(values)) {
    if (is.integer(values[[col]])) {
      values[[col]] <- ifelse(
        is.na(values[[col]]),
        "",
        as.character(values[[col]])
      )
    } else if (is.numeric(values[[col]])) {
      values[[col]] <- ifelse(
        is.na(values[[col]]),
        "",
        formatC(values[[col]], format = "f", digits = digits)
      )
    } else {
      values[[col]] <- ifelse(
        is.na(values[[col]]),
        "",
        as.character(values[[col]])
      )
    }
  }
  names(values) <- names
  lines <- c(
    paste0("| ", paste(names(values), collapse = " | "), " |"),
    paste0("| ", paste(rep("---", ncol(values)), collapse = " | "), " |")
  )
  body <- apply(values, 1L, function(row) {
    paste0("| ", paste(row, collapse = " | "), " |")
  })
  paste(c(lines, body), collapse = "\n")
}

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
    c(
      "n",
      "nu_intercept",
      "nu_slope",
      "sigma_slope",
      "rho_xw",
      "beta_mu_intercept",
      "beta_mu_x",
      "beta_sigma_intercept"
    )
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
    convergence_rate = as.integer(converged),
    pdHess_rate = as.integer(pdHess),
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

wald_focus <- out$summary$interval_diagnostics
wald_focus <- wald_focus[wald_focus$interval_method == "wald", , drop = FALSE]
wald_focus <- merge(
  conditions[c("cell_id", "cell_label", "nu_at_w0")],
  wald_focus,
  by = "cell_id",
  all.y = TRUE,
  sort = FALSE
)
wald_focus$interval_missing_rate <- 1 - wald_focus$interval_success_rate
wald_focus$coverage_gap_from_0_95 <- wald_focus$coverage - 0.95

nu_wald_focus <- wald_focus[
  wald_focus$parameter %in%
    c(
      "nu:(Intercept)",
      "nu:w"
    ),
  ,
  drop = FALSE
]

run_summary <- data.frame(
  surface = "student_nu_wald_calibration_diagnostic",
  interpretation_label = "diagnostic_calibration_pilot",
  master_seed = master_seed,
  git_sha = git_value("rev-parse", "HEAD"),
  n_conditions = nrow(conditions),
  n_rep = n_rep,
  fit_attempts = nrow(fit_rows),
  elapsed_seconds = elapsed_seconds,
  min_convergence_rate = min(fit_summary$convergence_rate),
  min_pdHess_rate = min(fit_summary$pdHess_rate),
  max_student_nu_warning_rate = max(fit_summary$student_nu_warning_rate),
  max_student_nu_error_rate = max(fit_summary$student_nu_error_rate),
  min_wald_interval_success_rate = min(wald_focus$interval_success_rate),
  min_wald_coverage = min(wald_focus$coverage),
  max_wald_coverage = max(wald_focus$coverage),
  max_wald_coverage_mcse = max(wald_focus$coverage_mcse),
  min_nu_wald_coverage = min(nu_wald_focus$coverage),
  max_nu_wald_coverage_mcse = max(nu_wald_focus$coverage_mcse),
  stringsAsFactors = FALSE
)

utils::write.csv(
  conditions,
  file.path(tables_dir, "student-nu-calibration-conditions.csv"),
  row.names = FALSE
)
utils::write.csv(
  fit_rows,
  file.path(tables_dir, "student-nu-calibration-fit-status.csv"),
  row.names = FALSE
)
utils::write.csv(
  fit_summary,
  file.path(tables_dir, "student-nu-calibration-status-summary.csv"),
  row.names = FALSE
)
utils::write.csv(
  wald_focus,
  file.path(tables_dir, "student-nu-wald-diagnostics.csv"),
  row.names = FALSE
)
utils::write.csv(
  nu_wald_focus,
  file.path(tables_dir, "student-nu-wald-shape-diagnostics.csv"),
  row.names = FALSE
)
utils::write.csv(
  run_summary,
  file.path(artifact_dir, "student-nu-wald-calibration-run-summary.csv"),
  row.names = FALSE
)
writeLines(
  capture.output(sessionInfo()),
  file.path(artifact_dir, "session-info.txt")
)
unlink(file.path(artifact_dir, "results"), recursive = TRUE)

readme <- c(
  "# Student-t Nu Wald Calibration Diagnostic",
  "",
  "This artifact extends the Student-t finite-variance guard audit with a",
  "larger Wald interval diagnostic for the fixed-effect Student-t shape route.",
  "It uses the existing Phase 18 Student-t shape simulation writer and keeps",
  "the interpretation label at `diagnostic_calibration_pilot`.",
  "",
  "The fitted model is `bf(y ~ x, sigma ~ z, nu ~ w)` with",
  "`family = student()`. The Student-t shape is parameterized as",
  "`nu = 2 + exp(eta_nu)`, so the fitted model is deliberately finite-variance",
  "and does not include `nu <= 2`.",
  "",
  "## ADEMP Summary",
  "",
  "**Aim.** Quantify whether the Student-t finite-variance diagnostic remains",
  "visible in a 100-replicate-per-cell Wald interval pilot, and record the",
  "first MCSE-backed Wald interval consequences for ordinary and low-`nu`",
  "fixed-effect cells.",
  "",
  "**Data-generating mechanism.** Each replicate uses `n = 180`,",
  "`beta_mu = (0.25, 0.55)`, `beta_sigma = (log(0.65), 0.20)`,",
  "`nu_slope = 0`, and `rho(x, w) = 0.20`. The two cells differ only in",
  "`nu(w = 0)`: 2.8 for the low-boundary cell and 8.0 for the ordinary cell.",
  "",
  "**Estimands.** Formula-scale fixed effects for `mu`, `sigma`, and `nu`,",
  "with `student_nu` status/value/message rows from `check_drm()` retained",
  "beside interval status.",
  "",
  "**Methods.** Each replicate fits `drmTMB(..., family = student())` through",
  "the existing Phase 18 Student-t shape runner. This diagnostic uses Wald",
  "intervals only. Profile and bootstrap intervals are intentionally absent",
  "from this slice.",
  "",
  "**Performance measures.** The committed tables report convergence,",
  "`pdHess`, warning, `student_nu` status rates, Wald interval success, Wald",
  "coverage, MCSE, interval width, missed intervals, and unusable intervals.",
  "",
  "## Files",
  "",
  "- `run-pilot.R`: reproducible runner.",
  "- `student-nu-wald-calibration-run-summary.csv`: one-row headline summary.",
  "- `session-info.txt`: R session information.",
  "- `tables/student-nu-calibration-conditions.csv`: simulation cells.",
  "- `tables/student-nu-calibration-fit-status.csv`: one row per fitted replicate.",
  "- `tables/student-nu-calibration-status-summary.csv`: diagnostic status rates.",
  "- `tables/student-nu-wald-diagnostics.csv`: Wald interval diagnostics for all parameters.",
  "- `tables/student-nu-wald-shape-diagnostics.csv`: Wald interval diagnostics for `nu` terms.",
  "- `tables/student-shape-*.csv`: standard Phase 18 Student-t shape artifact tables.",
  "",
  "The raw per-replicate RDS files are generated transiently by the runner and",
  "deleted before the artifact is committed.",
  "",
  "## Conditions",
  "",
  md_table(
    conditions,
    c(
      "cell_id",
      "cell_label",
      "n",
      "nu_at_w0",
      "nu_slope",
      "sigma_slope",
      "rho_xw"
    ),
    c(
      "Cell",
      "Label",
      "n",
      "`nu(w = 0)`",
      "`nu` slope",
      "`sigma` slope",
      "`rho(x, w)`"
    )
  ),
  "",
  "Each cell uses 100 replicates, for 200 fitted models.",
  "",
  "## Results",
  "",
  sprintf(
    "The run attempted %d fits. The minimum convergence rate was %.3f, the minimum `pdHess` rate was %.3f, and the maximum `student_nu` warning rate was %.3f.",
    run_summary$fit_attempts,
    run_summary$min_convergence_rate,
    run_summary$min_pdHess_rate,
    run_summary$max_student_nu_warning_rate
  ),
  "",
  md_table(
    fit_summary,
    c(
      "cell_label",
      "fit_replicates",
      "convergence_rate",
      "pdHess_rate",
      "student_nu_ok_rate",
      "student_nu_warning_rate",
      "student_nu_error_rate",
      "student_nu_note_rate"
    ),
    c(
      "Cell",
      "Fits",
      "Converged",
      "`pdHess`",
      "`student_nu` ok",
      "`student_nu` warning",
      "`student_nu` error",
      "`student_nu` note"
    )
  ),
  "",
  "Wald interval diagnostics for the shape terms:",
  "",
  md_table(
    nu_wald_focus[
      c(
        "cell_label",
        "parameter",
        "n_replicate",
        "n_interval",
        "coverage",
        "coverage_mcse",
        "interval_success_rate",
        "interval_failure_rate",
        "n_interval_missed",
        "n_interval_unusable"
      )
    ],
    c(
      "cell_label",
      "parameter",
      "n_replicate",
      "n_interval",
      "coverage",
      "coverage_mcse",
      "interval_success_rate",
      "interval_failure_rate",
      "n_interval_missed",
      "n_interval_unusable"
    ),
    c(
      "Cell",
      "Parameter",
      "Replicates",
      "Usable intervals",
      "Coverage",
      "Coverage MCSE",
      "Interval success",
      "Interval failure",
      "Missed",
      "Unusable"
    )
  ),
  "",
  "The low-boundary cell keeps the finite-variance warning/error surface",
  "visible and loses more usable intervals than the ordinary cell. The ordinary",
  "cell has higher interval availability but still carries Gaussian-tail notes",
  "when fitted `nu` moves toward a high-degree-of-freedom limit. These results",
  "are useful for prioritizing future Student-t profile/bootstrap work, but the",
  "replicate count and Wald-only interval method are not a promotion gate.",
  "",
  "## Boundary",
  "",
  "This artifact covers only fixed-effect Student-t shape models with",
  "`bf(y ~ x, sigma ~ z, nu ~ w)`. It does not test random effects, bivariate",
  "responses, structured effects, true `nu <= 2` misspecification stress,",
  "profile/bootstrap intervals, external comparators, speed, Julia bridge",
  "behavior, release readiness, CRAN readiness, or non-Gaussian REML/AI-REML.",
  "",
  "The reporting follows the ADEMP framing from Morris, White, and Crowther",
  "(2019) and the simulation-reporting discipline in Williams et al. (2024)."
)
writeLines(readme, file.path(artifact_dir, "README.md"))

print(run_summary)
print(fit_summary)
print(nu_wald_focus)
