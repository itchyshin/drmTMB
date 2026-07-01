#!/usr/bin/env Rscript

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

args <- commandArgs(TRUE)
if (any(args %in% c("--help", "-h"))) {
  cat(
    paste(
      "Usage: Rscript tools/run-structured-re-gaussian-mu-slope-boundary-profile-diagnostic.R [options]",
      "",
      "Options:",
      "  --source-replicates=PATH        Pregrid replicate TSV to diagnose.",
      "  --output-dir=PATH              Artifact directory.",
      "  --max-rows=N|Inf               Maximum boundary rows to profile (default: Inf).",
      "  --profile-endpoint-max-eval=N  Endpoint profile budget (default: 80).",
      "  --overwrite=true               Replace an existing artifact directory.",
      "  --write-dashboard=false        Do not overwrite the dashboard diagnostic sidecar.",
      "",
      sep = "\n"
    )
  )
  quit(status = 0)
}
arg_value <- function(name, default = NULL) {
  prefix <- paste0("--", name, "=")
  hit <- grep(paste0("^", prefix), args, value = TRUE)
  if (length(hit) == 0L) {
    return(default)
  }
  sub(prefix, "", hit[[length(hit)]], fixed = TRUE)
}
arg_flag <- function(name, default = FALSE) {
  value <- arg_value(name, NULL)
  if (is.null(value)) {
    return(default)
  }
  tolower(value) %in% c("1", "true", "yes", "y")
}

script_file <- sub(
  "^--file=",
  "",
  grep("^--file=", commandArgs(FALSE), value = TRUE)[1L] %||% "tools"
)
repo_root <- normalizePath(file.path(dirname(script_file), ".."))
if (!file.exists(file.path(repo_root, "DESCRIPTION"))) {
  repo_root <- normalizePath(getwd())
}

default_artifact_dir <- file.path(
  repo_root,
  "docs",
  "dev-log",
  "simulation-artifacts",
  "2026-06-29-gaussian-mu-slope-boundary-profile-diagnostic-local"
)
artifact_dir <- normalizePath(
  arg_value("output-dir", default_artifact_dir),
  mustWork = FALSE
)
overwrite <- arg_flag("overwrite", FALSE)
max_rows_arg <- arg_value("max-rows", "Inf")
max_rows <- suppressWarnings(as.numeric(max_rows_arg))
if (!is.finite(max_rows) && max_rows_arg != "Inf") {
  stop("`--max-rows` must be a positive integer or Inf.", call. = FALSE)
}
if (is.finite(max_rows) && max_rows < 1) {
  stop("`--max-rows` must be a positive integer or Inf.", call. = FALSE)
}
profile_endpoint_max_eval <- as.integer(arg_value(
  "profile-endpoint-max-eval",
  "80"
))
if (!is.finite(profile_endpoint_max_eval) || profile_endpoint_max_eval < 1L) {
  stop(
    "`--profile-endpoint-max-eval` must be a positive integer.",
    call. = FALSE
  )
}
write_dashboard_default <- identical(
  normalizePath(artifact_dir, mustWork = FALSE),
  normalizePath(default_artifact_dir, mustWork = FALSE)
)
write_dashboard <- arg_flag("write-dashboard", write_dashboard_default)

if (dir.exists(artifact_dir) && !overwrite) {
  stop(
    "`output-dir` already exists. Use --overwrite=true to replace it: ",
    artifact_dir,
    call. = FALSE
  )
}
if (dir.exists(artifact_dir) && overwrite) {
  unlink(artifact_dir, recursive = TRUE)
}
dir.create(artifact_dir, recursive = TRUE, showWarnings = FALSE)

