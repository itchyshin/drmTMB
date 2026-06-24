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
  "2026-06-24-sigma-slope-coverage-pregrid-dry-run"
)
dir.create(artifact_dir, recursive = TRUE, showWarnings = FALSE)

rule_path <- file.path(
  dashboard_dir,
  "structured-re-sigma-slope-replicated-denominator-rule.tsv"
)
output_path <- file.path(
  dashboard_dir,
  "structured-re-sigma-slope-coverage-pregrid-dry-run.tsv"
)
seed_manifest_path <- file.path(
  artifact_dir,
  "structured-re-sigma-slope-coverage-pregrid-seed-manifest.tsv"
)
cell_manifest_path <- file.path(
  artifact_dir,
  "structured-re-sigma-slope-coverage-pregrid-cell-manifest.tsv"
)

rule <- utils::read.delim(
  rule_path,
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
  gsub("_Intercept", "_intercept", out, fixed = TRUE)
}

provider_prefix <- c(
  phylo = "phylo",
  spatial = "fixed-covariance spatial",
  animal = "animal A-matrix",
  relmat = "relmat K-matrix"
)
provider_boundary <- c(
  phylo = "",
  spatial = " no range-estimating spatial support,",
  animal = " no pedigree/Ainv bridge marshalling,",
  relmat = " no Q bridge marshalling,"
)

n_replicates <- 150L
nominal_coverage <- 0.95
mcse_threshold <- 0.01
nominal_mcse <- sqrt(nominal_coverage * (1 - nominal_coverage) / n_replicates)
replicates_for_threshold <- ceiling(
  nominal_coverage * (1 - nominal_coverage) / mcse_threshold^2 - 1e-12
)
seed_manifest <- data.frame(
  replicate_index = seq_len(n_replicates),
  seed = 740000L + seq_len(n_replicates),
  seed_role = "predeclared_sigma_slope_pregrid",
  source_rule = "docs/dev-log/dashboard/structured-re-sigma-slope-replicated-denominator-rule.tsv",
  execution_status = "not_executed",
  stringsAsFactors = FALSE
)

eligible_rule <- rule[
  rule$current_denominator_action == "eligible_for_pregrid_with_retention",
  ,
  drop = FALSE
]
cell_rows <- lapply(seq_len(nrow(eligible_rule)), function(i) {
  target <- eligible_rule[i, , drop = FALSE]
  token <- endpoint_token(target$endpoint_member[[1L]])
  data.frame(
    pregrid_cell_id = sprintf(
      "sigma_slope_pregrid_%s_%s_rep%03d",
      target$structured_type[[1L]],
      token,
      seed_manifest$replicate_index
    ),
    replicate_index = seed_manifest$replicate_index,
    seed = seed_manifest$seed,
    structured_type = target$structured_type,
    endpoint_member = target$endpoint_member,
    direct_sd_target = target$direct_sd_target,
    profile_target = target$profile_target,
    interval_methods = "wald;endpoint_profile;bootstrap",
    current_denominator_action = target$current_denominator_action,
    retention_policy = paste(
      "retain_failed_profiles;retain_nonconverged_fits;",
      "retain_nonfinite_intervals;record_bootstrap_refit_attempts",
      sep = ""
    ),
    execution_status = "not_executed",
    coverage_evaluable = "FALSE",
    stringsAsFactors = FALSE
  )
})
cell_manifest <- do.call(rbind, cell_rows)

