args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg)) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath(
    "docs/dev-log/simulation-artifacts/2026-06-19-student-nu-profile-bootstrap-diagnostic/run-pilot.R",
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

master_seed <- 20260620L
n_rep <- 5L
bootstrap_nsim <- 10L
profile_level <- 0.70
bootstrap_level <- 0.70
profile_parameters <- c("nu:(Intercept)", "nu:w")

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

mcse_binary <- function(x, n) {
  ifelse(n > 0, sqrt(x * (1 - x) / n), NA_real_)
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
  profile_parameters = profile_parameters,
  profile_level = profile_level,
  profile_args = list(ystep = 0.75),
  bootstrap_nsim = bootstrap_nsim,
  bootstrap_level = bootstrap_level,
  bootstrap_cores = 1L,
  bootstrap_backend = "none",
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

profile_intervals <- out$summary$profile_intervals
profile_intervals <- merge(
  conditions[c("cell_id", "cell_label", "nu_at_w0")],
  profile_intervals,
  by = "cell_id",
  all.y = TRUE,
  sort = FALSE
)

bootstrap_intervals <- out$summary$bootstrap_intervals
bootstrap_intervals <- merge(
  conditions[c("cell_id", "cell_label", "nu_at_w0")],
  bootstrap_intervals,
  by = "cell_id",
  all.y = TRUE,
  sort = FALSE
)

interval_diagnostics <- out$summary$interval_diagnostics
interval_diagnostics <- merge(
  conditions[c("cell_id", "cell_label", "nu_at_w0")],
  interval_diagnostics,
  by = "cell_id",
  all.y = TRUE,
  sort = FALSE
)

nu_interval_diagnostics <- interval_diagnostics[
  interval_diagnostics$parameter %in%
    profile_parameters &
    interval_diagnostics$interval_method %in%
      c("profile", "parametric_bootstrap"),
  ,
  drop = FALSE
]

profile_summary <- stats::aggregate(
  cbind(
    n_profile = rep(1L, nrow(profile_intervals)),
    n_profile_ok = as.integer(profile_intervals$interval_status == "ok"),
    n_profile_failed = as.integer(profile_intervals$interval_status != "ok"),
    n_profile_degenerate = as.integer(
      is.finite(profile_intervals$conf.low) &
        is.finite(profile_intervals$conf.high) &
        abs(profile_intervals$conf.high - profile_intervals$conf.low) < 1e-8
    )
  ) ~ cell_id + parameter,
  profile_intervals,
  sum
)
profile_summary <- merge(
  conditions[c("cell_id", "cell_label", "nu_at_w0")],
  profile_summary,
  by = "cell_id",
  all.y = TRUE,
  sort = FALSE
)
profile_summary$profile_ok_rate <- profile_summary$n_profile_ok /
  profile_summary$n_profile
profile_summary$profile_ok_mcse <- mcse_binary(
  profile_summary$profile_ok_rate,
  profile_summary$n_profile
)
profile_summary$profile_degenerate_rate <-
  profile_summary$n_profile_degenerate / profile_summary$n_profile

bootstrap_summary <- stats::aggregate(
  cbind(
    n_interval = rep(1L, nrow(bootstrap_intervals)),
    n_bootstrap_ok = as.integer(bootstrap_intervals$interval_status == "ok"),
    n_bootstrap_failed = as.integer(
      bootstrap_intervals$interval_status != "ok"
    )
  ) ~ cell_id + parameter,
  bootstrap_intervals,
  sum
)
bootstrap_min <- stats::aggregate(
  n_bootstrap ~ cell_id + parameter,
  bootstrap_intervals,
  min,
  na.rm = TRUE
)
names(bootstrap_min)[names(bootstrap_min) == "n_bootstrap"] <-
  "min_n_bootstrap"
bootstrap_mean <- stats::aggregate(
  n_bootstrap ~ cell_id + parameter,
  bootstrap_intervals,
  mean,
  na.rm = TRUE
)
names(bootstrap_mean)[names(bootstrap_mean) == "n_bootstrap"] <-
  "mean_n_bootstrap"
bootstrap_summary <- bootstrap_summary[
  c(
    "cell_id",
    "parameter",
    "n_interval",
    "n_bootstrap_ok",
    "n_bootstrap_failed"
  )
]
bootstrap_summary <- merge(
  bootstrap_summary,
  bootstrap_min,
  by = c("cell_id", "parameter"),
  sort = FALSE
)
bootstrap_summary <- merge(
  bootstrap_summary,
  bootstrap_mean,
  by = c("cell_id", "parameter"),
  sort = FALSE
)
bootstrap_summary <- merge(
  conditions[c("cell_id", "cell_label", "nu_at_w0")],
  bootstrap_summary,
  by = "cell_id",
  all.y = TRUE,
  sort = FALSE
)
bootstrap_summary$bootstrap_ok_rate <- bootstrap_summary$n_bootstrap_ok /
  bootstrap_summary$n_interval
bootstrap_summary$bootstrap_ok_mcse <- mcse_binary(
  bootstrap_summary$bootstrap_ok_rate,
  bootstrap_summary$n_interval
)

nu_bootstrap_summary <- bootstrap_summary[
  bootstrap_summary$parameter %in% profile_parameters,
  ,
  drop = FALSE
]

run_summary <- data.frame(
  surface = "student_nu_profile_bootstrap_diagnostic",
  interpretation_label = "diagnostic_feasibility_pilot",
  master_seed = master_seed,
  git_sha = git_value("rev-parse", "HEAD"),
  n_conditions = nrow(conditions),
  n_rep = n_rep,
  fit_attempts = nrow(fit_rows),
  profile_parameters = paste(profile_parameters, collapse = ";"),
  profile_level = profile_level,
  bootstrap_nsim = bootstrap_nsim,
  bootstrap_level = bootstrap_level,
  elapsed_seconds = elapsed_seconds,
  min_convergence_rate = min(fit_summary$convergence_rate),
  min_pdHess_rate = min(fit_summary$pdHess_rate),
  min_nu_profile_ok_rate = min(profile_summary$profile_ok_rate),
  max_nu_profile_degenerate_rate = max(
    profile_summary$profile_degenerate_rate
  ),
  min_nu_bootstrap_ok_rate = min(nu_bootstrap_summary$bootstrap_ok_rate),
  min_nu_bootstrap_refits = min(nu_bootstrap_summary$min_n_bootstrap),
  stringsAsFactors = FALSE
)

utils::write.csv(
  conditions,
  file.path(tables_dir, "student-nu-profile-bootstrap-conditions.csv"),
  row.names = FALSE
)
utils::write.csv(
  fit_rows,
  file.path(tables_dir, "student-nu-profile-bootstrap-fit-status.csv"),
  row.names = FALSE
)
utils::write.csv(
  fit_summary,
  file.path(tables_dir, "student-nu-profile-bootstrap-fit-summary.csv"),
  row.names = FALSE
)
utils::write.csv(
  profile_intervals,
  file.path(tables_dir, "student-nu-profile-intervals.csv"),
  row.names = FALSE
)
utils::write.csv(
  profile_summary,
  file.path(tables_dir, "student-nu-profile-summary.csv"),
  row.names = FALSE
)
utils::write.csv(
  bootstrap_intervals,
  file.path(tables_dir, "student-nu-bootstrap-intervals.csv"),
  row.names = FALSE
)
utils::write.csv(
  bootstrap_summary,
  file.path(tables_dir, "student-nu-bootstrap-summary.csv"),
  row.names = FALSE
)
utils::write.csv(
  nu_interval_diagnostics,
  file.path(tables_dir, "student-nu-profile-bootstrap-diagnostics.csv"),
  row.names = FALSE
)
utils::write.csv(
  out$summary$interval_failures,
  file.path(tables_dir, "student-nu-profile-bootstrap-failures.csv"),
  row.names = FALSE
)
utils::write.csv(
  run_summary,
  file.path(
    artifact_dir,
    "student-nu-profile-bootstrap-run-summary.csv"
  ),
  row.names = FALSE
)
writeLines(
  capture.output(sessionInfo()),
  file.path(artifact_dir, "session-info.txt")
)

readme <- c(
  "# Student-t `nu` Profile/Bootstrap Diagnostic",
  "",
  "## Scope",
  "",
  "This artifact is a small feasibility diagnostic for the fixed-effect",
  "Student-t shape route. It follows the 100-replicate Wald calibration",
  "artifact by asking whether the existing profile-likelihood and",
  "parametric-bootstrap machinery can produce visible status rows for the two",
  "`nu` coefficients in ordinary and low-boundary cells.",
  "",
  "It is not a coverage or promotion grid. With five replicates per cell and",
  "ten bootstrap refits per fit, the only defensible conclusion is whether the",
  "interval machinery runs, which statuses it reports, and whether degenerate",
  "or failed interval rows remain visible.",
  "",
  "## Model",
  "",
  "The fitted model is `bf(y ~ x, sigma ~ z, nu ~ w)` with",
  "`family = student()`. The shape parameter uses",
  "`nu = 2 + exp(eta_nu)`, so the fitted model is deliberately finite-variance",
  "and excludes `nu <= 2`.",
  "",
  "## Design",
  "",
  "Both cells use `n = 180`, `beta_mu = (0.25, 0.55)`,",
  "`beta_sigma = (log(0.65), 0.20)`, `nu_slope = 0`, and",
  "`rho(x, w) = 0.20`. The low-boundary cell has `nu(w = 0) = 2.8`; the",
  "ordinary cell has `nu(w = 0) = 8.0`.",
  "",
  paste0(
    "Each cell has ",
    n_rep,
    " replicates. Profile intervals are requested"
  ),
  paste0("at level ", profile_level, " for `nu:(Intercept)` and `nu:w`."),
  paste0(
    "Parametric-bootstrap intervals are requested at level ",
    bootstrap_level,
    " with ",
    bootstrap_nsim,
    " refits per fit."
  ),
  "",
  "## Run Summary",
  "",
  md_table(
    run_summary,
    c(
      "fit_attempts",
      "min_convergence_rate",
      "min_pdHess_rate",
      "min_nu_profile_ok_rate",
      "max_nu_profile_degenerate_rate",
      "min_nu_bootstrap_ok_rate",
      "min_nu_bootstrap_refits"
    ),
    c(
      "fits",
      "min convergence",
      "min pdHess",
      "min profile ok",
      "max degenerate profile",
      "min bootstrap ok",
      "min bootstrap refits"
    )
  ),
  "",
  "## Fit Status",
  "",
  md_table(
    fit_summary,
    c(
      "cell_label",
      "nu_at_w0",
      "fit_replicates",
      "convergence_rate",
      "pdHess_rate",
      "warning_rate"
    ),
    c(
      "cell",
      "nu at w=0",
      "fits",
      "convergence",
      "pdHess",
      "warning rate"
    )
  ),
  "",
  "## `nu` Profile Status",
  "",
  md_table(
    profile_summary,
    c(
      "cell_label",
      "parameter",
      "n_profile",
      "n_profile_ok",
      "n_profile_failed",
      "profile_ok_rate",
      "n_profile_degenerate",
      "profile_degenerate_rate"
    ),
    c(
      "cell",
      "parameter",
      "profiles",
      "ok",
      "failed",
      "ok rate",
      "degenerate",
      "degenerate rate"
    )
  ),
  "",
  "## `nu` Bootstrap Status",
  "",
  md_table(
    nu_bootstrap_summary,
    c(
      "cell_label",
      "parameter",
      "n_interval",
      "n_bootstrap_ok",
      "n_bootstrap_failed",
      "bootstrap_ok_rate",
      "min_n_bootstrap",
      "mean_n_bootstrap"
    ),
    c(
      "cell",
      "parameter",
      "intervals",
      "ok",
      "failed",
      "ok rate",
      "min refits",
      "mean refits"
    )
  ),
  "",
  "## Interpretation",
  "",
  "This diagnostic records interval feasibility and status visibility only.",
  "The bootstrap count is too small for interval calibration, and the profile",
  "level is chosen to keep the run bounded. Degenerate profile rows, failed",
  "Wald rows, `student_nu` warnings, and bootstrap refit counts should travel",
  "with any later Student-t interval evidence rather than being summarized",
  "away.",
  "",
  "## Files",
  "",
  "- `run-pilot.R`: reproducible runner.",
  "- `student-nu-profile-bootstrap-run-summary.csv`: top-line run summary.",
  "- `tables/student-nu-profile-bootstrap-fit-summary.csv`: fit status by cell.",
  "- `tables/student-nu-profile-summary.csv`: profile status by `nu` parameter.",
  "- `tables/student-nu-bootstrap-summary.csv`: bootstrap status by parameter.",
  "- `tables/student-nu-profile-bootstrap-diagnostics.csv`: interval",
  "  diagnostics for the two `nu` coefficients.",
  "- `tables/student-nu-profile-bootstrap-failures.csv`: interval failure rows.",
  "",
  "## Boundary",
  "",
  "This artifact does not promote Student-t profile or bootstrap coverage,",
  "release readiness, CRAN readiness, Julia bridge parity, random effects,",
  "bivariate routes, true `nu <= 2`, or non-Gaussian REML/AI-REML."
)
writeLines(readme, file.path(artifact_dir, "README.md"))

message(
  "Wrote Student-t nu profile/bootstrap diagnostic artifact to ",
  artifact_dir
)
