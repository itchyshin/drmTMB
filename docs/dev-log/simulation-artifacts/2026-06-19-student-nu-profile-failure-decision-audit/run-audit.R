args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg)) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath(
    "docs/dev-log/simulation-artifacts/2026-06-19-student-nu-profile-failure-decision-audit/run-audit.R",
    mustWork = TRUE
  )
}

artifact_dir <- dirname(script_path)
repo_root <- normalizePath(
  file.path(artifact_dir, "../../../.."),
  mustWork = TRUE
)
source_artifact <- file.path(
  repo_root,
  "docs/dev-log/simulation-artifacts/2026-06-19-student-nu-profile-bootstrap-calibration-diagnostic"
)
source_artifact_rel <- "docs/dev-log/simulation-artifacts/2026-06-19-student-nu-profile-bootstrap-calibration-diagnostic"
source_tables <- file.path(source_artifact, "tables")
tables_dir <- file.path(artifact_dir, "tables")
dir.create(tables_dir, recursive = TRUE, showWarnings = FALSE)

profile_summary <- read.csv(
  file.path(source_tables, "student-nu-profile-calibration-summary.csv")
)
bootstrap_summary <- read.csv(
  file.path(source_tables, "student-nu-bootstrap-calibration-summary.csv")
)
failure_rows <- read.csv(
  file.path(
    source_tables,
    "student-nu-profile-bootstrap-calibration-failures.csv"
  )
)
profile_intervals <- read.csv(
  file.path(source_tables, "student-nu-profile-calibration-intervals.csv")
)

profile_targets <- c("nu:(Intercept)", "nu:w")
profile_failures <- failure_rows[
  failure_rows$interval_method == "profile" &
    failure_rows$parameter %in% profile_targets,
  ,
  drop = FALSE
]

profile_failure_summary <- as.data.frame(
  xtabs(~ cell_id + parameter + interval_status, profile_failures)
)
names(profile_failure_summary) <- c(
  "cell_id",
  "parameter",
  "interval_status",
  "n_failures"
)
profile_failure_summary <- profile_failure_summary[
  profile_failure_summary$n_failures > 0,
  ,
  drop = FALSE
]

fit_status_summary <- as.data.frame(
  xtabs(~ fit_diagnostic_status + student_nu_status, profile_failures)
)
names(fit_status_summary) <- c(
  "fit_diagnostic_status",
  "student_nu_status",
  "n_profile_failures"
)
fit_status_summary <- fit_status_summary[
  fit_status_summary$n_profile_failures > 0,
  ,
  drop = FALSE
]

convergence_summary <- as.data.frame(
  xtabs(~ converged + pdHess, profile_failures)
)
names(convergence_summary) <- c("converged", "pdHess", "n_profile_failures")
convergence_summary <- convergence_summary[
  convergence_summary$n_profile_failures > 0,
  ,
  drop = FALSE
]

message_summary <- as.data.frame(table(profile_failures$interval_message))
names(message_summary) <- c("interval_message", "n_profile_failures")
message_summary <- message_summary[
  order(message_summary$n_profile_failures, decreasing = TRUE),
  ,
  drop = FALSE
]

degenerate_ok <- profile_intervals[
  profile_intervals$interval_status == "ok" &
    is.finite(profile_intervals$conf.low) &
    is.finite(profile_intervals$conf.high) &
    abs(profile_intervals$conf.high - profile_intervals$conf.low) < 1e-8,
  ,
  drop = FALSE
]
degenerate_ok <- degenerate_ok[,
  intersect(
    c(
      "cell_id",
      "replicate",
      "parameter",
      "truth",
      "estimate",
      "conf.low",
      "conf.high",
      "converged",
      "pdHess",
      "student_nu_status"
    ),
    names(degenerate_ok)
  ),
  drop = FALSE
]

student_decisions <- merge(
  profile_summary[
    c(
      "cell_id",
      "cell_label",
      "nu_at_w0",
      "parameter",
      "n_profile",
      "n_profile_ok",
      "n_profile_failed",
      "profile_ok_rate",
      "profile_coverage",
      "profile_coverage_mcse",
      "profile_degenerate_rate"
    )
  ],
  bootstrap_summary[
    c(
      "cell_id",
      "parameter",
      "n_interval",
      "n_bootstrap_ok",
      "bootstrap_ok_rate",
      "bootstrap_coverage",
      "bootstrap_coverage_mcse",
      "min_n_bootstrap"
    )
  ],
  by = c("cell_id", "parameter"),
  all = TRUE,
  sort = FALSE
)
student_decisions$profile_decision <- "blocked_by_method"
student_decisions$bootstrap_decision <- ifelse(
  student_decisions$cell_label == "ordinary_nu" &
    student_decisions$parameter == "nu:(Intercept)",
  "diagnostic_hold",
  "needs_larger_grid"
)
student_decisions$decision_reason <- paste(
  "Profile ok rate",
  sprintf("%.2f", student_decisions$profile_ok_rate),
  "with",
  student_decisions$n_profile_failed,
  "failed profiles; bootstrap coverage",
  sprintf("%.2f", student_decisions$bootstrap_coverage),
  "with",
  student_decisions$min_n_bootstrap,
  "refits."
)

