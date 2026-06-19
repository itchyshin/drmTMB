args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg)) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath(
    "docs/dev-log/simulation-artifacts/2026-06-19-student-nu-profile-bootstrap-calibration-diagnostic/run-pilot.R",
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

master_seed <- 20260622L
n_rep <- 50L
bootstrap_nsim <- 50L
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

max_or_na <- function(x) {
  x <- x[is.finite(x)]
  if (!length(x)) {
    return(NA_real_)
  }
  max(x)
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

profile_intervals <- merge(
  conditions[c("cell_id", "cell_label", "nu_at_w0")],
  out$summary$profile_intervals,
  by = "cell_id",
  all.y = TRUE,
  sort = FALSE
)
bootstrap_intervals <- merge(
  conditions[c("cell_id", "cell_label", "nu_at_w0")],
  out$summary$bootstrap_intervals,
  by = "cell_id",
  all.y = TRUE,
  sort = FALSE
)
interval_diagnostics <- merge(
  conditions[c("cell_id", "cell_label", "nu_at_w0")],
  out$summary$interval_diagnostics,
  by = "cell_id",
  all.y = TRUE,
  sort = FALSE
)

nu_profile_intervals <- profile_intervals[
  profile_intervals$parameter %in% profile_parameters,
  ,
  drop = FALSE
]
nu_profile_intervals$covered <- with(
  nu_profile_intervals,
  is.finite(conf.low) &
    is.finite(conf.high) &
    is.finite(truth) &
    truth >= conf.low &
    truth <= conf.high
)
nu_bootstrap_intervals <- bootstrap_intervals[
  bootstrap_intervals$parameter %in% profile_parameters,
  ,
  drop = FALSE
]
nu_bootstrap_intervals$covered <- with(
  nu_bootstrap_intervals,
  is.finite(conf.low) &
    is.finite(conf.high) &
    is.finite(truth) &
    truth >= conf.low &
    truth <= conf.high
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
    n_profile = rep(1L, nrow(nu_profile_intervals)),
    n_profile_ok = as.integer(nu_profile_intervals$interval_status == "ok"),
    n_profile_failed = as.integer(
      nu_profile_intervals$interval_status != "ok"
    ),
    n_profile_covered = as.integer(
      nu_profile_intervals$interval_status == "ok" &
        nu_profile_intervals$covered
    ),
    n_profile_degenerate = as.integer(
      is.finite(nu_profile_intervals$conf.low) &
        is.finite(nu_profile_intervals$conf.high) &
        abs(nu_profile_intervals$conf.high - nu_profile_intervals$conf.low) <
          1e-8
    )
  ) ~ cell_id + parameter,
  nu_profile_intervals,
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
profile_summary$profile_coverage <- ifelse(
  profile_summary$n_profile_ok > 0,
  profile_summary$n_profile_covered / profile_summary$n_profile_ok,
  NA_real_
)
profile_summary$profile_coverage_mcse <- mcse_binary(
  profile_summary$profile_coverage,
  profile_summary$n_profile_ok
)
profile_summary$profile_degenerate_rate <-
  profile_summary$n_profile_degenerate / profile_summary$n_profile

bootstrap_summary <- stats::aggregate(
  cbind(
    n_interval = rep(1L, nrow(nu_bootstrap_intervals)),
    n_bootstrap_ok = as.integer(
      nu_bootstrap_intervals$interval_status == "ok"
    ),
    n_bootstrap_failed = as.integer(
      nu_bootstrap_intervals$interval_status != "ok"
    ),
    n_bootstrap_covered = as.integer(
      nu_bootstrap_intervals$interval_status == "ok" &
        nu_bootstrap_intervals$covered
    )
  ) ~ cell_id + parameter,
  nu_bootstrap_intervals,
  sum
)
bootstrap_min <- stats::aggregate(
  n_bootstrap ~ cell_id + parameter,
  nu_bootstrap_intervals,
  min,
  na.rm = TRUE
)
names(bootstrap_min)[names(bootstrap_min) == "n_bootstrap"] <-
  "min_n_bootstrap"
bootstrap_mean <- stats::aggregate(
  n_bootstrap ~ cell_id + parameter,
  nu_bootstrap_intervals,
  mean,
  na.rm = TRUE
)
names(bootstrap_mean)[names(bootstrap_mean) == "n_bootstrap"] <-
  "mean_n_bootstrap"
bootstrap_summary <- merge(
  bootstrap_summary,
  bootstrap_min,
  by = c("cell_id", "parameter"),
  all.x = TRUE,
  sort = FALSE
)
bootstrap_summary <- merge(
  bootstrap_summary,
  bootstrap_mean,
  by = c("cell_id", "parameter"),
  all.x = TRUE,
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
bootstrap_summary$bootstrap_coverage <- ifelse(
  bootstrap_summary$n_bootstrap_ok > 0,
  bootstrap_summary$n_bootstrap_covered / bootstrap_summary$n_bootstrap_ok,
  NA_real_
)
bootstrap_summary$bootstrap_coverage_mcse <- mcse_binary(
  bootstrap_summary$bootstrap_coverage,
  bootstrap_summary$n_bootstrap_ok
)

run_summary <- data.frame(
  surface = "student_nu_profile_bootstrap_calibration_diagnostic",
  interpretation_label = "diagnostic_interval_calibration",
  master_seed = master_seed,
  git_sha = git_value("rev-parse", "HEAD"),
  n_conditions = nrow(conditions),
  n_rep = n_rep,
  fit_attempts = nrow(conditions) * n_rep,
  profile_parameters = paste(profile_parameters, collapse = ";"),
  profile_level = profile_level,
  bootstrap_nsim = bootstrap_nsim,
  bootstrap_level = bootstrap_level,
  elapsed_seconds = elapsed_seconds,
  min_convergence_rate = min(fit_summary$convergence_rate),
  min_pdHess_rate = min(fit_summary$pdHess_rate),
  min_nu_profile_ok_rate = min(profile_summary$profile_ok_rate),
  max_nu_profile_coverage_mcse = max_or_na(
    profile_summary$profile_coverage_mcse
  ),
  min_nu_bootstrap_ok_rate = min(bootstrap_summary$bootstrap_ok_rate),
  min_nu_bootstrap_refits = min(bootstrap_summary$min_n_bootstrap),
  max_nu_bootstrap_coverage_mcse = max_or_na(
    bootstrap_summary$bootstrap_coverage_mcse
  )
)

utils::write.csv(
  conditions,
  file.path(
    tables_dir,
    "student-nu-profile-bootstrap-calibration-conditions.csv"
  ),
  row.names = FALSE
)
utils::write.csv(
  fit_rows,
  file.path(
    tables_dir,
    "student-nu-profile-bootstrap-calibration-fit-status.csv"
  ),
  row.names = FALSE
)
utils::write.csv(
  fit_summary,
  file.path(
    tables_dir,
    "student-nu-profile-bootstrap-calibration-fit-summary.csv"
  ),
  row.names = FALSE
)
utils::write.csv(
  nu_profile_intervals,
  file.path(tables_dir, "student-nu-profile-calibration-intervals.csv"),
  row.names = FALSE
)
utils::write.csv(
  profile_summary,
  file.path(tables_dir, "student-nu-profile-calibration-summary.csv"),
  row.names = FALSE
)
utils::write.csv(
  nu_bootstrap_intervals,
  file.path(tables_dir, "student-nu-bootstrap-calibration-intervals.csv"),
  row.names = FALSE
)
utils::write.csv(
  bootstrap_summary,
  file.path(tables_dir, "student-nu-bootstrap-calibration-summary.csv"),
  row.names = FALSE
)
utils::write.csv(
  nu_interval_diagnostics,
  file.path(
    tables_dir,
    "student-nu-profile-bootstrap-calibration-diagnostics.csv"
  ),
  row.names = FALSE
)
utils::write.csv(
  out$summary$interval_failures,
  file.path(
    tables_dir,
    "student-nu-profile-bootstrap-calibration-failures.csv"
  ),
  row.names = FALSE
)
utils::write.csv(
  run_summary,
  file.path(
    artifact_dir,
    "student-nu-profile-bootstrap-calibration-run-summary.csv"
  ),
  row.names = FALSE
)

session <- utils::capture.output(utils::sessionInfo())
writeLines(session, file.path(artifact_dir, "session-info.txt"))

readme <- c(
  "# Student-t `nu` Profile/Bootstrap Calibration Diagnostic",
  "",
  "## Scope",
  "",
  "This artifact is a bounded calibration diagnostic for the fixed-effect",
  "Student-t shape route. It follows the smaller profile/bootstrap pilot by",
  "increasing the run to 50 replicates per cell and 50 bootstrap refits per",
  "fit, so profile failures, bootstrap status, MCSE, and rough 70% interval",
  "coverage can be audited with more depth without presenting a promotion grid.",
  "",
  "It is not release-readiness evidence and does not settle profile/bootstrap",
  "coverage for users. The profile level remains 0.70, bootstrap refit counts",
  "are still modest, and failed or non-positive-Hessian fits remain part of the",
  "evidence.",
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
      "max_nu_profile_coverage_mcse",
      "min_nu_bootstrap_ok_rate",
      "min_nu_bootstrap_refits",
      "max_nu_bootstrap_coverage_mcse"
    ),
    c(
      "fits",
      "min convergence",
      "min pdHess",
      "min profile ok",
      "max profile coverage MCSE",
      "min bootstrap ok",
      "min bootstrap refits",
      "max bootstrap coverage MCSE"
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
    c("cell", "nu at w=0", "fits", "convergence", "pdHess", "warning rate")
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
      "profile_coverage",
      "profile_coverage_mcse"
    ),
    c(
      "cell",
      "parameter",
      "profiles",
      "ok",
      "failed",
      "ok rate",
      "rough coverage",
      "coverage MCSE"
    )
  ),
  "",
  "## `nu` Bootstrap Status",
  "",
  md_table(
    bootstrap_summary,
    c(
      "cell_label",
      "parameter",
      "n_interval",
      "n_bootstrap_ok",
      "n_bootstrap_failed",
      "bootstrap_ok_rate",
      "bootstrap_coverage",
      "bootstrap_coverage_mcse",
      "min_n_bootstrap"
    ),
    c(
      "cell",
      "parameter",
      "intervals",
      "ok",
      "failed",
      "ok rate",
      "rough coverage",
      "coverage MCSE",
      "min refits"
    )
  ),
  "",
  "## Interpretation",
  "",
  "This diagnostic records interval-method status and rough finite-sample behavior.",
  "The profile rows are target-specific and can fail even when the model returns",
  "finite point estimates. The bootstrap rows show whether the bounded refit",
  "budget returns intervals, but 50 refits per fit is not enough to support",
  "headline calibration.",
  "",
  "Any later Student-t interval claim should carry the fit status, profile",
  "status, bootstrap refit count, `student_nu` diagnostics, and MCSE columns",
  "forward instead of summarizing away failed or weak rows.",
  "",
  "## Files",
  "",
  "- `run-pilot.R`: reproducible runner.",
  "- `student-nu-profile-bootstrap-calibration-run-summary.csv`: top-line run summary.",
  "- `tables/student-nu-profile-bootstrap-calibration-fit-summary.csv`: fit status by cell.",
  "- `tables/student-nu-profile-calibration-summary.csv`: profile status and rough coverage by `nu` parameter.",
  "- `tables/student-nu-bootstrap-calibration-summary.csv`: bootstrap status and rough coverage by `nu` parameter.",
  "- `tables/student-nu-profile-bootstrap-calibration-diagnostics.csv`: interval diagnostics for the two `nu` coefficients.",
  "- `tables/student-nu-profile-bootstrap-calibration-failures.csv`: interval failure rows.",
  "",
  "## Boundary",
  "",
  "This artifact does not promote Student-t profile or bootstrap coverage,",
  "release readiness, CRAN readiness, Julia bridge parity, random effects,",
  "bivariate routes, true `nu <= 2`, or non-Gaussian REML/AI-REML."
)
writeLines(readme, file.path(artifact_dir, "README.md"))

message(
  "Wrote Student-t profile/bootstrap calibration diagnostic to ",
  artifact_dir
)
