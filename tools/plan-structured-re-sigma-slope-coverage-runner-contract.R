#!/usr/bin/env Rscript

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
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

args <- commandArgs(trailingOnly = TRUE)
mode_matches <- grep("^--mode=", args, value = TRUE)
mode_arg <- if (length(mode_matches)) {
  sub("^--mode=", "", mode_matches[[1L]])
} else {
  "dry-run"
}
if (!identical(mode_arg, "dry-run")) {
  stop(
    "Only --mode=dry-run is supported by this runner-contract planner.",
    call. = FALSE
  )
}

dashboard_dir <- file.path(repo_root, "docs", "dev-log", "dashboard")
artifact_dir <- file.path(
  repo_root,
  "docs",
  "dev-log",
  "simulation-artifacts",
  "2026-06-25-sigma-slope-coverage-runner-contract"
)
dir.create(artifact_dir, recursive = TRUE, showWarnings = FALSE)

dispatch_path <- file.path(
  dashboard_dir,
  "structured-re-sigma-slope-coverage-dispatch-review.tsv"
)
output_path <- file.path(
  dashboard_dir,
  "structured-re-sigma-slope-coverage-runner-contract.tsv"
)

dispatch <- utils::read.delim(
  dispatch_path,
  sep = "\t",
  quote = "",
  check.names = FALSE,
  stringsAsFactors = FALSE
)

clean_text <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- "NA"
  x <- gsub("[\r\n\t]+", " ", x)
  x <- gsub("[^ -~]", "", x)
  x <- gsub(" +", " ", x)
  trimws(x)
}

source_dispatch_manifest <- paste(
  "docs/dev-log/dashboard",
  "structured-re-sigma-slope-coverage-dispatch-review.tsv",
  sep = "/"
)
source_seed_manifest <- paste(
  "docs/dev-log/simulation-artifacts",
  "2026-06-24-sigma-slope-coverage-pregrid-dry-run",
  "structured-re-sigma-slope-coverage-pregrid-seed-manifest.tsv",
  sep = "/"
)
source_cell_manifest <- paste(
  "docs/dev-log/simulation-artifacts",
  "2026-06-24-sigma-slope-coverage-pregrid-dry-run",
  "structured-re-sigma-slope-coverage-pregrid-cell-manifest.tsv",
  sep = "/"
)
dashboard_contract <- paste(
  "docs/dev-log/dashboard",
  "structured-re-sigma-slope-coverage-runner-contract.tsv",
  sep = "/"
)
all_target_manifest <- paste(
  "docs/dev-log/simulation-artifacts",
  "2026-06-25-sigma-slope-coverage-runner-contract",
  "structured-re-sigma-slope-coverage-runner-target-manifest.tsv",
  sep = "/"
)
all_run_log <- paste(
  "docs/dev-log/simulation-artifacts",
  "2026-06-25-sigma-slope-coverage-runner-contract",
  "structured-re-sigma-slope-coverage-runner-run-log.tsv",
  sep = "/"
)

make_runner_rows <- function(selected, selected_manifest, run_log) {
  out <- data.frame(
    runner_id = paste0(
      "sigma_slope_coverage_runner_",
      selected$dispatch_id
    ),
    dispatch_id = selected$dispatch_id,
    cell_id = selected$cell_id,
    formula_cell = selected$formula_cell,
    structured_type = selected$structured_type,
    target_kind = selected$target_kind,
    endpoint_member = selected$endpoint_member,
    direct_sd_target = selected$direct_sd_target,
    profile_target = selected$profile_target,
    mode = "dry-run",
    selected = "TRUE",
    source_dispatch_manifest = source_dispatch_manifest,
    source_seed_manifest = source_seed_manifest,
    source_cell_manifest = source_cell_manifest,
    selected_manifest = selected_manifest,
    run_log = run_log,
    planned_replicates = selected$planned_replicates,
    planned_cells = selected$planned_cells,
    seed_start = selected$seed_start,
    seed_end = selected$seed_end,
    interval_methods = selected$interval_methods,
    retention_policy = selected$retention_policy,
    scheduler_status = "dry_run_not_submitted",
    compute_status = "not_executed",
    denominator_status = "runner_contract_only",
    mcse_threshold_status = selected$mcse_threshold_status,
    coverage_evaluable = "FALSE",
    coverage_status = "not_evaluated",
    interval_claim_status = "diagnostic_only",
    execution_status = "validated_not_executed",
    status = "covered",
    evidence_url = paste(
      "docs/dev-log/after-task",
      "2026-06-25-sigma-slope-coverage-runner-contract.md",
      sep = "/"
    ),
    claim_boundary = clean_text(paste(
      "sigma-only one-slope coverage runner contract only;",
      "no pre-grid cells executed, no Totoro job submitted,",
      "no DRAC job submitted, no coverage-evaluable denominator evidence,",
      "no MCSE-calibrated coverage, no interval reliability,",
      "no matched mu+sigma support, no q4/q8 support, no REML,",
      "no AI-REML, no broad bridge support, no public support,",
      "and no SR150 readiness promoted."
    )),
    next_gate = clean_text(paste(
      "After human review, execute one provider shard at a time on Totoro",
      "or through reviewed DRAC submission with this selected manifest;",
      "use shard-specific manifests and run logs so dry-runs cannot overwrite",
      "the full contract; retain fit errors, nonconvergence, pdHess false,",
      "nonfinite intervals, bootstrap refit attempts, and scheduler exit",
      "status before denominator accounting or coverage wording."
    )),
    stringsAsFactors = FALSE
  )
  character_cols <- vapply(out, is.character, logical(1L))
  out[character_cols] <- lapply(out[character_cols], clean_text)
  out
}

