#!/usr/bin/env Rscript
#
# Small q4 animal numerical-geometry diagnostic.
#
# This runner reruns a few selected animal q4 all-four one-slope seeds and
# records optimizer, gradient, cov.fixed, theta, direct-SD, and derived-
# correlation geometry. It is diagnostic evidence only: interval coverage,
# inference_ready, supported, q8, REML, AI-REML, and broad bridge support are out
# of scope.

`%||%` <- function(x, y) if (is.null(x)) y else x

args <- commandArgs(trailingOnly = TRUE)
if (any(args %in% c("--help", "-h"))) {
  cat(
    paste(
      "Usage: Rscript tools/run-structured-re-q4-animal-numerical-geometry-diagnostic.R [options]",
      "",
      "Options:",
      "  --replicates=a,b          Replicate indices (default: 910101,910102,910107,910110).",
      "  --seed-base=N             Seed base; seed = seed_base + replicate + variant offset (default: 910000).",
      "  --variant=NAME            Variant to run: strong or more_levels (default: more_levels).",
      "  --output-dir=PATH         Artifact directory; --out-dir is accepted as an alias.",
      "  --overwrite=true          Replace an existing artifact directory.",
      "  --write-dashboard=false   Do not overwrite the dashboard sidecar.",
      "",
      "This is diagnostic evidence only. It does not promote q4/q8 interval",
      "coverage, inference_ready, supported, REML, AI-REML, or bridge support.",
      sep = "\n"
    ),
    "\n"
  )
  quit(status = 0L)
}

arg_value <- function(name, default = NULL) {
  dashed <- paste0("--", name, "=")
  underscored <- gsub("-", "_", dashed, fixed = TRUE)
  hit <- c(
    grep(paste0("^", dashed), args, value = TRUE),
    grep(paste0("^", underscored), args, value = TRUE)
  )
  if (!length(hit)) {
    return(default)
  }
  sub("^[^=]+=", "", hit[[length(hit)]])
}

arg_flag <- function(name, default = FALSE) {
  value <- arg_value(name, NULL)
  if (any(args %in% paste0("--", name))) {
    return(TRUE)
  }
  if (is.null(value)) {
    return(default)
  }
  tolower(value) %in% c("1", "true", "yes", "y")
}

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
    file = path,
    sep = "\t",
    quote = FALSE,
    row.names = FALSE,
    na = "NA"
  )
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

replicate_arg <- strsplit(
  arg_value("replicates", "910101,910102,910107,910110"),
  ",",
  fixed = TRUE
)[[1L]]
replicate_indices <- as.integer(trimws(replicate_arg[nzchar(trimws(
  replicate_arg
))]))
if (!length(replicate_indices) || any(!is.finite(replicate_indices))) {
  stop("`--replicates` must be a comma-separated integer list.", call. = FALSE)
}
seed_base <- as.integer(arg_value("seed-base", "910000"))
if (!is.finite(seed_base) || seed_base < 1L) {
  stop("`--seed-base` must be a positive integer.", call. = FALSE)
}
variant <- arg_value("variant", "more_levels")
overwrite <- arg_flag("overwrite", FALSE)
write_dashboard <- arg_flag("write-dashboard", TRUE)

default_artifact_dir <- file.path(
  repo_root,
  "docs",
  "dev-log",
  "simulation-artifacts",
  "2026-06-29-q4-animal-numerical-geometry-local"
)
artifact_dir_arg <- arg_value(
  "output-dir",
  arg_value("out-dir", default_artifact_dir)
)
artifact_dir <- normalizePath(artifact_dir_arg, mustWork = FALSE)
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
dashboard_path <- file.path(
  dashboard_dir,
  "structured-re-q4-animal-numerical-geometry-diagnostic.tsv"
)
artifact_path <- file.path(
  artifact_dir,
  "structured-re-q4-animal-numerical-geometry-diagnostic.tsv"
)
attempt_path <- file.path(
  artifact_dir,
  "structured-re-q4-animal-numerical-geometry-attempts.tsv"
)
run_log_path <- file.path(
  artifact_dir,
  "structured-re-q4-animal-numerical-geometry-run-log.tsv"
)
session_info_path <- file.path(artifact_dir, "sessionInfo.txt")
git_sha_path <- file.path(artifact_dir, "git-sha.txt")