dashboard_dir <- file.path(repo_root, "docs", "dev-log", "dashboard")
default_source_replicate_path <- file.path(
  repo_root,
  "docs",
  "dev-log",
  "simulation-artifacts",
  "2026-06-29-gaussian-mu-slope-coverage-pregrid-local",
  "structured-re-gaussian-mu-slope-coverage-pregrid-replicates.tsv"
)
source_replicate_path <- normalizePath(
  arg_value("source-replicates", default_source_replicate_path),
  mustWork = FALSE
)
detail_path <- file.path(
  artifact_dir,
  "structured-re-gaussian-mu-slope-boundary-profile-diagnostic-detail.tsv"
)
summary_path <- file.path(
  artifact_dir,
  "structured-re-gaussian-mu-slope-boundary-profile-diagnostic-summary.tsv"
)
run_log_path <- file.path(
  artifact_dir,
  "structured-re-gaussian-mu-slope-boundary-profile-diagnostic-run-log.tsv"
)
session_info_path <- file.path(artifact_dir, "sessionInfo.txt")
git_sha_path <- file.path(artifact_dir, "git-sha.txt")
dashboard_path <- file.path(
  dashboard_dir,
  "structured-re-gaussian-mu-slope-boundary-profile-diagnostic.tsv"
)

clean_text <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- "NA"
  x <- gsub("[\r\n\t]+", " ", x)
  x <- gsub("[^ -~]", "", x)
  x <- gsub(" +", " ", x)
  trimws(x)
}

write_tsv <- function(x, path) {
  character_cols <- vapply(x, is.character, logical(1L))
  x[character_cols] <- lapply(x[character_cols], clean_text)
  utils::write.table(
    x,
    path,
    sep = "\t",
    quote = FALSE,
    row.names = FALSE,
    na = "NA"
  )
}

source_local <- function(path) {
  source(file.path(repo_root, path), local = .GlobalEnv)
}

suppressPackageStartupMessages(devtools::load_all(repo_root, quiet = TRUE))
for (path in c(
  "inst/sim/R/sim_registry.R",
  "inst/sim/R/sim_utils.R",
  "inst/sim/R/sim_runner.R",
  "inst/sim/R/sim_aggregate.R",
  "inst/sim/R/sim_uncertainty.R",
  "inst/sim/dgp/sim_dgp_phylo_mu_slope.R",
  "inst/sim/fit/sim_summarise_phylo_mu_slope.R",
  "inst/sim/run/sim_run_phylo_mu_slope_smoke.R",
  "inst/sim/dgp/sim_dgp_spatial_mu_slope.R",
  "inst/sim/fit/sim_summarise_spatial_mu_slope.R",
  "inst/sim/run/sim_run_spatial_mu_slope_smoke.R",
  "inst/sim/dgp/sim_dgp_animal_mu_slope.R",
  "inst/sim/fit/sim_summarise_animal_mu_slope.R",
  "inst/sim/run/sim_run_animal_mu_slope_smoke.R",
  "inst/sim/dgp/sim_dgp_relmat_mu_slope.R",
  "inst/sim/fit/sim_summarise_relmat_mu_slope.R",
  "inst/sim/run/sim_run_relmat_mu_slope_smoke.R"
)) {
  source_local(path)
}

provider_specs <- list(
  phylo = list(
    condition = phase18_phylo_mu_slope_conditions(
      n_tip = 8L,
      n_each = 7L
    )[1L, , drop = FALSE],
    dgp = phase18_dgp_phylo_mu_slope_cell,
    fit = phase18_fit_phylo_mu_slope
  ),
  spatial = list(
    condition = phase18_spatial_mu_slope_conditions(
      n_site = 12L,
      n_each = 8L
    )[1L, , drop = FALSE],
    dgp = phase18_dgp_spatial_mu_slope_cell,
    fit = phase18_fit_spatial_mu_slope
  ),
  animal = list(
    condition = phase18_animal_mu_slope_conditions(
      n_id = 8L,
      n_each = 7L
    )[1L, , drop = FALSE],
    dgp = phase18_dgp_animal_mu_slope_cell,
    fit = phase18_fit_animal_mu_slope
  ),
  relmat = list(
    condition = phase18_relmat_mu_slope_conditions(
      n_id = 8L,
      n_each = 7L
    )[1L, , drop = FALSE],
    dgp = phase18_dgp_relmat_mu_slope_cell,
    fit = phase18_fit_relmat_mu_slope
  )
)