make_run_log <- function(
  selected,
  shard_id,
  provider_filter,
  selected_manifest
) {
  endpoint_members <- paste(unique(selected$endpoint_member), collapse = ";")
  structured_types <- paste(unique(selected$structured_type), collapse = ";")
  data.frame(
    run_id = paste0("sigma_slope_coverage_runner_contract_", shard_id),
    mode = "dry-run",
    shard_id = shard_id,
    provider_filter = provider_filter,
    endpoint_member_filter = "all",
    selected_targets = nrow(selected),
    selected_structured_types = structured_types,
    selected_endpoint_members = endpoint_members,
    source_dispatch_manifest = source_dispatch_manifest,
    source_seed_manifest = source_seed_manifest,
    source_cell_manifest = source_cell_manifest,
    selected_manifest = selected_manifest,
    dashboard_contract = dashboard_contract,
    execution_status = "validated_not_executed",
    scheduler_status = "dry_run_not_submitted",
    compute_status = "not_executed",
    denominator_status = "runner_contract_only",
    mcse_threshold_status = "not_met_by_sr150",
    coverage_evaluable = "FALSE",
    coverage_status = "not_evaluated",
    interval_claim_status = "diagnostic_only",
    status = "covered",
    claim_boundary = clean_text(paste(
      "sigma-only one-slope coverage runner contract only;",
      "no pre-grid cells executed, no Totoro job submitted,",
      "no DRAC job submitted, no coverage-evaluable denominator evidence,",
      "no MCSE-calibrated coverage, no interval reliability,",
      "no matched mu+sigma support, no q4/q8 support, no REML,",
      "no AI-REML, no broad bridge support, no public support,",
      "and no SR150 readiness promoted."
    )),
    next_gate = clean_text(paste(
      "After human review, execute one provider shard at a time on Totoro",
      "or through reviewed DRAC submission with this selected manifest;",
      "retain fit errors, nonconvergence, pdHess false, nonfinite intervals,",
      "bootstrap refit attempts, and scheduler exit status before denominator",
      "accounting or coverage wording."
    )),
    stringsAsFactors = FALSE
  )
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

runner <- make_runner_rows(dispatch, all_target_manifest, all_run_log)
run_log <- make_run_log(dispatch, "all-targets", "all", all_target_manifest)

write_tsv(runner, output_path)
write_tsv(runner, file.path(artifact_dir, basename(all_target_manifest)))
write_tsv(run_log, file.path(artifact_dir, basename(all_run_log)))

for (provider in unique(dispatch$structured_type)) {
  shard_id <- paste0("provider-", provider)
  selected <- dispatch[dispatch$structured_type == provider, , drop = FALSE]
  shard_manifest <- paste(
    "docs/dev-log/simulation-artifacts",
    "2026-06-25-sigma-slope-coverage-runner-contract",
    paste0(
      "structured-re-sigma-slope-coverage-runner-target-manifest-",
      shard_id,
      ".tsv"
    ),
    sep = "/"
  )
  shard_run_log <- paste(
    "docs/dev-log/simulation-artifacts",
    "2026-06-25-sigma-slope-coverage-runner-contract",
    paste0(
      "structured-re-sigma-slope-coverage-runner-run-log-",
      shard_id,
      ".tsv"
    ),
    sep = "/"
  )
  shard_rows <- make_runner_rows(selected, shard_manifest, shard_run_log)
  shard_log <- make_run_log(selected, shard_id, provider, shard_manifest)
  write_tsv(shard_rows, file.path(artifact_dir, basename(shard_manifest)))
  write_tsv(shard_log, file.path(artifact_dir, basename(shard_run_log)))
}

cat("wrote ", output_path, " with ", nrow(runner), " rows\n", sep = "")
cat(
  "wrote ",
  file.path(artifact_dir, basename(all_target_manifest)),
  " with ",
  nrow(runner),
  " rows\n",
  sep = ""
)
cat(
  "wrote ",
  file.path(artifact_dir, basename(all_run_log)),
  " with 1 row\n",
  sep = ""
)
