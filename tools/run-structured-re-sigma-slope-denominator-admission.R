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
status_path <- file.path(
  dashboard_dir,
  "structured-re-sigma-slope-interval-diagnostic-status.tsv"
)
stability_path <- file.path(
  dashboard_dir,
  "structured-re-sigma-slope-interval-stability-probe.tsv"
)
output_path <- file.path(
  dashboard_dir,
  "structured-re-sigma-slope-denominator-admission.tsv"
)

status <- utils::read.delim(
  status_path,
  sep = "\t",
  quote = "",
  check.names = FALSE,
  stringsAsFactors = FALSE
)
stability <- utils::read.delim(
  stability_path,
  sep = "\t",
  quote = "",
  check.names = FALSE,
  stringsAsFactors = FALSE
)

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

endpoint_token <- function(endpoint_member) {
  out <- gsub(":", "_", endpoint_member, fixed = TRUE)
  out <- gsub("(", "", out, fixed = TRUE)
  out <- gsub(")", "", out, fixed = TRUE)
  gsub("_Intercept", "_intercept", out, fixed = TRUE)
}

rows <- lapply(seq_len(nrow(status)), function(i) {
  row <- status[i, , drop = FALSE]
  key <- stability$structured_type == row$structured_type &
    stability$endpoint_member == row$endpoint_member
  stability_rows <- stability[key, , drop = FALSE]
  n_variants <- nrow(stability_rows)
  n_wald_profile_finite <- sum(
    stability_rows$wald_status == "finite" &
      stability_rows$profile_status == "finite"
  )
  n_pdhess <- sum(as.integer(stability_rows$n_pdhess) == 1L)
  admission <- if (
    identical(row$interval_status, "wald_profile_bootstrap_finite") &&
      n_variants > 0L &&
      n_wald_profile_finite == n_variants &&
      n_pdhess == n_variants
  ) {
    "diagnostic_denominator_candidate"
  } else {
    "not_admitted_profile_failure"
  }
  next_gate <- if (identical(admission, "diagnostic_denominator_candidate")) {
    "Repeat across more seeds and add MCSE-calibrated denominator accounting before coverage wording."
  } else {
    "Diagnose endpoint-profile failure before denominator admission or coverage wording."
  }
  provider <- row$structured_type
  boundary <- paste0(
    provider_prefix[[provider]],
    " sigma-only one-slope denominator-admission diagnostic only;",
    provider_boundary[[provider]],
    " no interval reliability, interval coverage, coverage acceptance, ",
    "matched mu+sigma support, q4/q8, REML, AI-REML, or broad bridge support promoted."
  )
  data.frame(
    denominator_id = paste0(
      "sigma_slope_denominator_",
      provider,
      "_",
      endpoint_token(row$endpoint_member)
    ),
    cell_id = row$cell_id,
    formula_cell = row$formula_cell,
    structured_type = provider,
    target_kind = row$target_kind,
    endpoint_member = row$endpoint_member,
    direct_sd_target = row$direct_sd_target,
    profile_target = row$profile_target,
    source_interval_status = "docs/dev-log/dashboard/structured-re-sigma-slope-interval-diagnostic-status.tsv",
    source_stability_probe = "docs/dev-log/dashboard/structured-re-sigma-slope-interval-stability-probe.tsv",
    source_interval_artifact = row$source_artifact,
    source_stability_artifact = stability_rows$source_artifact[1L],
    smoke_interval_status = row$interval_status,
    smoke_n_finite_intervals = row$n_finite_intervals,
    smoke_wald_status = row$wald_status,
    smoke_profile_status = row$profile_status,
    smoke_bootstrap_status = row$bootstrap_status,
    stability_variant_count = n_variants,
    stability_wald_profile_finite_count = n_wald_profile_finite,
    stability_pdhess_true_count = n_pdhess,
    denominator_admission = admission,
    coverage_status = "not_evaluated",
    interval_claim_status = "diagnostic_only",
    status = "covered",
    evidence_url = "docs/dev-log/after-task/2026-06-24-sigma-slope-denominator-admission.md",
    claim_boundary = boundary,
    next_gate = next_gate,
    stringsAsFactors = FALSE
  )
})

out <- do.call(rbind, rows)
utils::write.table(
  out,
  output_path,
  sep = "\t",
  quote = FALSE,
  row.names = FALSE,
  na = "NA"
)

cat("wrote ", output_path, " with ", nrow(out), " rows\n", sep = "")