provider_boundary <- c(
  phylo = "",
  spatial = " no range-estimating spatial support,",
  animal = " no pedigree/Ainv bridge marshalling,",
  relmat = " no Q bridge marshalling,"
)
provider_label <- c(
  phylo = "phylo",
  spatial = "fixed-covariance spatial",
  animal = "animal A-matrix",
  relmat = "relmat K-matrix"
)

source_replicates <- utils::read.delim(
  source_replicate_path,
  sep = "\t",
  quote = "",
  check.names = FALSE,
  stringsAsFactors = FALSE
)
boundary_rows <- source_replicates[
  source_replicates$interval_status == "boundary_or_nonwald_status",
  ,
  drop = FALSE
]
boundary_rows <- boundary_rows[
  order(
    boundary_rows$provider,
    boundary_rows$replicate_index,
    boundary_rows$endpoint_member
  ),
  ,
  drop = FALSE
]
if (is.finite(max_rows)) {
  boundary_rows <- boundary_rows[
    seq_len(min(max_rows, nrow(boundary_rows))),
    ,
    drop = FALSE
  ]
}
if (nrow(boundary_rows) == 0L) {
  stop(
    "No boundary_or_nonwald_status rows found in the source pregrid artifact.",
    call. = FALSE
  )
}

profile_row_from_ci <- function(ci, parameter) {
  if (is.null(ci) || !is.data.frame(ci) || !"parm" %in% names(ci)) {
    return(NULL)
  }
  hit <- which(ci$parm == parameter)
  if (length(hit) == 0L) {
    return(NULL)
  }
  ci[hit[[1L]], , drop = FALSE]
}

