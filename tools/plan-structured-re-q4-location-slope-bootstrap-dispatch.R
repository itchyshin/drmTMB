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

dashboard_dir <- file.path(repo_root, "docs", "dev-log", "dashboard")
artifact_dir <- file.path(
  repo_root,
  "docs",
  "dev-log",
  "simulation-artifacts",
  "2026-06-24-q4-location-slope-bootstrap-dispatch-plan"
)
dir.create(artifact_dir, recursive = TRUE, showWarnings = FALSE)

interval_status_path <- file.path(
  dashboard_dir,
  "structured-re-q4-location-slope-interval-diagnostic-status.tsv"
)
budget_probe_path <- file.path(
  dashboard_dir,
  "structured-re-q4-location-slope-bootstrap-budget-probe.tsv"
)
output_path <- file.path(
  dashboard_dir,
  "structured-re-q4-location-slope-bootstrap-dispatch-plan.tsv"
)
manifest_path <- file.path(
  artifact_dir,
  "structured-re-q4-location-slope-bootstrap-dispatch-target-manifest.tsv"
)

status <- utils::read.delim(
  interval_status_path,
  sep = "\t",
  quote = "",
  check.names = FALSE,
  stringsAsFactors = FALSE
)
budget_probe <- utils::read.delim(
  budget_probe_path,
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

endpoint_token <- function(endpoint_member) {
  out <- gsub(":", "_", endpoint_member, fixed = TRUE)
  out <- gsub("(", "", out, fixed = TRUE)
  out <- gsub(")", "", out, fixed = TRUE)
  tolower(out)
}

provider_prefix <- c(
  phylo = "Phylo",
  spatial = "Fixed-covariance spatial",
  animal = "Animal A-matrix",
  relmat = "Relmat K-matrix"
)
provider_boundary <- c(
  phylo = "",
  spatial = " no range-estimating spatial support,",
  animal = " no pedigree/Ainv bridge marshalling,",
  relmat = " no Q precision marshalling,"
)
provider_shard <- c(
  phylo = "provider_shard_01_phylo",
  spatial = "provider_shard_02_spatial",
  animal = "provider_shard_03_animal",
  relmat = "provider_shard_04_relmat"
)
provider_order <- c("phylo", "spatial", "animal", "relmat")
endpoint_order <- c(
  "mu1:(Intercept)",
  "mu1:x",
  "mu2:(Intercept)",
  "mu2:x"
)

direct_status <- status[
  status$target_kind == "direct_sd",
  ,
  drop = FALSE
]
direct_status$provider_order <- match(
  direct_status$structured_type,
  provider_order
)
direct_status$endpoint_order <- match(
  direct_status$endpoint_member,
  endpoint_order
)
direct_status <- direct_status[
  order(direct_status$endpoint_order, direct_status$provider_order),
  ,
  drop = FALSE
]

source_interval_status <- paste(
  "docs/dev-log/dashboard",
  "structured-re-q4-location-slope-interval-diagnostic-status.tsv",
  sep = "/"
)
source_interval_artifact <- paste(
  "docs/dev-log/simulation-artifacts",
  "2026-06-24-q4-location-slope-interval-smoke",
  "structured-re-q4-location-slope-interval-smoke-results.tsv",
  sep = "/"
)
source_budget_probe <- paste(
  "docs/dev-log/dashboard",
  "structured-re-q4-location-slope-bootstrap-budget-probe.tsv",
  sep = "/"
)
source_budget_artifact <- paste(
  "docs/dev-log/simulation-artifacts",
  "2026-06-24-q4-location-slope-bootstrap-budget-probe",
  "structured-re-q4-location-slope-bootstrap-budget-probe-results.tsv",
  sep = "/"
)
target_manifest <- paste(
  "docs/dev-log/simulation-artifacts",
  "2026-06-24-q4-location-slope-bootstrap-dispatch-plan",
  "structured-re-q4-location-slope-bootstrap-dispatch-target-manifest.tsv",
  sep = "/"
)

planned_bootstrap_replicates <- 2L
planned_runner <- paste(
  "tools/run-structured-re-q4-location-slope-bootstrap-denominator-runner.R",
  "(planned; not executed by this dispatch-plan slice)"
)
planned_backends <- "totoro_cpu_worker;drac_slurm_array"
retention_policy <- paste(
  "retain_failed_profiles;retain_nonconverged_fits;",
  "retain_nonfinite_intervals;record_bootstrap_refit_attempts;",
  "retain_scheduler_exit_status",
  sep = ""
)

rows <- lapply(seq_len(nrow(direct_status)), function(i) {
  row <- direct_status[i, , drop = FALSE]
  provider <- row$structured_type[[1L]]
  endpoint_member <- row$endpoint_member[[1L]]
  token <- endpoint_token(endpoint_member)
  budget_row <- budget_probe[
    budget_probe$structured_type == provider &
      budget_probe$endpoint_member == "mu1:(Intercept)",
    ,
    drop = FALSE
  ]
  source_budget_status <- if (nrow(budget_row)) {
    budget_row$probe_status[[1L]]
  } else {
    "budget_probe_missing"
  }
  data.frame(
    dispatch_id = paste0(
      "q4_location_slope_bootstrap_dispatch_",
      provider,
      "_",
      token
    ),
    cell_id = row$cell_id,
    formula_cell = row$formula_cell,
    structured_type = provider,
    target_kind = row$target_kind,
    endpoint_member = endpoint_member,
    estimand = row$estimand,
    profile_target = row$profile_target,
    source_interval_status = source_interval_status,
    source_interval_artifact = source_interval_artifact,
    source_budget_probe = source_budget_probe,
    source_budget_artifact = source_budget_artifact,
    source_budget_endpoint_member = "mu1:(Intercept)",
    source_budget_status = source_budget_status,
    target_manifest = target_manifest,
    planned_runner = planned_runner,
    planned_backends = planned_backends,
    planned_shard = provider_shard[[provider]],
    provider_rotation_index = i,
    target_index = match(endpoint_member, endpoint_order),
    bootstrap_replicates = planned_bootstrap_replicates,
    bootstrap_seed = 4100L + i,
    retention_policy = retention_policy,
    scheduler_status = "dry_run_not_submitted",
    compute_status = "not_executed",
    denominator_status = "dispatch_plan_only",
    coverage_evaluable = "FALSE",
    coverage_status = "not_evaluated",
    interval_claim_status = "diagnostic_only",
    status = "covered",
    evidence_url = paste(
      "docs/dev-log/after-task",
      "2026-06-24-q4-location-slope-bootstrap-dispatch-plan.md",
      sep = "/"
    ),
    claim_boundary = clean_text(paste(
      provider_prefix[[provider]],
      "q4 location one-slope bootstrap dispatch plan only;",
      provider_boundary[[provider]],
      "no submitted Totoro job, no submitted DRAC job,",
      "no all-target bootstrap denominator evidence,",
      "no derived-correlation intervals, no interval reliability,",
      "interval coverage, q4 REML, AI-REML, broad bridge support,",
      "public support, partial location-scale support, broader q8 support,",
      "or calibrated coverage wording promoted."
    )),
    next_gate = clean_text(paste(
      "Review this provider-rotating manifest, then execute one shard at a",
      "time on Totoro or through reviewed DRAC submission; retain every target",
      "outcome before any denominator accounting or coverage-grid design."
    )),
    stringsAsFactors = FALSE
  )
})

out <- do.call(rbind, rows)
character_cols <- vapply(out, is.character, logical(1L))
out[character_cols] <- lapply(out[character_cols], clean_text)

utils::write.table(
  out,
  output_path,
  sep = "\t",
  quote = FALSE,
  row.names = FALSE,
  na = "NA"
)
utils::write.table(
  out,
  manifest_path,
  sep = "\t",
  quote = FALSE,
  row.names = FALSE,
  na = "NA"
)

cat("wrote ", output_path, " with ", nrow(out), " rows\n", sep = "")
cat("wrote ", manifest_path, " with ", nrow(out), " rows\n", sep = "")
