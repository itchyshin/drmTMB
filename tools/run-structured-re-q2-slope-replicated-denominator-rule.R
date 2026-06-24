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
admission_path <- file.path(
  dashboard_dir,
  "structured-re-q2-slope-denominator-admission.tsv"
)
extension_path <- file.path(
  dashboard_dir,
  "structured-re-q2-slope-denominator-extension.tsv"
)
output_path <- file.path(
  dashboard_dir,
  "structured-re-q2-slope-replicated-denominator-rule.tsv"
)

admission <- utils::read.delim(
  admission_path,
  sep = "\t",
  quote = "",
  check.names = FALSE,
  stringsAsFactors = FALSE
)
extension <- utils::read.delim(
  extension_path,
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

denominator_action <- function(admission_status, extension_candidate_count) {
  if (
    identical(admission_status, "diagnostic_denominator_candidate") &&
      extension_candidate_count == 2L
  ) {
    return("eligible_for_pregrid_with_retention")
  }
  "visible_holdout_until_smoke_profile_reconciled"
}

claim_boundary <- function(provider) {
  clean_text(paste(
    provider_prefix[[provider]],
    "q2 slope replicated-denominator rule only;",
    provider_boundary[[provider]],
    "no coverage-evaluable denominator evidence, calibrated coverage,",
    "interval reliability, q4/q8, REML, AI-REML, broad bridge support,",
    "DRAC execution, or SR150 readiness promoted."
  ))
}

next_gate <- function(action) {
  if (identical(action, "eligible_for_pregrid_with_retention")) {
    return(paste(
      "Run a predeclared q2 slope coverage pre-grid with all fit, profile,",
      "nonfinite-interval, and bootstrap-refit outcomes retained in the",
      "denominator; require MCSE <= 0.01 before coverage wording."
    ))
  }
  paste(
    "Keep this target visible as a holdout and reconcile the smoke",
    "endpoint-profile failure before admitting it to a coverage denominator."
  )
}

rows <- lapply(seq_len(nrow(admission)), function(i) {
  row <- admission[i, , drop = FALSE]
  provider <- row$structured_type[[1L]]
  endpoint_member <- row$endpoint_member[[1L]]
  key <- extension$structured_type == provider &
    extension$endpoint_member == endpoint_member
  extension_rows <- extension[key, , drop = FALSE]
  extension_variant_count <- nrow(extension_rows)
  extension_finite_count <- sum(
    extension_rows$wald_status == "finite" &
      extension_rows$profile_status == "finite"
  )
  extension_candidate_count <- sum(
    extension_rows$denominator_extension_status == "extension_candidate"
  )
  action <- denominator_action(
    row$denominator_admission[[1L]],
    extension_candidate_count
  )

  data.frame(
    rule_id = paste0(
      "q2_slope_replicated_denominator_rule_",
      provider,
      "_",
      gsub("[:+]", "_", endpoint_member)
    ),
    cell_id = row$cell_id,
    formula_cell = row$formula_cell,
    structured_type = provider,
    target_kind = row$target_kind,
    endpoint_member = endpoint_member,
    estimand = row$estimand,
    profile_target = row$profile_target,
    source_admission = "docs/dev-log/dashboard/structured-re-q2-slope-denominator-admission.tsv",
    source_extension = "docs/dev-log/dashboard/structured-re-q2-slope-denominator-extension.tsv",
    source_interval_status = row$source_interval_status,
    source_stability_probe = row$source_stability_probe,
    admission_status = row$denominator_admission,
    extension_variant_count = extension_variant_count,
    extension_wald_profile_finite_count = extension_finite_count,
    extension_candidate_count = extension_candidate_count,
    smoke_profile_status = row$smoke_profile_status,
    current_denominator_action = action,
    pregrid_min_replicates = 150L,
    seed_policy = "predeclared_seed_manifest_required_before_execution",
    failed_profile_retention = "retain_in_denominator",
    nonconverged_fit_retention = "retain_in_denominator",
    nonfinite_interval_retention = "retain_in_denominator",
    bootstrap_refit_retention = "record_attempts_and_retain_target_denominator",
    mcse_threshold = "0.01",
    coverage_evaluable = "FALSE",
    coverage_status = "not_evaluated",
    interval_claim_status = "diagnostic_only",
    status = "covered",
    evidence_url = "docs/dev-log/after-task/2026-06-24-q2-slope-replicated-denominator-rule.md",
    claim_boundary = claim_boundary(provider),
    next_gate = next_gate(action),
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

cat("wrote ", output_path, " with ", nrow(out), " rows\n", sep = "")
