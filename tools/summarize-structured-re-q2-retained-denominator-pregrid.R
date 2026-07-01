#!/usr/bin/env Rscript

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

args <- commandArgs(trailingOnly = TRUE)
if (any(args %in% c("--help", "-h"))) {
  cat(
    paste(
      "Usage: Rscript tools/summarize-structured-re-q2-retained-denominator-pregrid.R [options]",
      "",
      "Summarizes reviewed q2 SR150 retained-denominator pregrid artifacts.",
      "The output is a no-promotion dashboard sidecar; it never edits support",
      "cells or changes interval/coverage status.",
      "",
      "Options:",
      "  --artifact-root=PATH      Root containing shard_* artifact directories.",
      "  --output=PATH             Dashboard TSV output path.",
      "  --overwrite=true          Replace an existing output path.",
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

read_key_value_file <- function(path) {
  if (!file.exists(path)) {
    return(character())
  }
  lines <- readLines(path, warn = FALSE)
  lines <- lines[grepl("=", lines, fixed = TRUE)]
  values <- sub("^[^=]+=", "", lines)
  names(values) <- sub("=.*$", "", lines)
  values
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

fmt4 <- function(x) {
  ifelse(is.na(x), "NA", sprintf("%.4f", x))
}

fmt6 <- function(x) {
  ifelse(is.na(x), "NA", sprintf("%.6f", x))
}

as_num <- function(x) {
  suppressWarnings(as.numeric(x))
}

ratio_text <- function(num, den) {
  if (is.na(num) || is.na(den)) {
    return("NA")
  }
  if (den == 0L) {
    return(if (num == 0L) "balanced_no_lower_miss" else "Inf")
  }
  fmt4(num / den)
}

rate_text <- function(num, den) {
  if (is.na(num) || is.na(den) || den == 0L) {
    return("NA")
  }
  fmt4(num / den)
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

dashboard_dir <- file.path(repo_root, "docs", "dev-log", "dashboard")
design_path <- file.path(
  dashboard_dir,
  "structured-re-q2-retained-denominator-design.tsv"
)
artifact_root <- normalizePath(
  arg_value(
    "artifact-root",
    file.path(
      repo_root,
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-30-q2-retained-denominator-sr150-pregrid-rorqual"
    )
  ),
  winslash = "/",
  mustWork = FALSE
)
output_path <- normalizePath(
  arg_value(
    "output",
    file.path(
      dashboard_dir,
      "structured-re-q2-retained-denominator-pregrid-results.tsv"
    )
  ),
  winslash = "/",
  mustWork = FALSE
)
overwrite <- arg_flag("overwrite", FALSE)
if (file.exists(output_path) && !overwrite) {
  stop("Output exists; pass --overwrite=true to replace it: ", output_path, call. = FALSE)
}

design <- read_tsv(design_path)
required_design <- c(
  "design_id",
  "cell_id",
  "provider",
  "design_family",
  "source_interval_contract_id",
  "target_kind",
  "endpoint_member",
  "estimand",
  "interval_channel",
  "denominator_policy",
  "pregrid_n_rep",
  "mcse_threshold",
  "target_decision",
  "linked_support_status",
  "promotion_decision",
  "claim_boundary"
)
missing_design <- setdiff(required_design, names(design))
if (length(missing_design) > 0L) {
  stop(
    "q2 retained-denominator design is missing fields: ",
    paste(missing_design, collapse = ", "),
    call. = FALSE
  )
}
if (nrow(design) != 18L) {
  stop("q2 retained-denominator design must keep exactly 18 rows.", call. = FALSE)
}
if (sum(design$target_decision == "sr150_pregrid_ready_no_promotion") != 17L) {
  stop("q2 retained-denominator design must keep 17 SR150-ready rows.", call. = FALSE)
}
if (sum(design$target_decision == "profile_repair_required_no_pregrid") != 1L) {
  stop("q2 retained-denominator design must keep one repair-held row.", call. = FALSE)
}
if (!all(design$linked_support_status == "point_fit/planned/planned")) {
  stop("Linked support cells must remain point_fit/planned/planned.", call. = FALSE)
}
if (!all(design$promotion_decision == "do_not_promote")) {
  stop("Design rows must not promote support cells.", call. = FALSE)
}

ready_design <- design[
  design$target_decision == "sr150_pregrid_ready_no_promotion",
  ,
  drop = FALSE
]
held_design <- design[
  design$target_decision == "profile_repair_required_no_pregrid",
  ,
  drop = FALSE
]

shards <- data.frame(
  shard_id = c(1L, 2L, 3L, 4L, 5L),
  design_family = c(
    rep("q2_intercept", 4L),
    "q2_plus_q2_intercept"
  ),
  provider = c("phylo", "spatial", "animal", "relmat", "phylo"),
  dirname = c(
    "shard_1_q2-intercept-phylo/artifacts",
    "shard_2_q2-intercept-spatial/artifacts",
    "shard_3_q2-intercept-animal/artifacts",
    "shard_4_q2-intercept-relmat/artifacts",
    "shard_5_q2-plus-q2-phylo-ready-targets/artifacts"
  ),
  summary_file = c(
    rep("structured-re-q2-intercept-local-smoke.tsv", 4L),
    "structured-re-q2-plus-q2-intercept-local-smoke.tsv"
  ),
  replicate_file = c(
    rep("structured-re-q2-intercept-local-smoke-replicates.tsv", 4L),
    "structured-re-q2-plus-q2-intercept-local-smoke-replicates.tsv"
  ),
  seed_file = c(
    rep("structured-re-q2-intercept-local-smoke-seed-manifest.tsv", 4L),
    "structured-re-q2-plus-q2-intercept-local-smoke-seed-manifest.tsv"
  ),
  stringsAsFactors = FALSE
)

read_shard <- function(row) {
  shard_dir <- file.path(artifact_root, row$dirname)
  paths <- file.path(shard_dir, c(row$summary_file, row$replicate_file, row$seed_file))
  local_metadata_dir <- file.path(
    artifact_root,
    "_rorqual-metadata",
    paste0("shard_", row$shard_id)
  )
  run_log <- file.path(local_metadata_dir, "q2-retained-denominator-pregrid-run-log.txt")
  run_meta <- read_key_value_file(run_log)
  missing <- paths[!file.exists(paths)]
  if (length(missing) > 0L) {
    stop(
      "Missing q2 retained-denominator pregrid artifact(s): ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }
  summary <- read_tsv(paths[[1L]])
  replicates <- read_tsv(paths[[2L]])
  seeds <- read_tsv(paths[[3L]])
  summary$source_summary <- rel_path(paths[[1L]])
  summary$source_replicates <- rel_path(paths[[2L]])
  summary$source_seed_manifest <- rel_path(paths[[3L]])
  summary$source_shard_id <- row$shard_id
  summary$source_design_family <- row$design_family
  summary$source_shard_provider <- row$provider
  summary$source_artifact_dir <- rel_path(shard_dir)
  fill_missing <- function(field, value) {
    if (!nzchar(value %||% "")) {
      return()
    }
    if (!field %in% names(summary)) {
      summary[[field]] <<- value
      return()
    }
    current <- as.character(summary[[field]])
    current[is.na(current) | !nzchar(current) | current == "NA"] <- value
    summary[[field]] <<- current
  }
  remote_run_root <- run_meta[["run_root"]] %||% ""
  fill_missing("runtime_host_name", run_meta[["node"]] %||% "")
  fill_missing("slurm_cluster_name", run_meta[["slurm_cluster_name"]] %||% "")
  fill_missing("slurm_job_id", run_meta[["slurm_job_id"]] %||% "")
  fill_missing("run_root", remote_run_root)
  if (nzchar(remote_run_root)) {
    fill_missing(
      "metadata_dir",
      file.path(remote_run_root, "metadata", paste0("shard_", row$shard_id))
    )
    fill_missing("log_dir", file.path(remote_run_root, "logs"))
  }
  list(summary = summary, replicates = replicates, seeds = seeds)
}

bind_rows_fill <- function(rows) {
  cols <- unique(unlist(lapply(rows, names), use.names = FALSE))
  filled <- lapply(rows, function(row) {
    missing_cols <- setdiff(cols, names(row))
    for (col in missing_cols) {
      row[[col]] <- NA
    }
    row[, cols, drop = FALSE]
  })
  do.call(rbind, filled)
}

shard_artifacts <- lapply(seq_len(nrow(shards)), function(i) read_shard(shards[i, ]))
summary <- bind_rows_fill(lapply(shard_artifacts, `[[`, "summary"))
replicates <- bind_rows_fill(lapply(shard_artifacts, `[[`, "replicates"))
seeds <- bind_rows_fill(lapply(shard_artifacts, `[[`, "seeds"))

required_summary <- c(
  "contract_id",
  "cell_id",
  "provider",
  "target_kind",
  "endpoint_member",
  "estimand",
  "target_parm",
  "n_rep",
  "n_fit_ok",
  "n_fit_error",
  "n_sim_error",
  "n_converged",
  "n_pdhess",
  "n_wald_finite",
  "n_profile_finite",
  "n_bootstrap_attempted",
  "n_bootstrap_finite",
  "wald_coverage_smoke",
  "wald_mcse_smoke",
  "profile_coverage_smoke",
  "profile_mcse_smoke",
  "wald_lower_miss",
  "wald_upper_miss",
  "profile_lower_miss",
  "profile_upper_miss",
  "promotion_decision",
  "host_class",
  "host_name"
)
missing_summary <- setdiff(required_summary, names(summary))
if (length(missing_summary) > 0L) {
  stop(
    "q2 retained-denominator summaries are missing fields: ",
    paste(missing_summary, collapse = ", "),
    call. = FALSE
  )
}
if (!all(summary$promotion_decision == "do_not_promote")) {
  stop("Source pregrid summaries must not promote support cells.", call. = FALSE)
}
if (!identical(
  sort(summary$contract_id),
  sort(ready_design$source_interval_contract_id)
)) {
  missing_results <- setdiff(ready_design$source_interval_contract_id, summary$contract_id)
  unexpected_results <- setdiff(summary$contract_id, ready_design$source_interval_contract_id)
  stop(
    "Pregrid summary rows do not match the 17 SR150-ready design targets. ",
    "Missing: ",
    paste(missing_results, collapse = ", "),
    "; unexpected: ",
    paste(unexpected_results, collapse = ", "),
    call. = FALSE
  )
}
if (held_design$source_interval_contract_id %in% summary$contract_id) {
  stop("Repair-held q2-plus-q2 target appeared in SR150 pregrid artifacts.", call. = FALSE)
}
if (!all(as.integer(summary$n_rep) == 150L)) {
  stop("All q2 retained-denominator summary rows must have n_rep = 150.", call. = FALSE)
}

replicate_counts <- table(replicates$contract_id)
bad_rep_counts <- names(replicate_counts)[replicate_counts != 150L]
if (length(bad_rep_counts) > 0L) {
  stop(
    "Raw replicate TSVs must retain exactly 150 attempted rows per target. ",
    "Bad targets: ",
    paste(bad_rep_counts, collapse = ", "),
    call. = FALSE
  )
}
if (!setequal(names(replicate_counts), ready_design$source_interval_contract_id)) {
  stop("Raw replicate TSV target set does not match the 17 ready design targets.", call. = FALSE)
}
if (nrow(seeds) != 750L) {
  stop("Seed manifests must contain 750 rows across five SR150 shards.", call. = FALSE)
}

summary <- summary[
  match(ready_design$source_interval_contract_id, summary$contract_id),
  ,
  drop = FALSE
]
row.names(summary) <- NULL

status_for <- function(row, design_row) {
  n_rep <- as.integer(row$n_rep)
  n_fit_ok <- as.integer(row$n_fit_ok)
  n_converged <- as.integer(row$n_converged)
  n_pdhess <- as.integer(row$n_pdhess)
  n_wald_finite <- as.integer(row$n_wald_finite)
  n_profile_finite <- as.integer(row$n_profile_finite)
  wald_mcse <- as_num(row$wald_mcse_smoke)
  threshold <- as_num(design_row$mcse_threshold)
  if (n_fit_ok != n_rep) {
    return("sr150_fit_or_sim_failure_review_required_no_promotion")
  }
  if (n_converged != n_rep || n_pdhess != n_rep) {
    return("sr150_convergence_or_pdhess_review_required_no_promotion")
  }
  if (n_wald_finite != n_rep) {
    return("sr150_wald_finiteness_review_required_no_promotion")
  }
  if (
    identical(design_row$target_kind, "direct_correlation") &&
      n_profile_finite != n_rep
  ) {
    return("sr150_correlation_profile_finiteness_review_required_no_promotion")
  }
  if (!is.na(wald_mcse) && !is.na(threshold) && wald_mcse > threshold) {
    return("sr150_completed_topup_candidate_mcse_gt_0.01_no_promotion")
  }
  "sr150_completed_review_required_no_promotion"
}

rows <- lapply(seq_len(nrow(summary)), function(i) {
  row <- summary[i, , drop = FALSE]
  design_row <- ready_design[
    ready_design$source_interval_contract_id == row$contract_id[[1L]],
    ,
    drop = FALSE
  ]
  n_rep <- as.integer(row$n_rep)
  wald_lower <- as.integer(row$wald_lower_miss)
  wald_upper <- as.integer(row$wald_upper_miss)
  profile_lower <- as.integer(row$profile_lower_miss)
  profile_upper <- as.integer(row$profile_upper_miss)
  data.frame(
    pregrid_id = paste0("q2_retained_denominator_sr150_", design_row$design_id),
    design_id = design_row$design_id,
    cell_id = design_row$cell_id,
    provider = design_row$provider,
    design_family = design_row$design_family,
    source_interval_contract_id = row$contract_id,
    target_kind = design_row$target_kind,
    endpoint_member = design_row$endpoint_member,
    estimand = design_row$estimand,
    target_parm = row$target_parm,
    interval_channel = design_row$interval_channel,
    denominator_policy = design_row$denominator_policy,
    source_artifact_dir = row$source_artifact_dir,
    source_summary = row$source_summary,
    source_replicates = row$source_replicates,
    source_seed_manifest = row$source_seed_manifest,
    n_rep = n_rep,
    n_fit_ok = as.integer(row$n_fit_ok),
    n_fit_error = as.integer(row$n_fit_error),
    n_sim_error = as.integer(row$n_sim_error),
    n_converged = as.integer(row$n_converged),
    n_pdhess = as.integer(row$n_pdhess),
    n_wald_finite = as.integer(row$n_wald_finite),
    n_profile_finite = as.integer(row$n_profile_finite),
    n_bootstrap_attempted = as.integer(row$n_bootstrap_attempted),
    n_bootstrap_finite = as.integer(row$n_bootstrap_finite),
    wald_finite_rate = rate_text(as.integer(row$n_wald_finite), n_rep),
    profile_finite_rate = rate_text(as.integer(row$n_profile_finite), n_rep),
    wald_coverage = fmt4(as_num(row$wald_coverage_smoke)),
    wald_coverage_mcse = fmt6(as_num(row$wald_mcse_smoke)),
    profile_coverage = fmt4(as_num(row$profile_coverage_smoke)),
    profile_coverage_mcse = fmt6(as_num(row$profile_mcse_smoke)),
    wald_lower_miss = wald_lower,
    wald_upper_miss = wald_upper,
    wald_lower_miss_rate = rate_text(wald_lower, n_rep),
    wald_upper_miss_rate = rate_text(wald_upper, n_rep),
    wald_upper_lower_miss_ratio = ratio_text(wald_upper, wald_lower),
    profile_lower_miss = profile_lower,
    profile_upper_miss = profile_upper,
    profile_lower_miss_rate = rate_text(profile_lower, n_rep),
    profile_upper_miss_rate = rate_text(profile_upper, n_rep),
    profile_upper_lower_miss_ratio = ratio_text(profile_upper, profile_lower),
    pregrid_status = status_for(row, design_row),
    review_decision = "fisher_rose_grace_review_required_no_promotion",
    promotion_decision = "do_not_promote",
    evidence_url = row$source_artifact_dir,
    claim_boundary = paste(
      "This promotes exactly no Q-Series row; Rorqual SR150 q2",
      "retained-denominator pregrid artifacts are imported for",
      "Fisher/Rose/Grace review only; all attempted replicate rows are",
      "retained; MCSE <= 0.01 is a top-up target, not an SR150 pass claim;",
      "no interval_status, coverage_status, inference_ready, supported, q1,",
      "q2 slope inheritance, q4/q8, non-Gaussian interval, REML, AI-REML,",
      "bridge support, or public support claim."
    ),
    next_gate = paste(
      "Review retained denominator, convergence, pdHess, Wald/profile finite",
      "rates, lower/upper misses, warning/profile messages in the raw",
      "replicate TSV, and blocked neighbours before any status-table edit;",
      "top up only exact targets that survive Fisher/Rose/Grace review."
    ),
    source_design = rel_path(design_path),
    source_shard_id = row$source_shard_id,
    host_class = row$host_class,
    host_name = row$host_name,
    runtime_host_name = row$runtime_host_name %||% "NA",
    slurm_cluster_name = row$slurm_cluster_name %||% "NA",
    slurm_job_id = row$slurm_job_id %||% "NA",
    run_root = row$run_root %||% "NA",
    metadata_dir = row$metadata_dir %||% "NA",
    log_dir = row$log_dir %||% "NA",
    stringsAsFactors = FALSE
  )
})

out <- do.call(rbind, rows)
write_tsv(out, output_path)
message("Wrote q2 retained-denominator SR150 pregrid rows to ", rel_path(output_path))
