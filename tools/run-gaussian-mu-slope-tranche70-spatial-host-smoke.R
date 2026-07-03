#!/usr/bin/env Rscript

`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0L || is.na(x)) y else x
}

print_help <- function() {
  cat(
    paste(
      "Usage: Rscript tools/run-gaussian-mu-slope-tranche70-spatial-host-smoke.R [options]",
      "",
      "Tranche 70 fail-closed runner for the q1 mu one-slope spatial n=5 smoke.",
      "Dry-run mode validates and prints the execution manifest only. Execute",
      "mode is artifact-only and refuses unless the reviewed approval token,",
      "exact T68 source snapshot, exact T68 run root, fixed seed manifest,",
      "and write-dashboard=false boundary are all present.",
      "",
      "Options:",
      "  --mode=dry-run|execute",
      "  --provider=spatial",
      "  --target=both|mu_intercept|mu_x",
      "  --n-rep=5",
      "  --seeds=861001,861002,861003,861004,861005",
      "  --host-label=LABEL",
      "  --source-snapshot-path=PATH",
      "  --run-root-path=PATH",
      "  --output-dir=PATH",
      "  --summary-path=PATH|NA",
      "  --write-dashboard=false",
      "  --overwrite=false",
      "  --help, -h",
      "",
      "Boundary: no dashboard writes; no coverage authorization; no promotion;",
      "no support-cell status edit; no host denominator pooling.",
      sep = "\n"
    ),
    "\n"
  )
}

args <- commandArgs(trailingOnly = TRUE)
if (any(args %in% c("--help", "-h"))) {
  print_help()
  quit(status = 0L)
}

arg_value <- function(name, default = NULL) {
  eq_prefix <- paste0("--", name, "=")
  eq_hit <- grep(paste0("^", eq_prefix), args, value = TRUE)
  if (length(eq_hit) > 0L) {
    return(sub(eq_prefix, "", eq_hit[[length(eq_hit)]], fixed = TRUE))
  }
  key <- paste0("--", name)
  key_index <- which(args == key)
  if (length(key_index) == 0L) {
    return(default)
  }
  value_index <- key_index[[length(key_index)]] + 1L
  if (value_index > length(args) || startsWith(args[[value_index]], "--")) {
    return(default)
  }
  args[[value_index]]
}

arg_bool <- function(name, default = FALSE) {
  value <- arg_value(name, NULL)
  if (is.null(value)) {
    return(default)
  }
  tolower(value) %in% c("1", "true", "yes", "y")
}

clean_ascii <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- "NA"
  x <- gsub("[\r\n\t]+", " ", x)
  x <- gsub("[^ -~]", "", x)
  x <- gsub(" +", " ", x)
  trimws(x)
}

write_tsv <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  character_cols <- vapply(x, is.character, logical(1L))
  x[character_cols] <- lapply(x[character_cols], clean_ascii)
  utils::write.table(
    x,
    path,
    sep = "\t",
    quote = FALSE,
    row.names = FALSE,
    na = "NA"
  )
}

write_stdout_tsv <- function(x) {
  character_cols <- vapply(x, is.character, logical(1L))
  x[character_cols] <- lapply(x[character_cols], clean_ascii)
  utils::write.table(
    x,
    stdout(),
    sep = "\t",
    quote = FALSE,
    row.names = FALSE,
    na = "NA"
  )
}

relpath <- function(path, root) {
  path <- normalizePath(path, winslash = "/", mustWork = FALSE)
  root <- normalizePath(root, winslash = "/", mustWork = FALSE)
  prefix <- paste0(root, "/")
  if (startsWith(path, prefix)) {
    return(substring(path, nchar(prefix) + 1L))
  }
  path
}

script_file <- sub(
  "^--file=",
  "",
  grep("^--file=", commandArgs(FALSE), value = TRUE)[1L] %||% "tools"
)
runner_root <- normalizePath(file.path(dirname(script_file), ".."), mustWork = FALSE)
if (!file.exists(file.path(runner_root, "DESCRIPTION"))) {
  runner_root <- normalizePath(getwd(), mustWork = FALSE)
}

t68_source_snapshot_path <- paste0(
  "/home/snakagaw/codex/",
  "drmTMB-q1mu-slope-tranche68-source-56add7f0-20260702T103739Z"
)
t68_run_root_path <- paste0(
  "/home/snakagaw/drmtmb-qseries/",
  "q1-mu-slope-spatial-tranche68-20260702T103739Z"
)
default_output_dir <- file.path(
  t68_run_root_path,
  "tranche70-spatial-host-smoke-artifacts"
)
expected_seeds <- 861001:861005

mode <- gsub("_", "-", tolower(arg_value("mode", "dry-run")), fixed = TRUE)
provider <- tolower(arg_value("provider", "spatial"))
target <- tolower(arg_value("target", "both"))
n_rep <- as.integer(arg_value("n-rep", "5"))
seed_arg <- arg_value("seeds", paste(expected_seeds, collapse = ","))
seeds <- as.integer(trimws(strsplit(seed_arg, ",", fixed = TRUE)[[1L]]))
host_label <- clean_ascii(arg_value("host-label", "totoro_q1mu_slope_spatial_t70_n5"))
source_snapshot_path <- clean_ascii(arg_value(
  "source-snapshot-path",
  t68_source_snapshot_path
))
run_root_path <- clean_ascii(arg_value("run-root-path", t68_run_root_path))
output_dir <- clean_ascii(arg_value("output-dir", default_output_dir))
summary_path_arg <- clean_ascii(arg_value("summary-path", "NA"))
write_dashboard <- arg_bool("write-dashboard", FALSE)
overwrite <- arg_bool("overwrite", FALSE)

if (!mode %in% c("dry-run", "execute")) {
  stop("--mode must be dry-run or execute.", call. = FALSE)
}
if (!identical(provider, "spatial")) {
  stop("Tranche 70 is spatial-only; use --provider=spatial.", call. = FALSE)
}
if (!target %in% c("both", "mu_intercept", "mu_x")) {
  stop("`--target` must be both, mu_intercept, or mu_x.", call. = FALSE)
}
if (!identical(n_rep, 5L)) {
  stop("Tranche 70 is fixed at --n-rep=5.", call. = FALSE)
}
if (!identical(seeds, expected_seeds)) {
  stop(
    "Tranche 70 seed manifest must be 861001,861002,861003,861004,861005.",
    call. = FALSE
  )
}
if (isTRUE(write_dashboard)) {
  stop(
    "Tranche 70 is artifact-only; use --write-dashboard=false.",
    call. = FALSE
  )
}
if (!identical(source_snapshot_path, t68_source_snapshot_path)) {
  stop(
    "Tranche 70 must use the exact T68 source snapshot path: ",
    t68_source_snapshot_path,
    call. = FALSE
  )
}
if (!identical(run_root_path, t68_run_root_path)) {
  stop(
    "Tranche 70 must use the exact T68 run root path: ",
    t68_run_root_path,
    call. = FALSE
  )
}

targets <- switch(
  target,
  both = c("mu_intercept", "mu_x"),
  mu_intercept = "mu_intercept",
  mu_x = "mu_x"
)
target_members <- c(mu_intercept = "mu:(Intercept)", mu_x = "mu:x")
direct_sd_targets <- c(mu_intercept = "sd_mu_intercept", mu_x = "sd_mu_x")
target_parameters <- c(
  mu_intercept = "sd:mu:spatial(1 | site)",
  mu_x = "sd:mu:spatial(0 + x | site)"
)
raw_path <- file.path(output_dir, "structured-re-gaussian-mu-slope-tranche70-spatial-host-smoke-results.tsv")
run_log_path <- file.path(output_dir, "structured-re-gaussian-mu-slope-tranche70-spatial-host-smoke-run-log.tsv")
summary_path <- if (identical(summary_path_arg, "NA")) {
  file.path(output_dir, "structured-re-gaussian-mu-slope-tranche70-spatial-host-smoke-summary.tsv")
} else {
  summary_path_arg
}
run_id <- paste0("tranche70_spatial_mu_slope_", host_label, "_n5")

claim_boundary <- paste(
  "Tranche 70 spatial-only q1 mu one-slope n=5 host-smoke runner contract;",
  "execute mode is fail-closed behind",
  "DRMTMB_Q1MU_SLOPE_T70_EXECUTION_APPROVED=rose_fisher_noether_grace;",
  "source code must load from the exact T68 Totoro snapshot;",
  "artifacts must write under the exact T68 qseries run root;",
  "write-dashboard=false is mandatory;",
  "all attempted replicates are retained if execution happens;",
  "no model command in dry-run;",
  "no coverage authorization;",
  "no support-cell status movement;",
  "no inference_ready;",
  "no supported;",
  "no q1 sigma;",
  "no q2;",
  "no q4/q8;",
  "no non-Gaussian interval;",
  "no REML;",
  "no AI-REML;",
  "no bridge support;",
  "no public support;",
  "no denominator pooling."
)

manifest <- do.call(
  rbind,
  lapply(targets, function(target_id) {
    data.frame(
      manifest_id = paste0("tranche70_spatial_", target_id, "_seed_", seeds),
      provider = "spatial",
      target = target_id,
      endpoint_member = target_members[[target_id]],
      direct_sd_target = direct_sd_targets[[target_id]],
      parameter = target_parameters[[target_id]],
      replicate_index = seq_along(seeds),
      seed = seeds,
      host_label = host_label,
      source_snapshot_path = source_snapshot_path,
      run_root_path = run_root_path,
      output_dir = output_dir,
      raw_artifact_path = raw_path,
      summary_artifact_path = summary_path,
      run_log_path = run_log_path,
      execution_status = if (identical(mode, "dry-run")) {
        "dry_run_only_no_fit_no_host_command"
      } else {
        "execute_requested_pending_fail_closed_checks"
      },
      denominator_status = if (identical(mode, "dry-run")) {
        "no_new_denominator"
      } else {
        "future_attempts_retained_after_execution"
      },
      coverage_decision = "coverage_not_authorized",
      promotion_decision = "do_not_promote",
      support_cell_decision = "unchanged_point_fit_planned_planned",
      claim_boundary = claim_boundary,
      stringsAsFactors = FALSE
    )
  })
)

if (identical(mode, "dry-run")) {
  write_stdout_tsv(manifest)
  quit(status = 0L)
}

approval <- Sys.getenv("DRMTMB_Q1MU_SLOPE_T70_EXECUTION_APPROVED", unset = "")
if (!identical(approval, "rose_fisher_noether_grace")) {
  stop(
    "Refusing Tranche 70 execution: set ",
    "DRMTMB_Q1MU_SLOPE_T70_EXECUTION_APPROVED=rose_fisher_noether_grace ",
    "after Rose/Fisher/Noether/Grace approval and checkpoint.",
    call. = FALSE
  )
}
if (!identical(target, "both")) {
  stop("Execute mode must run both direct-SD targets together.", call. = FALSE)
}
source_root <- normalizePath(source_snapshot_path, winslash = "/", mustWork = TRUE)
run_root <- normalizePath(run_root_path, winslash = "/", mustWork = TRUE)
output_dir_norm <- normalizePath(output_dir, winslash = "/", mustWork = FALSE)
if (!startsWith(output_dir_norm, paste0(run_root, "/"))) {
  stop("`--output-dir` must be under the exact T68 run root.", call. = FALSE)
}
if (dir.exists(output_dir) && !overwrite) {
  stop(
    "`output-dir` already exists. Use --overwrite=true to replace it: ",
    output_dir,
    call. = FALSE
  )
}
if (dir.exists(output_dir) && overwrite) {
  unlink(output_dir, recursive = TRUE)
}
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

load_current_source <- function(path) {
  if (!requireNamespace("devtools", quietly = TRUE)) {
    stop("The Tranche 70 runner requires devtools for load_all().", call. = FALSE)
  }
  devtools::load_all(path, quiet = TRUE)
}

source_local <- function(path) {
  source(file.path(source_root, path), local = .GlobalEnv)
}

load_status <- tryCatch(
  {
    load_current_source(source_root)
    "devtools_load_all_exact_t68_source_snapshot"
  },
  error = function(e) {
    paste("devtools_load_all_failed:", conditionMessage(e))
  }
)
if (!identical(load_status, "devtools_load_all_exact_t68_source_snapshot")) {
  run_log <- data.frame(
    run_id = run_id,
    mode = mode,
    host_label = host_label,
    source_snapshot_path = source_snapshot_path,
    run_root_path = run_root_path,
    output_dir = output_dir,
    raw_artifact_path = raw_path,
    summary_artifact_path = summary_path,
    run_log_path = run_log_path,
    load_status = clean_ascii(load_status),
    coverage_decision = "coverage_not_authorized",
    promotion_decision = "do_not_promote",
    support_cell_decision = "unchanged_point_fit_planned_planned",
    claim_boundary = claim_boundary,
    stringsAsFactors = FALSE
  )
  write_tsv(run_log, run_log_path)
  write_tsv(manifest, raw_path)
  stop("drmTMB could not be loaded from the exact T68 source snapshot.", call. = FALSE)
}

for (path in c(
  "inst/sim/R/sim_registry.R",
  "inst/sim/R/sim_utils.R",
  "inst/sim/dgp/sim_dgp_spatial_mu_slope.R",
  "inst/sim/fit/sim_summarise_spatial_mu_slope.R",
  "inst/sim/run/sim_run_spatial_mu_slope_smoke.R"
)) {
  source_local(path)
}

endpoint_from_parameter <- function(parm) {
  if (grepl("\\(1 \\|", parm)) {
    return("mu:(Intercept)")
  }
  if (grepl("\\(0 \\+ x \\|", parm)) {
    return("mu:x")
  }
  "unknown"
}

target_from_endpoint <- function(endpoint_member) {
  switch(
    endpoint_member,
    "mu:(Intercept)" = "sd_mu_intercept",
    "mu:x" = "sd_mu_x",
    "sd_mu_unknown"
  )
}

empty_result_rows <- function(replicate_index, seed, status, message, elapsed_sec = NA_real_) {
  do.call(
    rbind,
    lapply(names(target_parameters), function(target_id) {
      data.frame(
        run_id = run_id,
        replicate_index = replicate_index,
        seed = seed,
        host_label = host_label,
        provider = "spatial",
        cell_id = "qseries_spatial_q1_mu_one_slope",
        target = target_id,
        endpoint_member = target_members[[target_id]],
        direct_sd_target = direct_sd_targets[[target_id]],
        parameter = target_parameters[[target_id]],
        truth = NA_real_,
        estimate = NA_real_,
        conf_low = NA_real_,
        conf_high = NA_real_,
        conf_level = NA_real_,
        interval_method = NA_character_,
        interval_scale = NA_character_,
        conf_status = NA_character_,
        finite_interval = FALSE,
        covered = FALSE,
        lower_miss = FALSE,
        upper_miss = FALSE,
        convergence = NA_integer_,
        converged = FALSE,
        pdHess = FALSE,
        nobs = NA_integer_,
        elapsed_sec = elapsed_sec,
        warning_count = 0L,
        warnings = "",
        attempt_status = status,
        fit_message = clean_ascii(message),
        target_found = FALSE,
        denominator_policy = "attempt_retained_even_when_failed;host_denominator_separate;do_not_pool_hosts",
        coverage_decision = "coverage_not_authorized",
        promotion_decision = "do_not_promote",
        support_cell_decision = "unchanged_point_fit_planned_planned",
        claim_boundary = claim_boundary,
        stringsAsFactors = FALSE
      )
    })
  )
}

run_one_replicate <- function(replicate_index, seed) {
  condition <- phase18_spatial_mu_slope_conditions(
    n_site = 12L,
    n_each = 8L
  )[1L, , drop = FALSE]
  warnings <- character()
  started <- proc.time()[["elapsed"]]
  dat <- withCallingHandlers(
    tryCatch(
      phase18_dgp_spatial_mu_slope_cell(
        condition,
        seed = seed,
        cell_id = "qseries_spatial_q1_mu_one_slope",
        replicate = replicate_index
      ),
      error = function(e) e
    ),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  if (inherits(dat, "error")) {
    elapsed <- proc.time()[["elapsed"]] - started
    return(empty_result_rows(replicate_index, seed, "sim_error", conditionMessage(dat), elapsed))
  }
  fit <- withCallingHandlers(
    tryCatch(phase18_fit_spatial_mu_slope(dat, condition), error = function(e) e),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  if (inherits(fit, "error")) {
    elapsed <- proc.time()[["elapsed"]] - started
    return(empty_result_rows(replicate_index, seed, "fit_error", conditionMessage(fit), elapsed))
  }
  ci <- withCallingHandlers(
    tryCatch(confint(fit), error = function(e) e),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  elapsed <- proc.time()[["elapsed"]] - started
  if (inherits(ci, "error")) {
    rows <- empty_result_rows(replicate_index, seed, "confint_error", conditionMessage(ci), elapsed)
    rows$convergence <- fit$opt$convergence %||% NA_integer_
    rows$converged <- isTRUE((fit$opt$convergence %||% NA_integer_) == 0L)
    rows$pdHess <- isTRUE(fit$sdr$pdHess)
    rows$nobs <- stats::nobs(fit)
    rows$warning_count <- length(unique(warnings))
    rows$warnings <- paste(unique(warnings), collapse = " | ")
    return(rows)
  }
  sd_rows <- grepl("^sd:mu:spatial", ci$parm)
  out <- ci[sd_rows, , drop = FALSE]
  truth <- attr(dat, "truth", exact = TRUE)$sd
  sd_est <- fit$sdpars$mu
  rows <- lapply(names(target_parameters), function(target_id) {
    endpoint_member <- target_members[[target_id]]
    direct_sd_target <- direct_sd_targets[[target_id]]
    parm <- target_parameters[[target_id]]
    row <- out[out$parm == parm, , drop = FALSE]
    target_found <- nrow(row) == 1L
    truth_value <- unname(truth[[sub("^sd:mu:", "", parm)]])
    estimate_value <- unname(sd_est[[sub("^sd:mu:", "", parm)]])
    if (!target_found) {
      missing_rows <- empty_result_rows(
        replicate_index,
        seed,
        "target_missing",
        paste("confint output did not include", parm),
        elapsed
      )
      return(missing_rows[missing_rows$target == target_id, , drop = FALSE])
    }
    finite_interval <- is.finite(row$lower) && is.finite(row$upper)
    covered <- finite_interval && row$lower <= truth_value && truth_value <= row$upper
    data.frame(
      run_id = run_id,
      replicate_index = replicate_index,
      seed = seed,
      host_label = host_label,
      provider = "spatial",
      cell_id = "qseries_spatial_q1_mu_one_slope",
      target = target_id,
      endpoint_member = endpoint_member,
      direct_sd_target = direct_sd_target,
      parameter = parm,
      truth = truth_value,
      estimate = estimate_value,
      conf_low = row$lower,
      conf_high = row$upper,
      conf_level = row$level,
      interval_method = paste0("confint_default_", row$method),
      interval_scale = row$scale,
      conf_status = row$conf.status,
      finite_interval = finite_interval,
      covered = covered,
      lower_miss = finite_interval && truth_value < row$lower,
      upper_miss = finite_interval && truth_value > row$upper,
      convergence = fit$opt$convergence %||% NA_integer_,
      converged = isTRUE((fit$opt$convergence %||% NA_integer_) == 0L),
      pdHess = isTRUE(fit$sdr$pdHess),
      nobs = stats::nobs(fit),
      elapsed_sec = elapsed,
      warning_count = length(unique(warnings)),
      warnings = paste(unique(warnings), collapse = " | "),
      attempt_status = "fit_ok",
      fit_message = "",
      target_found = TRUE,
      denominator_policy = "attempt_retained_even_when_failed;host_denominator_separate;do_not_pool_hosts",
      coverage_decision = "coverage_not_authorized",
      promotion_decision = "do_not_promote",
      support_cell_decision = "unchanged_point_fit_planned_planned",
      claim_boundary = claim_boundary,
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

rows <- do.call(
  rbind,
  lapply(seq_along(seeds), function(i) run_one_replicate(i, seeds[[i]]))
)
write_tsv(rows, raw_path)

summaries <- do.call(
  rbind,
  lapply(names(target_parameters), function(target_id) {
    subset <- rows[rows$target == target_id, , drop = FALSE]
    n_attempted <- nrow(subset)
    n_fit_ok <- sum(subset$attempt_status == "fit_ok")
    n_pdhess <- sum(subset$pdHess %in% TRUE)
    n_finite <- sum(subset$finite_interval %in% TRUE)
    data.frame(
      result_id = paste0("tranche70_spatial_mu_slope_", target_id),
      cell_id = "qseries_spatial_q1_mu_one_slope",
      provider = "spatial",
      target = target_id,
      endpoint_member = target_members[[target_id]],
      direct_sd_target = direct_sd_targets[[target_id]],
      parameter = target_parameters[[target_id]],
      n_rep_planned = 5L,
      n_attempted = n_attempted,
      host_label = host_label,
      source_snapshot_path = source_snapshot_path,
      run_root_path = run_root_path,
      raw_artifact_url = relpath(raw_path, source_root),
      run_log_url = relpath(run_log_path, source_root),
      n_fit_error = sum(subset$attempt_status %in% c("sim_error", "fit_error", "confint_error", "target_missing")),
      n_fit_ok = n_fit_ok,
      n_converged = sum(subset$converged %in% TRUE),
      n_pdhess = n_pdhess,
      pdhess_rate = round(n_pdhess / n_attempted, 4L),
      n_finite_interval = n_finite,
      finite_interval_rate = round(n_finite / n_attempted, 4L),
      n_covered = sum(subset$covered %in% TRUE),
      n_lower_miss = sum(subset$lower_miss %in% TRUE),
      n_upper_miss = sum(subset$upper_miss %in% TRUE),
      smoke_decision = if (n_pdhess == n_attempted && n_finite == n_attempted) {
        "host_smoke_completed_review_required_no_promotion"
      } else {
        "host_smoke_failed_review_required"
      },
      coverage_decision = "coverage_not_authorized",
      promotion_decision = "do_not_promote",
      support_cell_decision = "unchanged_point_fit_planned_planned",
      rose_audit = "rose_no_status_claim_from_t70_artifact",
      fisher_review = "fisher_n5_smoke_not_coverage",
      noether_review = "noether_spatial_q1_mu_direct_sd_identity_preserved",
      grace_review = "grace_exact_t68_source_and_run_root_required",
      claim_boundary = claim_boundary,
      next_gate = paste(
        "Review Tranche 70 retained attempt artifacts for pdHess and finite",
        "direct-SD intervals before any admission wording; no coverage design",
        "or status edit without Rose/Fisher/Noether/Grace review."
      ),
      stringsAsFactors = FALSE
    )
  })
)
write_tsv(summaries, summary_path)

run_log <- data.frame(
  run_id = run_id,
  mode = mode,
  host_label = host_label,
  source_snapshot_path = source_snapshot_path,
  run_root_path = run_root_path,
  output_dir = output_dir,
  raw_artifact_path = raw_path,
  summary_artifact_path = summary_path,
  run_log_path = run_log_path,
  n_attempted_rows = nrow(rows),
  n_summary_rows = nrow(summaries),
  load_status = load_status,
  coverage_decision = "coverage_not_authorized",
  promotion_decision = "do_not_promote",
  support_cell_decision = "unchanged_point_fit_planned_planned",
  claim_boundary = claim_boundary,
  stringsAsFactors = FALSE
)
write_tsv(run_log, run_log_path)

message("[tranche70] wrote ", raw_path)
message("[tranche70] wrote ", summary_path)
message("[tranche70] wrote ", run_log_path)
message("[tranche70] coverage_decision=coverage_not_authorized")
message("[tranche70] promotion_decision=do_not_promote")
