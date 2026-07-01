#!/usr/bin/env Rscript
#
# Small q4 animal optimizer-route diagnostic.
#
# This runner compares a few optimizer routes on selected animal q4 all-four
# one-slope seeds. It is diagnostic evidence only: interval coverage,
# inference_ready, supported, q8, REML, AI-REML, and broad bridge support are out
# of scope.

`%||%` <- function(x, y) if (is.null(x)) y else x

args <- commandArgs(trailingOnly = TRUE)
if (any(args %in% c("--help", "-h"))) {
  cat(
    paste(
      "Usage: Rscript tools/run-structured-re-q4-animal-optimizer-route-diagnostic.R [options]",
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
  "2026-06-29-q4-animal-optimizer-route-local"
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
  "structured-re-q4-animal-optimizer-route-diagnostic.tsv"
)
artifact_path <- file.path(
  artifact_dir,
  "structured-re-q4-animal-optimizer-route-diagnostic.tsv"
)
run_log_path <- file.path(
  artifact_dir,
  "structured-re-q4-animal-optimizer-route-run-log.tsv"
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
  "structured-re-q4-animal-optimizer-route-diagnostic.tsv"
)
artifact_path <- file.path(
  artifact_dir,
  "structured-re-q4-animal-optimizer-route-diagnostic.tsv"
)
run_log_path <- file.path(
  artifact_dir,
  "structured-re-q4-animal-optimizer-route-run-log.tsv"
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

log10_condition <- function(values) {
  values <- abs(values)
  values <- values[is.finite(values) & values > 0]
  if (!length(values)) {
    return(NA_real_)
  }
  log10(max(values) / min(values))
}

fit_animal_control <- function(sim, control) {
  A <- sim$A
  form <- bf(
    mu1 = y1 ~ x + animal(1 + x | p | id, A = A),
    mu2 = y2 ~ x + animal(1 + x | p | id, A = A),
    sigma1 = ~ z + animal(1 + x | p | id, A = A),
    sigma2 = ~ z + animal(1 + x | p | id, A = A),
    rho12 = ~1
  )
  warnings <- character()
  fit <- withCallingHandlers(
    tryCatch(
      drmTMB(
        form,
        family = biv_gaussian(),
        data = sim$data,
        control = control
      ),
      error = function(e) e
    ),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  list(fit = fit, warnings = warnings)
}

route_control <- list(
  custom1600_fallback = drm_control(
    fallback_optimizer = "BFGS",
    optimizer = list(eval.max = 1600, iter.max = 1600)
  ),
  ladder_no_fallback = drm_control(),
  robust_no_fallback = drm_control(optimizer_preset = "robust"),
  multistart2_no_fallback = drm_control(multi_start = 2L),
  multistart2_fallback = drm_control(
    multi_start = 2L,
    fallback_optimizer = "BFGS"
  )
)

route_description <- c(
  custom1600_fallback = "custom nlminb budget plus BFGS fallback",
  ladder_no_fallback = "default/careful/robust nlminb ladder, no fallback",
  robust_no_fallback = "robust nlminb budget only, no fallback",
  multistart2_no_fallback = "two-start nlminb ladder, no fallback",
  multistart2_fallback = "two-start nlminb ladder plus BFGS fallback"
)

claim_boundary_text <- paste(
  "Animal q4 all-four one-slope optimizer-route diagnostic only:",
  "routes compare default ladder, robust, multistart, and BFGS fallback;",
  "no coverage, no inference_ready, no supported, no q8 inference,",
  "no q4 REML, no REML, no AI-REML, no broad q4 bridge support,",
  "and no derived-correlation interval claim."
)
next_gate_text <- paste(
  "If optimizer routes do not rescue failed-Hessian seeds, design a deeper",
  "parameter-transform or staged-start-map experiment before any q4",
  "coverage-grid design; Fisher/Rose must approve denominator policy before",
  "any status edit."
)

route_geometry <- function(fit) {
  if (inherits(fit, "error")) {
    return(list(
      fit_error = TRUE,
      error_message = clean_text(conditionMessage(fit)),
      convergence = NA_integer_,
      pdHess = FALSE,
      objective = NA_real_,
      selected = "error",
      selected_attempt = NA_integer_,
      attempt_count = 0L,
      attempts = "error",
      selected_delta = NA_real_,
      selected_worse = FALSE,
      max_gradient = NA_real_,
      cov_neg = NA_integer_,
      cov_min = NA_real_,
      theta_max = NA_real_,
      corr_condition = NA_real_,
      direct_sd_min = NA_real_,
      direct_sd_max = NA_real_
    ))
  }
  attempts <- fit$optimizer_attempts
  best_objective <- if (nrow(attempts)) {
    min(attempts$objective, na.rm = TRUE)
  } else {
    NA_real_
  }
  selected_objective <- fit$optimizer_used$objective %||% NA_real_
  selected_delta <- selected_objective - best_objective
  gradient <- fit$sdr$gradient.fixed %||%
    tryCatch(fit$obj$gr(fit$opt$par), error = function(e) numeric())
  max_gradient <- if (length(gradient) && any(is.finite(gradient))) {
    max(abs(gradient), na.rm = TRUE)
  } else {
    NA_real_
  }
  cov_eig <- tryCatch(
    eigen(fit$sdr$cov.fixed, symmetric = TRUE, only.values = TRUE)$values,
    error = function(e) NULL
  )
  report <- tryCatch(fit$obj$report(), error = function(e) list())
  theta <- as.numeric(report$theta_phylo %||% numeric())
  corr_eig <- matrix_eigenvalues(report$phylo_q4_corr %||% NULL)
  direct_sd <- as.numeric(
    report$sd_phylo %||% unlist(fit$sdpars, use.names = TRUE)
  )
  list(
    fit_error = FALSE,
    error_message = "NA",
    convergence = as.integer(fit$opt$convergence),
    pdHess = isTRUE(fit$sdr$pdHess),
    objective = as.numeric(fit$opt$objective),
    selected = fit$optimizer_used$optimizer_preset %||% "NA",
    selected_attempt = fit$optimizer_used$attempt %||% NA_integer_,
    attempt_count = nrow(attempts),
    attempts = if (nrow(attempts)) {
      objective_labels <- vapply(
        attempts$objective,
        format_num,
        character(1L),
        digits = 8L
      )
      paste(
        attempts$optimizer_preset,
        attempts$convergence,
        objective_labels,
        sep = ":",
        collapse = " | "
      )
    } else {
      "NA"
    },
    selected_delta = selected_delta,
    selected_worse = is.finite(selected_delta) && selected_delta > 1e-3,
    max_gradient = max_gradient,
    cov_neg = if (is.null(cov_eig)) NA_integer_ else sum(cov_eig <= 0),
    cov_min = if (is.null(cov_eig)) NA_real_ else min(cov_eig),
    theta_max = if (length(theta)) max(abs(theta)) else NA_real_,
    corr_condition = log10_condition(corr_eig),
    direct_sd_min = if (length(direct_sd)) min(direct_sd) else NA_real_,
    direct_sd_max = if (length(direct_sd)) max(direct_sd) else NA_real_
  )
}

route_status <- function(geom) {
  if (isTRUE(geom$fit_error)) {
    return("fit_error")
  }
  if (
    isTRUE(geom$pdHess) &&
      identical(geom$convergence, 0L) &&
      is.finite(geom$max_gradient) &&
      geom$max_gradient <= 1e-3 &&
      identical(as.integer(geom$cov_neg), 0L)
  ) {
    return("pdhess_pass_smoke")
  }
  if (isTRUE(geom$selected_worse)) {
    return("selected_worse_objective_blocked")
  }
  if (
    !isTRUE(geom$pdHess) &&
      is.finite(geom$max_gradient) &&
      geom$max_gradient > 1e-3
  ) {
    return("gradient_hessian_blocked")
  }
  if (!isTRUE(geom$pdHess)) {
    return("hessian_blocked")
  }
  "route_watch"
}

rows <- list()
for (replicate_index in replicate_indices) {
  seed <- seed_base + replicate_index + spec$seed_offset
  message(
    "Running animal q4 optimizer-route replicate ",
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
  replicate_rows <- list()
  for (route in names(route_control)) {
    message("  route: ", route)
    res <- fit_animal_control(sim, route_control[[route]])
    geom <- route_geometry(res$fit)
    status <- route_status(geom)
    replicate_rows[[route]] <- data.frame(
      diagnostic_id = paste0(
        "q4_animal_optimizer_route_",
        replicate_index,
        "_",
        route
      ),
      cell_id = "qseries_animal_q4_all_four_one_slope_planned",
      variant = variant,
      replicate_index = replicate_index,
      seed = seed,
      route = route,
      route_description = route_description[[route]],
      n_levels = spec$n,
      n_each = spec$n_each,
      fit_error = geom$fit_error,
      convergence = geom$convergence,
      pdHess = geom$pdHess,
      objective = format_num(geom$objective, digits = 10L),
      optimizer_selected_preset = geom$selected,
      selected_attempt = geom$selected_attempt,
      optimizer_attempt_count = geom$attempt_count,
      optimizer_attempt_summary = geom$attempts,
      selected_objective_delta_from_best = format_num(
        geom$selected_delta,
        digits = 10L
      ),
      selected_worse_than_best = geom$selected_worse,
      warning_count = length(res$warnings),
      warning_messages = clean_text(paste(
        unique(res$warnings),
        collapse = " | "
      )),
      max_abs_gradient_fixed = format_num(geom$max_gradient, digits = 8L),
      sdr_cov_fixed_eig_min = format_num(geom$cov_min, digits = 8L),
      sdr_cov_fixed_n_negative = geom$cov_neg,
      theta_max_abs = format_num(geom$theta_max, digits = 8L),
      corr_log10_condition = format_num(geom$corr_condition, digits = 8L),
      min_direct_sd_estimate = format_num(geom$direct_sd_min, digits = 8L),
      max_direct_sd_estimate = format_num(geom$direct_sd_max, digits = 8L),
      route_status = status,
      rescue_status = "pending_replicate_comparison",
      interval_claim_status = "diagnostic_only",
      coverage_status = "not_evaluable",
      source_artifact = paste(
        "docs/dev-log/simulation-artifacts",
        basename(artifact_dir),
        "structured-re-q4-animal-optimizer-route-diagnostic.tsv",
        sep = "/"
      ),
      evidence_url = "docs/dev-log/after-task/2026-06-29-q-series-q4-animal-optimizer-route-diagnostic.md",
      claim_boundary = claim_boundary_text,
      next_gate = next_gate_text,
      stringsAsFactors = FALSE
    )
  }
  baseline_status <- replicate_rows$custom1600_fallback$route_status[[1L]]
  any_rescue <- any(vapply(
    replicate_rows,
    function(row) {
      row$route[[1L]] != "custom1600_fallback" &&
        row$route_status[[1L]] == "pdhess_pass_smoke"
    },
    logical(1L)
  ))
  for (route in names(replicate_rows)) {
    row <- replicate_rows[[route]]
    row$rescue_status <- if (baseline_status == "pdhess_pass_smoke") {
      "baseline_already_passed"
    } else if (row$route_status[[1L]] == "pdhess_pass_smoke") {
      "route_rescued_failed_baseline"
    } else if (any_rescue) {
      "not_selected_rescue"
    } else {
      "no_route_rescue"
    }
    rows[[length(rows) + 1L]] <- row
  }
}

out <- do.call(rbind, rows)
rownames(out) <- NULL
run_log <- data.frame(
  log_id = "q4_animal_optimizer_route_diagnostic",
  timestamp_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
  replicates = paste(replicate_indices, collapse = ","),
  routes = paste(names(route_control), collapse = ","),
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

write_tsv(out, artifact_path)
write_tsv(run_log, run_log_path)
if (write_dashboard) {
  write_tsv(out, dashboard_path)
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

message("Wrote optimizer-route artifact: ", artifact_path)
if (write_dashboard) {
  message("Wrote dashboard sidecar: ", dashboard_path)
}
