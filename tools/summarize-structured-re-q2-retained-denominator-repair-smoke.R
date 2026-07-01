#!/usr/bin/env Rscript

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

args <- commandArgs(trailingOnly = TRUE)
if (any(args %in% c("--help", "-h"))) {
  cat(
    paste(
      "Usage: Rscript tools/summarize-structured-re-q2-retained-denominator-repair-smoke.R [options]",
      "",
      "Imports q2 retained-denominator repair-smoke command manifests and any",
      "available per-cell smoke artifacts. Missing artifacts are retained as",
      "manifest-only rows; diagnostic repair sidecars are summarized separately,",
      "and no support-cell status is changed.",
      "",
      "Options:",
      "  --manifest=PATH          repair-smoke command manifest.",
      "  --output=PATH            dashboard sidecar to write.",
      "  --overwrite=true         replace existing output.",
      "  --require-artifacts=true fail if any selected artifact directory is missing.",
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

clean_text <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- "NA"
  x <- gsub("[\r\n\t]+", " ", x)
  x <- gsub("[^ -~]", "", x)
  x <- gsub(" +", " ", x)
  trimws(x)
}

read_tsv <- function(path) {
  utils::read.delim(
    path,
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
}

write_tsv <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  character_cols <- vapply(x, is.character, logical(1L))
  x[character_cols] <- lapply(x[character_cols], clean_text)
  utils::write.table(
    x,
    file = path,
    sep = "\t",
    row.names = FALSE,
    quote = FALSE,
    na = "NA"
  )
}

as_num <- function(x) {
  suppressWarnings(as.numeric(x))
}

fmt4 <- function(x) {
  ifelse(is.na(x), "NA", sprintf("%.4f", x))
}

fmt6 <- function(x) {
  ifelse(is.na(x), "NA", sprintf("%.6f", x))
}

join_unique <- function(x) {
  x <- unique(as.character(x[!is.na(x) & nzchar(as.character(x))]))
  if (length(x) == 0L) {
    return("NA")
  }
  paste(x, collapse = ";")
}

rate_text <- function(num, den) {
  if (is.na(num) || is.na(den) || den == 0L) {
    return("NA")
  }
  fmt4(num / den)
}

safe_min_num <- function(x) {
  x <- as_num(x)
  x <- x[is.finite(x)]
  if (length(x) == 0L) {
    return(NA_real_)
  }
  min(x)
}

safe_max_num <- function(x) {
  x <- as_num(x)
  x <- x[is.finite(x)]
  if (length(x) == 0L) {
    return(NA_real_)
  }
  max(x)
}

script_file <- sub(
  "^--file=",
  "",
  grep("^--file=", commandArgs(FALSE), value = TRUE)[1L] %||% "tools"
)
repo_root_candidates <- c(
  Sys.getenv("DRMTMB_REPO_ROOT", ""),
  file.path(dirname(script_file), ".."),
  getwd(),
  file.path(getwd(), ".."),
  file.path(getwd(), "..", "..")
)
repo_root_candidates <- repo_root_candidates[nzchar(repo_root_candidates)]
repo_root <- NA_character_
for (candidate in repo_root_candidates) {
  candidate <- normalizePath(candidate, winslash = "/", mustWork = FALSE)
  if (file.exists(file.path(candidate, "DESCRIPTION"))) {
    repo_root <- candidate
    break
  }
}
if (is.na(repo_root)) {
  stop("Cannot locate drmTMB repo root.", call. = FALSE)
}

rel_path <- function(path) {
  path <- normalizePath(path, winslash = "/", mustWork = FALSE)
  sub(paste0("^", gsub("([\\W])", "\\\\\\1", repo_root), "/?"), "", path)
}

resolve_path <- function(path) {
  if (grepl("^/", path)) {
    return(normalizePath(path, winslash = "/", mustWork = FALSE))
  }
  normalizePath(file.path(repo_root, path), winslash = "/", mustWork = FALSE)
}

dashboard_dir <- file.path(repo_root, "docs", "dev-log", "dashboard")
default_manifest <- file.path(
  repo_root,
  "docs",
  "dev-log",
  "simulation-artifacts",
  "2026-06-30-q2-retained-denominator-repair-smoke-local",
  "structured-re-q2-retained-denominator-repair-smoke-command.tsv"
)
manifest_path <- normalizePath(
  arg_value("manifest", default_manifest),
  winslash = "/",
  mustWork = FALSE
)
output_path <- normalizePath(
  arg_value(
    "output",
    file.path(
      dashboard_dir,
      "structured-re-q2-retained-denominator-repair-smoke-dispatch.tsv"
    )
  ),
  winslash = "/",
  mustWork = FALSE
)
overwrite <- arg_flag("overwrite", FALSE)
require_artifacts <- arg_flag("require-artifacts", FALSE)
if (file.exists(output_path) && !overwrite) {
  stop("Output exists; pass --overwrite=true to replace it: ", output_path, call. = FALSE)
}
if (!file.exists(manifest_path)) {
  stop("Repair-smoke manifest does not exist: ", manifest_path, call. = FALSE)
}

manifest <- read_tsv(manifest_path)
if (!"interval_repair_channel" %in% names(manifest)) {
  manifest$interval_repair_channel <- "none"
}
required_manifest <- c(
  "command_id",
  "repair_id",
  "cell_id",
  "provider",
  "repair_status",
  "repair_targets",
  "n_rep",
  "smoke_seed_range",
  "seed_start",
  "seed_base",
  "seed_end",
  "profile_max_eval",
  "interval_repair_channel",
  "host_class",
  "host_name",
  "output_dir",
  "source_repair_contract",
  "selected_contract_ids",
  "dry_run",
  "promotion_decision",
  "claim_boundary",
  "command"
)
missing_manifest <- setdiff(required_manifest, names(manifest))
if (length(missing_manifest) > 0L) {
  stop(
    "repair-smoke command manifest is missing fields: ",
    paste(missing_manifest, collapse = ", "),
    call. = FALSE
  )
}
if (!all(manifest$promotion_decision == "do_not_promote")) {
  stop("Repair-smoke command manifest must be no-promotion only.", call. = FALSE)
}
if (anyDuplicated(manifest$cell_id) > 0L) {
  stop("Repair-smoke command manifest has duplicate cell_id rows.", call. = FALSE)
}

summary_candidates <- function(artifact_dir) {
  c(
    file.path(artifact_dir, "structured-re-q2-intercept-local-smoke.tsv"),
    file.path(artifact_dir, "structured-re-q2-intercept-substitute-smoke.tsv"),
    file.path(artifact_dir, "structured-re-q2-plus-q2-intercept-local-smoke.tsv")
  )
}

replicate_candidates <- function(artifact_dir) {
  c(
    file.path(artifact_dir, "structured-re-q2-intercept-local-smoke-replicates.tsv"),
    file.path(artifact_dir, "structured-re-q2-intercept-substitute-smoke-replicates.tsv"),
    file.path(artifact_dir, "structured-re-q2-plus-q2-intercept-local-smoke-replicates.tsv")
  )
}

seed_candidates <- function(artifact_dir) {
  c(
    file.path(artifact_dir, "structured-re-q2-intercept-local-smoke-seed-manifest.tsv"),
    file.path(artifact_dir, "structured-re-q2-intercept-substitute-smoke-seed-manifest.tsv"),
    file.path(artifact_dir, "structured-re-q2-plus-q2-intercept-local-smoke-seed-manifest.tsv")
  )
}

artifact_status <- function(summary, n_rep) {
  if (is.null(summary)) {
    return("repair_smoke_manifest_only_no_promotion")
  }
  n_rep <- as.integer(n_rep)
  if (any(as.integer(summary$n_fit_ok) != n_rep)) {
    return("repair_smoke_fit_or_sim_failure_review_required_no_promotion")
  }
  if (
    any(as.integer(summary$n_converged) != n_rep) ||
      any(as.integer(summary$n_pdhess) != n_rep)
  ) {
    return("repair_smoke_convergence_or_pdhess_review_required_no_promotion")
  }
  if (
    any(as.integer(summary$n_wald_finite) != n_rep) ||
      any(as.integer(summary$n_profile_finite) != n_rep)
  ) {
    return("repair_smoke_finiteness_review_required_no_promotion")
  }
  mcse <- c(as_num(summary$wald_mcse_smoke), as_num(summary$profile_mcse_smoke))
  if (any(mcse > 0.01, na.rm = TRUE)) {
    return("repair_smoke_mcse_gt_0.01_review_required_no_promotion")
  }
  "repair_smoke_completed_review_required_no_promotion"
}

rows <- lapply(seq_len(nrow(manifest)), function(i) {
  row <- manifest[i, , drop = FALSE]
  artifact_dir <- resolve_path(row$output_dir[[1L]])
  summary_path <- summary_candidates(artifact_dir)
  summary_path <- summary_path[file.exists(summary_path)]
  replicate_path <- replicate_candidates(artifact_dir)
  replicate_path <- replicate_path[file.exists(replicate_path)]
  seed_path <- seed_candidates(artifact_dir)
  seed_path <- seed_path[file.exists(seed_path)]
  if (length(summary_path) == 0L) {
    if (require_artifacts) {
      stop("Missing repair-smoke summary artifact for ", row$cell_id, call. = FALSE)
    }
    summary <- NULL
    observed_target_rows <- 0L
    n_fit_ok_min <- NA_integer_
    n_converged_min <- NA_integer_
    n_pdhess_min <- NA_integer_
    n_wald_finite_min <- NA_integer_
    n_profile_finite_min <- NA_integer_
    min_wald_coverage <- NA_real_
    max_wald_mcse <- NA_real_
    min_profile_coverage <- NA_real_
    max_profile_mcse <- NA_real_
    wald_lower_miss <- NA_integer_
    wald_upper_miss <- NA_integer_
    profile_lower_miss <- NA_integer_
    profile_upper_miss <- NA_integer_
    interval_repair_channel <- row$interval_repair_channel
    n_repair_attempted_min <- NA_integer_
    n_repair_finite_min <- NA_integer_
    min_repair_coverage <- NA_real_
    max_repair_mcse <- NA_real_
    repair_lower_miss <- NA_integer_
    repair_upper_miss <- NA_integer_
    observed_contract_ids <- "NA"
  } else {
    summary <- read_tsv(summary_path[[1L]])
    optional_summary_defaults <- list(
      repair_channel = "none",
      n_repair_attempted = 0L,
      n_repair_finite = 0L,
      repair_coverage_smoke = NA_character_,
      repair_mcse_smoke = NA_character_,
      repair_lower_miss = 0L,
      repair_upper_miss = 0L
    )
    for (field in names(optional_summary_defaults)) {
      if (!field %in% names(summary)) {
        summary[[field]] <- optional_summary_defaults[[field]]
      }
    }
    required_summary <- c(
      "contract_id",
      "cell_id",
      "provider",
      "target_kind",
      "endpoint_member",
      "estimand",
      "n_rep",
      "n_fit_ok",
      "n_converged",
      "n_pdhess",
      "n_wald_finite",
      "n_profile_finite",
      "wald_coverage_smoke",
      "wald_mcse_smoke",
      "profile_coverage_smoke",
      "profile_mcse_smoke",
      "wald_lower_miss",
      "wald_upper_miss",
      "profile_lower_miss",
      "profile_upper_miss",
      "promotion_decision"
    )
    missing_summary <- setdiff(required_summary, names(summary))
    if (length(missing_summary) > 0L) {
      stop(
        "repair-smoke summary is missing fields for ",
        row$cell_id,
        ": ",
        paste(missing_summary, collapse = ", "),
        call. = FALSE
      )
    }
    if (!all(summary$promotion_decision == "do_not_promote")) {
      stop("repair-smoke summaries must remain no-promotion only.", call. = FALSE)
    }
    if (!all(summary$cell_id == row$cell_id)) {
      stop("repair-smoke summary cell_id does not match manifest.", call. = FALSE)
    }
    observed_target_rows <- nrow(summary)
    n_fit_ok_min <- min(as.integer(summary$n_fit_ok), na.rm = TRUE)
    n_converged_min <- min(as.integer(summary$n_converged), na.rm = TRUE)
    n_pdhess_min <- min(as.integer(summary$n_pdhess), na.rm = TRUE)
    n_wald_finite_min <- min(as.integer(summary$n_wald_finite), na.rm = TRUE)
    n_profile_finite_min <- min(as.integer(summary$n_profile_finite), na.rm = TRUE)
    min_wald_coverage <- safe_min_num(summary$wald_coverage_smoke)
    max_wald_mcse <- safe_max_num(summary$wald_mcse_smoke)
    min_profile_coverage <- safe_min_num(summary$profile_coverage_smoke)
    max_profile_mcse <- safe_max_num(summary$profile_mcse_smoke)
    wald_lower_miss <- sum(as.integer(summary$wald_lower_miss), na.rm = TRUE)
    wald_upper_miss <- sum(as.integer(summary$wald_upper_miss), na.rm = TRUE)
    profile_lower_miss <- sum(as.integer(summary$profile_lower_miss), na.rm = TRUE)
    profile_upper_miss <- sum(as.integer(summary$profile_upper_miss), na.rm = TRUE)
    interval_repair_channel <- join_unique(summary$repair_channel)
    n_repair_attempted_min <- min(as.integer(summary$n_repair_attempted), na.rm = TRUE)
    n_repair_finite_min <- min(as.integer(summary$n_repair_finite), na.rm = TRUE)
    min_repair_coverage <- safe_min_num(summary$repair_coverage_smoke)
    max_repair_mcse <- safe_max_num(summary$repair_mcse_smoke)
    repair_lower_miss <- sum(as.integer(summary$repair_lower_miss), na.rm = TRUE)
    repair_upper_miss <- sum(as.integer(summary$repair_upper_miss), na.rm = TRUE)
    observed_contract_ids <- join_unique(summary$contract_id)
  }
  data.frame(
    dispatch_id = paste0("q2_retained_denominator_repair_smoke_dispatch_", row$cell_id),
    command_id = row$command_id,
    repair_id = row$repair_id,
    cell_id = row$cell_id,
    provider = row$provider,
    repair_status = row$repair_status,
    repair_targets = row$repair_targets,
    n_rep = as.integer(row$n_rep),
    smoke_seed_range = row$smoke_seed_range,
    seed_base = as.integer(row$seed_base),
    seed_end = as.integer(row$seed_end),
    profile_max_eval = as.integer(row$profile_max_eval),
    interval_repair_channel = interval_repair_channel,
    host_class = row$host_class,
    host_name = row$host_name,
    slurm_cluster_name = row$slurm_cluster_name %||% "NA",
    slurm_job_id = row$slurm_job_id %||% "NA",
    artifact_status = artifact_status(summary, row$n_rep),
    observed_target_rows = observed_target_rows,
    expected_target_rows = if (identical(row$cell_id, "qseries_phylo_q2_plus_q2_intercept")) 5L else 3L,
    n_fit_ok_min = n_fit_ok_min,
    n_converged_min = n_converged_min,
    n_pdhess_min = n_pdhess_min,
    n_wald_finite_min = n_wald_finite_min,
    n_profile_finite_min = n_profile_finite_min,
    n_repair_attempted_min = n_repair_attempted_min,
    n_repair_finite_min = n_repair_finite_min,
    min_wald_coverage = fmt4(min_wald_coverage),
    max_wald_mcse = fmt6(max_wald_mcse),
    min_profile_coverage = fmt4(min_profile_coverage),
    max_profile_mcse = fmt6(max_profile_mcse),
    min_repair_coverage = fmt4(min_repair_coverage),
    max_repair_mcse = fmt6(max_repair_mcse),
    wald_lower_miss = wald_lower_miss,
    wald_upper_miss = wald_upper_miss,
    wald_upper_miss_rate = rate_text(wald_upper_miss, as.integer(row$n_rep) * observed_target_rows),
    profile_lower_miss = profile_lower_miss,
    profile_upper_miss = profile_upper_miss,
    profile_upper_miss_rate = rate_text(profile_upper_miss, as.integer(row$n_rep) * observed_target_rows),
    repair_lower_miss = repair_lower_miss,
    repair_upper_miss = repair_upper_miss,
    repair_upper_miss_rate = rate_text(repair_upper_miss, as.integer(row$n_rep) * observed_target_rows),
    observed_contract_ids = observed_contract_ids,
    selected_contract_ids = row$selected_contract_ids,
    source_manifest = rel_path(manifest_path),
    source_repair_contract = row$source_repair_contract,
    source_summary = if (length(summary_path)) rel_path(summary_path[[1L]]) else "NA",
    source_replicates = if (length(replicate_path)) rel_path(replicate_path[[1L]]) else "NA",
    source_seed_manifest = if (length(seed_path)) rel_path(seed_path[[1L]]) else "NA",
    evidence_url = if (length(summary_path)) rel_path(summary_path[[1L]]) else rel_path(manifest_path),
    promotion_decision = "do_not_promote",
    claim_boundary = paste(
      "This promotes exactly no Q-Series row; q2 retained-denominator repair",
      "smoke dispatch/results are diagnostic-only and do not change",
      "interval_status, coverage_status, inference_ready, supported, or let",
      "repair-sidecar metrics replace the primary interval route without",
      "Fisher/Rose/Grace review; they do not change",
      "q2 slope",
      "inheritance, q2-plus inheritance, q4/q8, non-Gaussian intervals, REML,",
      "AI-REML, bridge support, or public support."
    ),
    next_gate = paste(
      "If artifact_status is manifest-only, run the exact command after",
      "source/root checks; if artifacts are imported, Fisher/Rose/Grace must",
      "review finite rates, pdHess, one-sided misses, raw replicates, and",
      "blocked neighbours before any top-up or support-cell status edit."
    ),
    stringsAsFactors = FALSE
  )
})

out <- do.call(rbind, rows)
write_tsv(out, output_path)
message("Wrote q2 repair-smoke dispatch rows to ", rel_path(output_path))