load_result <- tryCatch(
  {
    suppressPackageStartupMessages(devtools::load_all(repo_root, quiet = TRUE))
    list(
      ok = TRUE,
      status = "devtools_load_all",
      detail = "loaded current source with devtools::load_all"
    )
  },
  error = function(e) {
    list(
      ok = FALSE,
      status = "devtools_load_all_failed",
      detail = clean_text(conditionMessage(e))
    )
  }
)
if (!isTRUE(load_result$ok)) {
  stop(load_result$detail, call. = FALSE)
}

source_q4_stability_prefix <- function() {
  runner <- file.path(
    repo_root,
    "tools",
    "run-structured-re-q4-slope-interval-stability-probe.R"
  )
  src <- readLines(runner, warn = FALSE)
  src <- src[!grepl("^devtools::load_all\\(", src)]
  main_line <- grep("^plan\\s*<-\\s*utils::read.delim", src)[1L]
  if (!is.finite(main_line)) {
    stop("Could not find q4 stability probe main entrypoint.", call. = FALSE)
  }
  tmp <- tempfile(fileext = ".R")
  writeLines(src[seq_len(main_line - 1L)], tmp)
  source(tmp, local = .GlobalEnv)
  invisible(TRUE)
}
source_q4_stability_prefix()
artifact_dir <- normalizePath(artifact_dir_arg, mustWork = FALSE)
dashboard_path <- file.path(
  dashboard_dir,
  "structured-re-q4-animal-numerical-geometry-diagnostic.tsv"
)
artifact_path <- file.path(
  artifact_dir,
  "structured-re-q4-animal-numerical-geometry-diagnostic.tsv"
)
attempt_path <- file.path(
  artifact_dir,
  "structured-re-q4-animal-numerical-geometry-attempts.tsv"
)
run_log_path <- file.path(
  artifact_dir,
  "structured-re-q4-animal-numerical-geometry-run-log.tsv"
)
session_info_path <- file.path(artifact_dir, "sessionInfo.txt")
git_sha_path <- file.path(artifact_dir, "git-sha.txt")

q4_variants <- list(
  strong = list(
    seed_offset = 0L,
    n = 8L,
    n_each = 24L,
    sds = c(
      mu1_intercept = 0.70,
      mu1_x = 0.48,
      mu2_intercept = 0.62,
      mu2_x = 0.44,
      sigma1_intercept = 0.50,
      sigma1_x = 0.34,
      sigma2_intercept = 0.46,
      sigma2_x = 0.30
    )
  ),
  more_levels = list(
    seed_offset = 100000L,
    n = 16L,
    n_each = 12L,
    sds = c(
      mu1_intercept = 0.62,
      mu1_x = 0.42,
      mu2_intercept = 0.56,
      mu2_x = 0.38,
      sigma1_intercept = 0.42,
      sigma1_x = 0.28,
      sigma2_intercept = 0.40,
      sigma2_x = 0.26
    )
  )
)
if (!variant %in% names(q4_variants)) {
  stop("`--variant` must be `strong` or `more_levels`.", call. = FALSE)
}
spec <- q4_variants[[variant]]

format_num <- function(x, digits = 8L) {
  if (!is.finite(x)) {
    return("NA")
  }
  formatC(x, digits = digits, format = "fg", flag = "#")
}

format_vector <- function(x, digits = 8L) {
  x <- as.numeric(x)
  x <- x[is.finite(x)]
  if (!length(x)) {
    return("NA")
  }
  paste(vapply(x, format_num, character(1L), digits = digits), collapse = ";")
}