target_rows <- lapply(seq_len(nrow(rule)), function(i) {
  row <- rule[i, , drop = FALSE]
  provider <- row$structured_type[[1L]]
  eligible <- identical(
    row$current_denominator_action[[1L]],
    "eligible_for_pregrid_with_retention"
  )
  denominator_role <- if (eligible) {
    "pregrid_target"
  } else {
    "visible_holdout"
  }
  planned_replicates <- if (eligible) n_replicates else 0L
  next_gate <- if (eligible) {
    paste(
      "Execute only after review of this dry-run manifest; retain all outcomes",
      "and do not use SR150 for coverage wording because nominal MCSE is",
      "above 0.01."
    )
  } else {
    paste(
      "Reconcile the smoke endpoint-profile failure before adding this target",
      "to the executable pre-grid cell manifest."
    )
  }
  data.frame(
    pregrid_id = paste0(
      "sigma_slope_coverage_pregrid_",
      provider,
      "_",
      endpoint_token(row$endpoint_member[[1L]])
    ),
    cell_id = row$cell_id,
    formula_cell = row$formula_cell,
    structured_type = provider,
    target_kind = row$target_kind,
    endpoint_member = row$endpoint_member,
    direct_sd_target = row$direct_sd_target,
    profile_target = row$profile_target,
    source_rule = "docs/dev-log/dashboard/structured-re-sigma-slope-replicated-denominator-rule.tsv",
    source_seed_manifest = "docs/dev-log/simulation-artifacts/2026-06-24-sigma-slope-coverage-pregrid-dry-run/structured-re-sigma-slope-coverage-pregrid-seed-manifest.tsv",
    source_cell_manifest = "docs/dev-log/simulation-artifacts/2026-06-24-sigma-slope-coverage-pregrid-dry-run/structured-re-sigma-slope-coverage-pregrid-cell-manifest.tsv",
    current_denominator_action = row$current_denominator_action,
    denominator_role = denominator_role,
    planned_replicates = planned_replicates,
    planned_cells = planned_replicates,
    seed_manifest_rows = nrow(seed_manifest),
    target_cell_manifest_rows = planned_replicates,
    total_cell_manifest_rows = nrow(cell_manifest),
    nominal_coverage = sprintf("%.2f", nominal_coverage),
    nominal_mcse_at_150 = sprintf("%.6f", nominal_mcse),
    replicates_for_mcse_threshold = replicates_for_threshold,
    mcse_threshold = sprintf("%.2f", mcse_threshold),
    mcse_threshold_status = "not_met_by_sr150",
    interval_methods = "wald;endpoint_profile;bootstrap",
    retention_policy = paste(
      "retain_failed_profiles;retain_nonconverged_fits;",
      "retain_nonfinite_intervals;record_bootstrap_refit_attempts",
      sep = ""
    ),
    execution_status = "not_executed",
    coverage_evaluable = "FALSE",
    coverage_status = "not_evaluated",
    interval_claim_status = "diagnostic_only",
    status = "covered",
    evidence_url = "docs/dev-log/after-task/2026-06-24-sigma-slope-coverage-pregrid-dry-run.md",
    claim_boundary = clean_text(paste(
      provider_prefix[[provider]],
      "sigma-only one-slope coverage pre-grid dry-run only;",
      provider_boundary[[provider]],
      "no coverage-evaluable denominator evidence, calibrated coverage,",
      "interval reliability, matched mu+sigma support, q4/q8, REML,",
      "AI-REML, broad bridge support, DRAC execution, or SR150 readiness",
      "promoted."
    )),
    next_gate = clean_text(next_gate),
    stringsAsFactors = FALSE
  )
})

target_out <- do.call(rbind, target_rows)
for (object_name in c("seed_manifest", "cell_manifest", "target_out")) {
  object <- get(object_name)
  character_cols <- vapply(object, is.character, logical(1L))
  object[character_cols] <- lapply(object[character_cols], clean_text)
  assign(object_name, object)
}

utils::write.table(
  seed_manifest,
  seed_manifest_path,
  sep = "\t",
  quote = FALSE,
  row.names = FALSE,
  na = "NA"
)
utils::write.table(
  cell_manifest,
  cell_manifest_path,
  sep = "\t",
  quote = FALSE,
  row.names = FALSE,
  na = "NA"
)
utils::write.table(
  target_out,
  output_path,
  sep = "\t",
  quote = FALSE,
  row.names = FALSE,
  na = "NA"
)

cat("wrote ", output_path, " with ", nrow(target_out), " rows\n", sep = "")
cat(
  "wrote ",
  seed_manifest_path,
  " with ",
  nrow(seed_manifest),
  " rows\n",
  sep = ""
)
cat(
  "wrote ",
  cell_manifest_path,
  " with ",
  nrow(cell_manifest),
  " rows\n",
  sep = ""
)
