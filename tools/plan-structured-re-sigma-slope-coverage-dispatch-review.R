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
  "2026-06-25-sigma-slope-coverage-dispatch-review"
)
dir.create(artifact_dir, recursive = TRUE, showWarnings = FALSE)

pregrid_path <- file.path(
  dashboard_dir,
  "structured-re-sigma-slope-coverage-pregrid-dry-run.tsv"
)
qseries_path <- file.path(
  dashboard_dir,
  "structured-re-q-series-support-cells.tsv"
)
cell_manifest_path <- file.path(
  repo_root,
  "docs",
  "dev-log",
  "simulation-artifacts",
  "2026-06-24-sigma-slope-coverage-pregrid-dry-run",
  "structured-re-sigma-slope-coverage-pregrid-cell-manifest.tsv"
)
output_path <- file.path(
  dashboard_dir,
  "structured-re-sigma-slope-coverage-dispatch-review.tsv"
)
target_manifest_path <- file.path(
  artifact_dir,
  "structured-re-sigma-slope-coverage-dispatch-target-manifest.tsv"
)

pregrid <- utils::read.delim(
  pregrid_path,
  sep = "\t",
  quote = "",
  check.names = FALSE,
  stringsAsFactors = FALSE
)
qseries <- utils::read.delim(
  qseries_path,
  sep = "\t",
  quote = "",
  check.names = FALSE,
  stringsAsFactors = FALSE
)
cell_manifest <- utils::read.delim(
  cell_manifest_path,
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
  out <- gsub("_Intercept", "_intercept", out, fixed = TRUE)
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
  relmat = " no Q bridge marshalling,"
)
provider_shard <- c(
  phylo = "provider_shard_01_phylo",
  spatial = "provider_shard_02_spatial",
  animal = "provider_shard_03_animal",
  relmat = "provider_shard_04_relmat"
)
provider_order <- c("phylo", "spatial", "animal", "relmat")
endpoint_order <- c("sigma:(Intercept)", "sigma:x")

dispatch <- pregrid[
  pregrid$denominator_role == "pregrid_target" &
    pregrid$current_denominator_action == "eligible_for_pregrid_with_retention",
  ,
  drop = FALSE
]
dispatch$provider_order <- match(dispatch$structured_type, provider_order)
dispatch$endpoint_order <- match(dispatch$endpoint_member, endpoint_order)
dispatch <- dispatch[
  order(dispatch$endpoint_order, dispatch$provider_order),
  ,
  drop = FALSE
]

source_pregrid <- paste(
  "docs/dev-log/dashboard",
  "structured-re-sigma-slope-coverage-pregrid-dry-run.tsv",
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
target_manifest <- paste(
  "docs/dev-log/simulation-artifacts",
  "2026-06-25-sigma-slope-coverage-dispatch-review",
  "structured-re-sigma-slope-coverage-dispatch-target-manifest.tsv",
  sep = "/"
)

planned_runner <- paste(
  "tools/run-structured-re-sigma-slope-coverage-pregrid-runner.R",
  "(planned; not executed by this dispatch-review slice)"
)
planned_backends <- "totoro_cpu_worker;drac_slurm_array"
retention_policy <- paste(
  "retain_failed_profiles;retain_nonconverged_fits;",
  "retain_nonfinite_intervals;record_bootstrap_refit_attempts;",
  "retain_scheduler_exit_status",
  sep = ""
)

rows <- lapply(seq_len(nrow(dispatch)), function(i) {
  row <- dispatch[i, , drop = FALSE]
  provider <- row$structured_type[[1L]]
  endpoint_member <- row$endpoint_member[[1L]]
  target_cells <- cell_manifest[
    cell_manifest$structured_type == provider &
      cell_manifest$endpoint_member == endpoint_member,
    ,
    drop = FALSE
  ]
  seed_values <- as.integer(target_cells$seed)
  qseries_row <- qseries[qseries$cell_id == row$cell_id, , drop = FALSE]
  data.frame(
    dispatch_id = paste0(
      "sigma_slope_coverage_dispatch_",
      provider,
      "_",
      endpoint_token(endpoint_member)
    ),
    cell_id = row$cell_id,
    formula_cell = qseries_row$formula_cell[[1L]],
    structured_type = provider,
    target_kind = row$target_kind,
    endpoint_member = endpoint_member,
    direct_sd_target = row$direct_sd_target,
    profile_target = row$profile_target,
    source_pregrid = source_pregrid,
    source_seed_manifest = source_seed_manifest,
    source_cell_manifest = source_cell_manifest,
    target_manifest = target_manifest,
    planned_runner = planned_runner,
    planned_backends = planned_backends,
    planned_shard = provider_shard[[provider]],
    provider_rotation_index = i,
    target_index = match(endpoint_member, endpoint_order),
    planned_replicates = row$planned_replicates,
    planned_cells = row$planned_cells,
    seed_start = min(seed_values),
    seed_end = max(seed_values),
    interval_methods = row$interval_methods,
    retention_policy = retention_policy,
    scheduler_status = "dry_run_not_submitted",
    compute_status = "not_executed",
    denominator_status = "dispatch_review_only",
    mcse_threshold_status = row$mcse_threshold_status,
    coverage_evaluable = "FALSE",
    coverage_status = "not_evaluated",
    interval_claim_status = "diagnostic_only",
    status = "covered",
    evidence_url = paste(
      "docs/dev-log/after-task",
      "2026-06-25-sigma-slope-coverage-dispatch-review.md",
      sep = "/"
    ),
    claim_boundary = clean_text(paste(
      provider_prefix[[provider]],
      "sigma-only one-slope coverage dispatch review only;",
      provider_boundary[[provider]],
      "no submitted Totoro job, no submitted DRAC job,",
      "no executed pre-grid cells, no coverage-evaluable denominator",
      "evidence, no calibrated coverage, no interval reliability,",
      "no matched mu+sigma support, no q4/q8 support, no REML, no AI-REML,",
      "no broad bridge support, no public support, no DRAC execution,",
      "and no SR150 readiness promoted."
    )),
    next_gate = clean_text(paste(
      "Review this dispatch manifest and runner contract, then execute one",
      "provider shard on Totoro or through reviewed DRAC submission; retain",
      "fit errors, nonconvergence, pdHess false, nonfinite intervals,",
      "bootstrap refit attempts, and scheduler exit status before any",
      "denominator accounting or coverage wording."
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
  target_manifest_path,
  sep = "\t",
  quote = FALSE,
  row.names = FALSE,
  na = "NA"
)

cat("wrote ", output_path, " with ", nrow(out), " rows\n", sep = "")
cat(
  "wrote ",
  target_manifest_path,
  " with ",
  nrow(out),
  " rows\n",
  sep = ""
)