safe_eigenvalues <- function(cov_fixed) {
  if (is.null(cov_fixed) || !length(cov_fixed) || !all(is.finite(cov_fixed))) {
    return(NULL)
  }
  tryCatch(
    eigen(cov_fixed, symmetric = TRUE, only.values = TRUE)$values,
    error = function(e) NULL
  )
}

matrix_eigenvalues <- function(x) {
  if (is.null(x) || !length(x)) {
    return(NULL)
  }
  mat <- tryCatch(as.matrix(x), error = function(e) NULL)
  if (is.null(mat) || length(dim(mat)) != 2L || nrow(mat) != ncol(mat)) {
    return(NULL)
  }
  if (!all(is.finite(mat))) {
    return(NULL)
  }
  tryCatch(
    eigen(mat, symmetric = TRUE, only.values = TRUE)$values,
    error = function(e) NULL
  )
}

matrix_offdiag <- function(x) {
  if (is.null(x) || !length(x)) {
    return(numeric())
  }
  mat <- tryCatch(as.matrix(x), error = function(e) NULL)
  if (is.null(mat) || length(dim(mat)) != 2L || nrow(mat) != ncol(mat)) {
    return(numeric())
  }
  mat[row(mat) != col(mat)]
}

log10_condition <- function(values) {
  values <- abs(values)
  values <- values[is.finite(values) & values > 0]
  if (!length(values)) {
    return(NA_real_)
  }
  log10(max(values) / min(values))
}

geometry_status <- function(fit_ok, pdhess, max_gradient, n_nonpositive) {
  if (!is.finite(max_gradient)) {
    max_gradient <- Inf
  }
  if (!is.finite(n_nonpositive)) {
    n_nonpositive <- 0L
  }
  if (!isTRUE(fit_ok)) {
    return("fit_not_ok")
  }
  if (!isTRUE(pdhess) && n_nonpositive > 0L && max_gradient > 1e-3) {
    return("gradient_covfixed_eigen_blocked")
  }
  if (!isTRUE(pdhess) && n_nonpositive > 0L) {
    return("covfixed_eigen_blocked")
  }
  if (!isTRUE(pdhess)) {
    return("pdhess_false_other")
  }
  if (max_gradient > 1e-3) {
    return("pdhess_true_gradient_watch")
  }
  "pdhess_pass_smoke"
}

claim_boundary_text <- paste(
  "Animal q4 all-four one-slope numerical-geometry diagnostic only:",
  "selected seeds compare pdHess false and pdHess true fits;",
  "no coverage, no inference_ready, no supported, no q8 inference,",
  "no q4 REML, no REML, no AI-REML, no broad q4 bridge support,",
  "and no derived-correlation interval claim."
)
next_gate_text <- paste(
  "Use these fields to decide whether q8-shaped Hessian/correlation geometry",
  "needs a parameter-transform or optimizer-start experiment before any q4",
  "coverage-grid design; Fisher/Rose must approve denominator policy before",
  "any status edit."
)