true_true_failures <- convergence_summary$n_profile_failures[
  as.character(convergence_summary$converged) == "TRUE" &
    as.character(convergence_summary$pdHess) == "TRUE"
]
if (
  nrow(profile_failures) != 107L ||
    nrow(degenerate_ok) != 2L ||
    nrow(student_decisions) != 4L ||
    any(student_decisions$profile_decision != "blocked_by_method") ||
    sum(student_decisions$n_profile_failed) != 107L ||
    length(true_true_failures) != 1L ||
    true_true_failures != 86L
) {
  stop("Student-t profile decision audit assertions failed.", call. = FALSE)
}

write.csv(
  profile_failure_summary,
  file.path(tables_dir, "profile-failure-summary.csv"),
  row.names = FALSE
)
write.csv(
  fit_status_summary,
  file.path(tables_dir, "profile-failure-fit-status-summary.csv"),
  row.names = FALSE
)
write.csv(
  convergence_summary,
  file.path(tables_dir, "profile-failure-convergence-summary.csv"),
  row.names = FALSE
)
write.csv(
  message_summary,
  file.path(tables_dir, "profile-failure-message-summary.csv"),
  row.names = FALSE
)
write.csv(
  degenerate_ok,
  file.path(tables_dir, "profile-degenerate-ok-rows.csv"),
  row.names = FALSE
)
write.csv(
  student_decisions,
  file.path(tables_dir, "student-nu-interval-decision-summary.csv"),
  row.names = FALSE
)

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

readme <- c(
  "# Student-t `nu` Profile Failure Decision Audit",
  "",
  "## Scope",
  "",
  "This artifact is a readback audit of the 100-fit Student-t profile/bootstrap",
  "calibration diagnostic. It does not rerun fits and does not change interval",
  "methods. Its purpose is to decide whether the next Student-t interval slice",
  "should run a larger grid or repair/profile-audit the method first.",
  "",
  "## Source Artifact",
  "",
  paste0("- `", source_artifact_rel, "`"),
  "",
  "## Decision Summary",
  "",
  md_table(
    student_decisions,
    c(
      "cell_label",
      "parameter",
      "profile_ok_rate",
      "n_profile_failed",
      "profile_decision",
      "bootstrap_coverage",
      "bootstrap_coverage_mcse",
      "bootstrap_decision"
    ),
    c(
      "cell",
      "parameter",
      "profile ok",
      "profile failed",
      "profile decision",
      "bootstrap coverage",
      "bootstrap MCSE",
      "bootstrap decision"
    )
  ),
  "",
  "## Profile Failure Diagnostics",
  "",
  "The 100-fit calibration artifact retained 107 focused `nu` profile failures.",
  "Most failed rows reported `nonfinite_interval`; profile failure also occurred",
  "in many fits that had `converged = TRUE` and `pdHess = TRUE`, so larger",
  "replicate counts alone would not resolve the profile interval method.",
  "",
  md_table(
    convergence_summary,
    c("converged", "pdHess", "n_profile_failures"),
    c("converged", "pdHess", "profile failures"),
    digits = 0L
  ),
  "",
  "## Degenerate Profile Rows",
  "",
  "Two low-boundary `nu:(Intercept)` profile rows were formally `ok` but had",
  "degenerate intervals. They are retained as target-construction evidence, not",
  "as calibrated interval support.",
  "",
  md_table(
    degenerate_ok,
    intersect(
      c(
        "cell_id",
        "replicate",
        "parameter",
        "truth",
        "estimate",
        "conf.low",
        "conf.high",
        "converged",
        "pdHess",
        "student_nu_status"
      ),
      names(degenerate_ok)
    )
  ),
  "",
  "## Boundary",
  "",
  "Student-t profile intervals remain `blocked_by_method` for the current fixed-effect",
  "finite-variance shape route. Bootstrap intervals remain diagnostic or larger-grid",
  "candidates depending on the target. This artifact does not promote profile or",
  "bootstrap coverage, random effects, bivariate routes, structured routes, true",
  "`nu <= 2`, Julia bridge parity, release readiness, CRAN readiness, or",
  "non-Gaussian REML/AI-REML."
)

writeLines(readme, file.path(artifact_dir, "README.md"))

cat(
  paste0(
    "student_nu_profile_failure_decision_ok: profile_failures=",
    nrow(profile_failures),
    " degenerate_ok=",
    nrow(degenerate_ok),
    " decisions=",
    nrow(student_decisions),
    "\n"
  )
)