run_boundary_profile <- function(row) {
  provider <- row$provider[[1L]]
  spec <- provider_specs[[provider]]
  warnings <- character()
  started <- proc.time()[["elapsed"]]
  dat <- tryCatch(
    withCallingHandlers(
      spec$dgp(
        spec$condition,
        seed = as.integer(row$seed[[1L]]),
        cell_id = sprintf("gaussian_mu_slope_boundary_profile_%s", provider),
        replicate = as.integer(row$replicate_index[[1L]])
      ),
      warning = function(w) {
        warnings <<- c(warnings, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    ),
    error = function(e) e
  )
  fit <- NULL
  fit_error <- NA_character_
  if (inherits(dat, "error")) {
    fit_error <- conditionMessage(dat)
  } else {
    fit <- tryCatch(
      withCallingHandlers(
        spec$fit(dat, spec$condition),
        warning = function(w) {
          warnings <<- c(warnings, conditionMessage(w))
          invokeRestart("muffleWarning")
        }
      ),
      error = function(e) e
    )
    if (inherits(fit, "error")) {
      fit_error <- conditionMessage(fit)
      fit <- NULL
    }
  }

  profile_ci <- NULL
  profile_error <- NA_character_
  if (!is.null(fit)) {
    profile_ci <- tryCatch(
      withCallingHandlers(
        confint(
          fit,
          parm = row$parameter[[1L]],
          method = "profile",
          profile_engine = "endpoint",
          profile_endpoint_max_eval = profile_endpoint_max_eval
        ),
        warning = function(w) {
          warnings <<- c(warnings, conditionMessage(w))
          invokeRestart("muffleWarning")
        }
      ),
      error = function(e) e
    )
    if (inherits(profile_ci, "error")) {
      profile_error <- conditionMessage(profile_ci)
      profile_ci <- NULL
    }
  }

  profile_row <- profile_row_from_ci(profile_ci, row$parameter[[1L]])
  lower <- if (is.null(profile_row)) NA_real_ else profile_row$lower[[1L]]
  upper <- if (is.null(profile_row)) NA_real_ else profile_row$upper[[1L]]
  status <- if (is.null(profile_row)) {
    if (!is.na(profile_error)) "profile_error" else "profile_target_missing"
  } else {
    profile_row$conf.status[[1L]]
  }
  message <- if (is.null(profile_row)) {
    profile_error %||% fit_error %||% status
  } else {
    profile_row$profile.message[[1L]] %||% status
  }
  fit_ok <- !is.null(fit)
  converged <- fit_ok && isTRUE(fit$opt$convergence == 0)
  pdhess <- fit_ok && isTRUE(fit$sdr$pdHess)
  finite_interval <- identical(status, "profile") &&
    is.finite(lower) &&
    is.finite(upper)
  truth <- as.numeric(row$truth[[1L]])
  covered <- finite_interval && lower <= truth && truth <= upper
  verdict <- if (!fit_ok) {
    "fit_failed_before_profile"
  } else if (!converged) {
    "nonconverged_fit_before_profile"
  } else if (!pdhess) {
    "non_pdhess_fit_before_profile"
  } else if (finite_interval && covered) {
    "profile_rescued_boundary_covered"
  } else if (finite_interval && truth < lower) {
    "profile_finite_lower_miss"
  } else if (finite_interval && truth > upper) {
    "profile_finite_upper_miss"
  } else {
    "profile_failed_or_nonfinite_boundary"
  }

  data.frame(
    diagnostic_id = paste(
      "gaussian_mu_slope_boundary_profile",
      provider,
      row$endpoint_member[[1L]],
      row$replicate_index[[1L]],
      sep = "_"
    ),
    cell_id = row$cell_id,
    provider = provider,
    endpoint_member = row$endpoint_member,
    replicate_index = row$replicate_index,
    seed = row$seed,
    parameter = row$parameter,
    truth = row$truth,
    wald_estimate = row$estimate,
    wald_conf_low = row$conf.low,
    wald_conf_high = row$conf.high,
    wald_conf_status = row$conf.status,
    wald_interval_status = row$interval_status,
    fit_ok = fit_ok,
    converged = converged,
    pdHess = pdhess,
    profile_ok = !is.null(profile_row),
    profile_conf_status = status,
    profile_lower = lower,
    profile_upper = upper,
    profile_level = if (is.null(profile_row)) {
      NA_real_
    } else {
      profile_row$level[[1L]]
    },
    profile_finite_interval = finite_interval,
    profile_covered = covered,
    profile_lower_miss = finite_interval && truth < lower,
    profile_upper_miss = finite_interval && truth > upper,
    profile_message = message,
    warning_count = length(warnings),
    warnings = paste(unique(warnings), collapse = " | "),
    fit_error = fit_error,
    profile_error = profile_error,
    elapsed = proc.time()[["elapsed"]] - started,
    diagnostic_verdict = verdict,
    stringsAsFactors = FALSE
  )
}

details <- do.call(
  rbind,
  lapply(seq_len(nrow(boundary_rows)), function(i) {
    run_boundary_profile(boundary_rows[i, , drop = FALSE])
  })
)
row.names(details) <- NULL

status_counts <- function(x) {
  counts <- sort(table(x), decreasing = TRUE)
  paste(paste(names(counts), as.integer(counts), sep = "="), collapse = "; ")
}

first_examples <- function(x, n = 2L) {
  x <- unique(clean_text(x))
  x <- x[!is.na(x) & nzchar(x) & x != "NA"]
  if (length(x) == 0L) {
    return("none")
  }
  paste(utils::head(x, n), collapse = " | ")
}

summary_rows <- do.call(
  rbind,
  lapply(split(details, details$cell_id), function(x) {
    provider <- x$provider[[1L]]
    n_finite <- sum(x$profile_finite_interval)
    n_failed <- sum(!x$profile_finite_interval)
    verdict <- if (n_finite == 0L) {
      "boundary_profile_failed_all"
    } else if (n_failed > 0L) {
      "boundary_profile_partial_rescue_still_blocked"
    } else if (all(x$profile_covered)) {
      "boundary_profile_rescued_all_but_sr150_mcse_still_blocks"
    } else {
      "boundary_profile_finite_miss_still_blocked"
    }
    inference_signal <- if (n_finite == 0L) {
      "not_inference_ready_boundary_profile_failed_all"
    } else if (sum(x$profile_upper_miss) > 0L || n_failed > 0L) {
      "not_inference_ready_boundary_profile_upper_miss_or_failure"
    } else {
      "not_inference_ready_boundary_profile_rescue_needs_retained_coverage_topup"
    }
    next_gate <- if (sum(x$profile_upper_miss) > 0L || n_failed > 0L) {
      "Do not top up or promote this row until boundary-profile upper misses and remaining profile failures are resolved, then rerun retained coverage with MCSE <= 0.01."
    } else {
      "Do not promote this row until retained coverage is rerun with MCSE <= 0.01 and one-sided misses pass the row-specific gate."
    }
    data.frame(
      diagnostic_id = paste0("gaussian_mu_slope_boundary_profile_", provider),
      cell_id = x$cell_id[[1L]],
      provider = provider,
      n_boundary_rows = nrow(x),
      n_profile_attempted = nrow(x),
      n_profile_converged_fit = sum(x$converged),
      n_profile_pdhess_fit = sum(x$pdHess),
      n_profile_confint_ok = sum(x$profile_ok),
      n_profile_finite_interval = n_finite,
      n_profile_failed = n_failed,
      n_profile_covered = sum(x$profile_covered),
      n_profile_lower_miss = sum(x$profile_lower_miss),
      n_profile_upper_miss = sum(x$profile_upper_miss),
      profile_status_counts = status_counts(x$profile_conf_status),
      profile_verdict_counts = status_counts(x$diagnostic_verdict),
      profile_message_examples = first_examples(x$profile_message),
      diagnostic_verdict = verdict,
      widget_state = "mu_slope_boundary_profile_blocked",
      stability_signal = "profile_endpoint_attempted_for_sr150_boundary_rows",
      inference_signal = inference_signal,
      linked_fit_status = "point_fit",
      linked_interval_status = "planned",
      linked_coverage_status = "planned",
      promotion_decision = "do_not_promote",
      evidence_url = "docs/dev-log/after-task/2026-06-29-q-series-gaussian-mu-slope-boundary-profile-diagnostic.md",
      artifact_dir = "docs/dev-log/simulation-artifacts/2026-06-29-gaussian-mu-slope-boundary-profile-diagnostic-local",
      claim_boundary = clean_text(paste(
        provider_label[[provider]],
        "Gaussian q1 mu one-slope boundary profile diagnostic only;",
        provider_boundary[[provider]],
        "SR150 pregrid rows remain planned/planned with no MCSE-qualified coverage,",
        "inference_ready, supported, q2/q4/q8, sigma, non-Gaussian, REML,",
        "AI-REML, broad bridge support, or public support promoted."
      )),
      next_gate = next_gate,
      stringsAsFactors = FALSE
    )
  })
)
row.names(summary_rows) <- NULL

write_tsv(details, detail_path)
write_tsv(summary_rows, summary_path)
if (write_dashboard) {
  write_tsv(summary_rows, dashboard_path)
}

run_log <- data.frame(
  artifact = c(
    "source_replicates",
    "detail",
    "summary",
    "dashboard_summary"
  ),
  path = c(
    source_replicate_path,
    detail_path,
    summary_path,
    if (write_dashboard) dashboard_path else "not_written"
  ),
  rows = c(
    nrow(source_replicates),
    nrow(details),
    nrow(summary_rows),
    if (write_dashboard) nrow(summary_rows) else 0L
  ),
  stringsAsFactors = FALSE
)
run_log$path <- sub(
  paste0("^", gsub("([\\W])", "\\\\\\1", repo_root), "/?"),
  "",
  run_log$path
)
write_tsv(run_log, run_log_path)
capture.output(utils::sessionInfo(), file = session_info_path)
old_wd <- setwd(repo_root)
on.exit(setwd(old_wd), add = TRUE)
git_sha <- tryCatch(
  system2("git", c("rev-parse", "HEAD"), stdout = TRUE, stderr = TRUE),
  error = function(e) conditionMessage(e)
)
writeLines(git_sha, git_sha_path)

cat("wrote ", detail_path, " with ", nrow(details), " rows\n", sep = "")
cat("wrote ", summary_path, " with ", nrow(summary_rows), " rows\n", sep = "")
if (write_dashboard) {
  cat(
    "wrote ",
    dashboard_path,
    " with ",
    nrow(summary_rows),
    " rows\n",
    sep = ""
  )
}