diagnostic_rows <- list()
attempt_rows <- list()
for (replicate_index in replicate_indices) {
  seed <- seed_base + replicate_index + spec$seed_offset
  warnings <- character()
  message(
    "Fitting animal q4 numerical-geometry replicate ",
    replicate_index,
    " (",
    variant,
    ", seed ",
    seed,
    ")"
  )
  sim <- make_provider_data(
    "animal",
    seed = seed,
    n = spec$n,
    n_each = spec$n_each,
    sds = spec$sds
  )
  fit <- withCallingHandlers(
    tryCatch(fit_provider("animal", sim), error = function(e) e),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  fit_error <- inherits(fit, "error")
  convergence <- if (fit_error) NA_integer_ else fit$opt$convergence
  fit_ok <- !fit_error && identical(convergence, 0L)
  pdhess <- !fit_error && isTRUE(fit$sdr$pdHess)
  loglik <- if (fit_error) {
    NA_real_
  } else {
    tryCatch(as.numeric(stats::logLik(fit)), error = function(e) NA_real_)
  }
  gradient <- if (fit_error) {
    numeric()
  } else {
    fit$sdr$gradient.fixed %||%
      tryCatch(fit$obj$gr(fit$opt$par), error = function(e) numeric())
  }
  max_gradient <- if (length(gradient)) {
    max(abs(gradient), na.rm = TRUE)
  } else {
    NA_real_
  }
  max_gradient_index <- if (length(gradient)) {
    which.max(abs(gradient))
  } else {
    NA_integer_
  }
  max_gradient_parameter <- if (length(gradient) && length(names(gradient))) {
    names(gradient)[[max_gradient_index]]
  } else {
    "NA"
  }
  cov_fixed <- if (fit_error) NULL else fit$sdr$cov.fixed
  cov_total <- if (is.null(cov_fixed)) 0L else length(cov_fixed)
  cov_finite <- if (is.null(cov_fixed)) 0L else sum(is.finite(cov_fixed))
  cov_dim <- if (is.null(cov_fixed)) {
    "NA"
  } else {
    paste(dim(cov_fixed), collapse = "x")
  }
  cov_fixed_eigen <- safe_eigenvalues(cov_fixed)
  n_nonpositive <- if (is.null(cov_fixed_eigen)) {
    NA_integer_
  } else {
    sum(cov_fixed_eigen <= 0)
  }
  abs_eigen <- if (is.null(cov_fixed_eigen)) numeric() else abs(cov_fixed_eigen)
  nonzero_abs_eigen <- abs_eigen[abs_eigen > 0]
  condition_abs <- if (length(nonzero_abs_eigen)) {
    max(nonzero_abs_eigen) / min(nonzero_abs_eigen)
  } else {
    NA_real_
  }
  par_fixed <- if (fit_error) numeric() else fit$sdr$par.fixed
  report <- if (fit_error) {
    list()
  } else {
    tryCatch(fit$obj$report(), error = function(e) list())
  }
  theta <- as.numeric(
    report$theta_phylo %||% par_fixed[grepl("^theta_", names(par_fixed))]
  )
  log_sd <- as.numeric(
    report$log_sd_phylo %||% par_fixed[grepl("^log_sd_", names(par_fixed))]
  )
  corr_matrix <- report$phylo_q4_corr %||% NULL
  cov_matrix <- report$phylo_q4_covariance %||% NULL
  corr_values <- matrix_offdiag(corr_matrix)
  corr_eigen <- matrix_eigenvalues(corr_matrix)
  q4_cov_eigen <- matrix_eigenvalues(cov_matrix)
  q_phylo <- if (is.null(corr_matrix)) {
    length(log_sd)
  } else {
    nrow(as.matrix(corr_matrix))
  }
  phylo_mu_n_blocks <- if (is.null(corr_matrix)) {
    NA_integer_
  } else {
    1L
  }
  direct_sd <- if (fit_error) {
    numeric()
  } else {
    as.numeric(report$sd_phylo %||% unlist(fit$sdpars, use.names = TRUE))
  }
  correlations <- if (fit_error) {
    numeric()
  } else {
    as.numeric(corr_values %||% unlist(fit$corpars, use.names = TRUE))
  }
  optimizer_used <- if (fit_error) list() else fit$optimizer_used
  optimizer_attempts <- if (fit_error) data.frame() else fit$optimizer_attempts
  if (nrow(optimizer_attempts)) {
    best_attempt_objective <- min(optimizer_attempts$objective, na.rm = TRUE)
    selected_objective <- optimizer_used$objective %||% NA_real_
    selected_objective_delta_from_best <- selected_objective -
      best_attempt_objective
    selected_worse_than_best <- is.finite(selected_objective_delta_from_best) &&
      selected_objective_delta_from_best > 1e-3
    for (attempt_i in seq_len(nrow(optimizer_attempts))) {
      attempt <- optimizer_attempts[attempt_i, , drop = FALSE]
      attempt_objective_delta <- attempt$objective[[1L]] -
        best_attempt_objective
      attempt_rows[[length(attempt_rows) + 1L]] <- data.frame(
        seed = seed,
        replicate_index = replicate_index,
        attempt = attempt$attempt[[1L]],
        optimizer = attempt$optimizer[[1L]],
        optimizer_preset = attempt$optimizer_preset[[1L]],
        status = attempt$status[[1L]],
        convergence = attempt$convergence[[1L]],
        message = attempt$message[[1L]],
        objective = format_num(attempt$objective[[1L]], digits = 10L),
        elapsed_sec = format_num(attempt$elapsed_sec[[1L]], digits = 8L),
        selected = attempt$selected[[1L]],
        control = clean_text(paste(
          unlist(attempt$control[[1L]]),
          collapse = ","
        )),
        objective_delta_from_best = format_num(
          attempt_objective_delta,
          digits = 10L
        ),
        stringsAsFactors = FALSE
      )
    }
  } else {
    best_attempt_objective <- NA_real_
    selected_objective <- NA_real_
    selected_objective_delta_from_best <- NA_real_
    selected_worse_than_best <- FALSE
  }
  status <- geometry_status(
    fit_ok,
    pdhess,
    max_gradient %||% Inf,
    n_nonpositive %||% 0L
  )

  diagnostic_rows[[length(diagnostic_rows) + 1L]] <- data.frame(
    diagnostic_id = paste0("q4_animal_numerical_geometry_", replicate_index),
    cell_id = "qseries_animal_q4_all_four_one_slope_planned",
    variant = variant,
    replicate_index = replicate_index,
    seed = seed,
    n_levels = spec$n,
    n_each = spec$n_each,
    q_phylo = q_phylo,
    phylo_mu_n_blocks = phylo_mu_n_blocks,
    fit_ok = fit_ok,
    convergence = convergence,
    pdHess = pdhess,
    logLik = format_num(loglik),
    objective = format_num(
      if (fit_error) NA_real_ else fit$opt$objective,
      digits = 10L
    ),
    optimizer_selected = optimizer_used$optimizer %||% "NA",
    optimizer_selected_preset = optimizer_used$optimizer_preset %||% "NA",
    selected_attempt = optimizer_used$attempt %||% NA_integer_,
    optimizer_attempt_count = nrow(optimizer_attempts),
    fallback_selected = isTRUE(optimizer_used$retried),
    best_attempt_objective = format_num(best_attempt_objective, digits = 10L),
    selected_objective_delta_from_best = format_num(
      selected_objective_delta_from_best,
      digits = 10L
    ),
    selected_worse_than_best = selected_worse_than_best,
    optimizer_attempt_statuses = paste(
      optimizer_attempts$status,
      collapse = ";"
    ),
    optimizer_attempt_convergences = paste(
      optimizer_attempts$convergence,
      collapse = ";"
    ),
    warning_count = length(warnings),
    warning_messages = clean_text(paste(unique(warnings), collapse = " | ")),
    max_abs_gradient_fixed = format_num(max_gradient, digits = 8L),
    max_gradient_parameter = max_gradient_parameter,
    max_gradient_index = max_gradient_index,
    sdreport_status = if (pdhess) "pdHess_true" else "pdHess_false",
    sdreport_message = if (pdhess) {
      "positive definite Hessian"
    } else {
      "non-positive definite Hessian"
    },
    log_sd_min = format_num(if (length(log_sd)) min(log_sd) else NA_real_),
    log_sd_median = format_num(
      if (length(log_sd)) stats::median(log_sd) else NA_real_
    ),
    log_sd_max = format_num(if (length(log_sd)) max(log_sd) else NA_real_),
    sd_min = format_num(if (length(direct_sd)) min(direct_sd) else NA_real_),
    sd_median = format_num(
      if (length(direct_sd)) stats::median(direct_sd) else NA_real_
    ),
    sd_max = format_num(if (length(direct_sd)) max(direct_sd) else NA_real_),
    theta_abs_median = format_num(
      if (length(theta)) stats::median(abs(theta)) else NA_real_
    ),
    theta_abs_q90 = format_num(
      if (length(theta)) unname(stats::quantile(abs(theta), 0.90)) else NA_real_
    ),
    theta_abs_q95 = format_num(
      if (length(theta)) unname(stats::quantile(abs(theta), 0.95)) else NA_real_
    ),
    cov_fixed_status = if (is.null(cov_fixed_eigen)) {
      "unavailable"
    } else {
      "eigen_ok"
    },
    cov_fixed_dim = cov_dim,
    cov_fixed_finite_count = cov_finite,
    cov_fixed_total = cov_total,
    min_cov_fixed_eigenvalue = format_num(
      if (is.null(cov_fixed_eigen)) NA_real_ else min(cov_fixed_eigen),
      digits = 8L
    ),
    max_cov_fixed_eigenvalue = format_num(
      if (is.null(cov_fixed_eigen)) NA_real_ else max(cov_fixed_eigen),
      digits = 8L
    ),
    n_cov_fixed_nonpositive_eigenvalues = n_nonpositive,
    cov_fixed_condition_abs = format_num(condition_abs, digits = 8L),
    theta_count = length(theta),
    theta_max_abs = format_num(
      if (length(theta)) max(abs(theta)) else NA_real_,
      digits = 8L
    ),
    n_theta_abs_gt_10 = sum(abs(theta) > 10),
    n_theta_abs_gt_50 = sum(abs(theta) > 50),
    n_theta_abs_gt_100 = sum(abs(theta) > 100),
    theta_abs_gt_3 = sum(abs(theta) > 3),
    theta_abs_gt_5 = sum(abs(theta) > 5),
    log_sd_count = length(log_sd),
    min_direct_sd_estimate = format_num(
      if (length(direct_sd)) min(direct_sd) else NA_real_,
      digits = 8L
    ),
    max_direct_sd_estimate = format_num(
      if (length(direct_sd)) max(direct_sd) else NA_real_,
      digits = 8L
    ),
    n_direct_sd_lt_0_10 = sum(direct_sd < 0.10),
    n_direct_sd_lt_0_20 = sum(direct_sd < 0.20),
    cor_count = length(correlations),
    max_abs_derived_correlation = format_num(
      if (length(correlations)) max(abs(correlations)) else NA_real_,
      digits = 8L
    ),
    corr_abs_offdiag_max = format_num(
      if (length(corr_values)) max(abs(corr_values)) else NA_real_,
      digits = 8L
    ),
    corr_abs_offdiag_q95 = format_num(
      if (length(corr_values)) {
        unname(stats::quantile(abs(corr_values), 0.95))
      } else {
        NA_real_
      },
      digits = 8L
    ),
    n_abs_corr_gt_0_9 = sum(abs(correlations) > 0.9),
    n_abs_derived_correlation_gt_0_95 = sum(abs(correlations) > 0.95),
    n_abs_derived_correlation_gt_0_99 = sum(abs(correlations) > 0.99),
    corr_eig_min = format_num(
      if (is.null(corr_eigen)) NA_real_ else min(corr_eigen)
    ),
    corr_eig_max = format_num(
      if (is.null(corr_eigen)) NA_real_ else max(corr_eigen)
    ),
    corr_log10_condition = format_num(log10_condition(corr_eigen)),
    cov_eig_min = format_num(
      if (is.null(q4_cov_eigen)) NA_real_ else min(q4_cov_eigen)
    ),
    cov_eig_max = format_num(
      if (is.null(q4_cov_eigen)) NA_real_ else max(q4_cov_eigen)
    ),
    cov_log10_condition = format_num(log10_condition(q4_cov_eigen)),
    sdr_cov_fixed_eig_min = format_num(
      if (is.null(cov_fixed_eigen)) NA_real_ else min(cov_fixed_eigen),
      digits = 8L
    ),
    sdr_cov_fixed_eig_max = format_num(
      if (is.null(cov_fixed_eigen)) NA_real_ else max(cov_fixed_eigen),
      digits = 8L
    ),
    sdr_cov_fixed_n_negative = if (is.null(cov_fixed_eigen)) {
      NA_integer_
    } else {
      sum(cov_fixed_eigen < 0)
    },
    sdr_cov_fixed_n_near_zero = if (is.null(cov_fixed_eigen)) {
      NA_integer_
    } else {
      sum(abs(cov_fixed_eigen) < 1e-8)
    },
    diag_cov_random_min = format_num(
      if (!fit_error && length(fit$sdr$diag.cov.random)) {
        min(fit$sdr$diag.cov.random, na.rm = TRUE)
      } else {
        NA_real_
      },
      digits = 8L
    ),
    diag_cov_random_max = format_num(
      if (!fit_error && length(fit$sdr$diag.cov.random)) {
        max(fit$sdr$diag.cov.random, na.rm = TRUE)
      } else {
        NA_real_
      },
      digits = 8L
    ),
    diag_cov_random_n_nonpositive = if (
      !fit_error && length(fit$sdr$diag.cov.random)
    ) {
      sum(fit$sdr$diag.cov.random <= 0, na.rm = TRUE)
    } else {
      NA_integer_
    },
    quadratic_phylo = format_vector(report$quadratic_phylo %||% NA_real_),
    geometry_status = status,
    interval_claim_status = "diagnostic_only",
    coverage_status = "not_evaluable",
    source_artifact = paste(
      "docs/dev-log/simulation-artifacts",
      basename(artifact_dir),
      "structured-re-q4-animal-numerical-geometry-diagnostic.tsv",
      sep = "/"
    ),
    evidence_url = "docs/dev-log/after-task/2026-06-29-q-series-q4-animal-numerical-geometry-diagnostic.md",
    claim_boundary = claim_boundary_text,
    next_gate = next_gate_text,
    stringsAsFactors = FALSE
  )
}

diagnostic_out <- do.call(rbind, diagnostic_rows)
attempt_out <- if (length(attempt_rows)) {
  do.call(rbind, attempt_rows)
} else {
  data.frame()
}
run_log <- data.frame(
  log_id = "q4_animal_numerical_geometry_diagnostic",
  timestamp_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
  replicates = paste(replicate_indices, collapse = ","),
  seed_base = seed_base,
  variant = variant,
  load_status = load_result$status,
  load_detail = load_result$detail,
  output_dir = artifact_dir,
  dashboard_output = if (write_dashboard) dashboard_path else "not_written",
  claim_boundary = claim_boundary_text,
  next_gate = next_gate_text,
  stringsAsFactors = FALSE
)

write_tsv(diagnostic_out, artifact_path)
if (nrow(attempt_out)) {
  write_tsv(attempt_out, attempt_path)
}
write_tsv(run_log, run_log_path)
if (write_dashboard) {
  write_tsv(diagnostic_out, dashboard_path)
  if (nrow(attempt_out)) {
    write_tsv(
      attempt_out,
      file.path(
        dashboard_dir,
        "structured-re-q4-animal-numerical-geometry-attempts.tsv"
      )
    )
  }
}

git_sha <- tryCatch(
  {
    old_wd <- setwd(repo_root)
    on.exit(setwd(old_wd), add = TRUE)
    out <- system2(
      "git",
      c("rev-parse", "HEAD"),
      stdout = TRUE,
      stderr = FALSE
    )
    if (!length(out)) "unknown" else out[[1L]]
  },
  error = function(e) "unknown"
)
writeLines(git_sha, git_sha_path)
writeLines(capture.output(sessionInfo()), session_info_path)

message("Wrote numerical geometry artifact: ", artifact_path)
if (nrow(attempt_out)) {
  message("Wrote numerical geometry attempts: ", attempt_path)
}
if (write_dashboard) {
  message("Wrote dashboard sidecar: ", dashboard_path)
}
