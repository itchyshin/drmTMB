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
  "structured-re-q4-intercept-interval-diagnostic-status.tsv"
)
output_path <- file.path(
  dashboard_dir,
  "structured-re-q4-intercept-denominator-precheck.tsv"
)

source_status_rel <- file.path(
  "docs",
  "dev-log",
  "dashboard",
  "structured-re-q4-intercept-interval-diagnostic-status.tsv"
)
evidence_rel <- file.path(
  "docs",
  "dev-log",
  "after-task",
  "2026-06-25-q4-intercept-denominator-precheck.md"
)

status <- utils::read.delim(
  status_path,
  sep = "\t",
  quote = "",
  check.names = FALSE,
  stringsAsFactors = FALSE
)

endpoint_token <- function(endpoint_member) {
  out <- gsub(":", "_", endpoint_member, fixed = TRUE)
  out <- gsub("(", "", out, fixed = TRUE)
  out <- gsub(")", "", out, fixed = TRUE)
  out <- gsub("+", "_", out, fixed = TRUE)
  gsub("_Intercept", "_intercept", out, fixed = TRUE)
}

claim_prefix <- function(provider) {
  switch(
    provider,
    phylo = "Phylo",
    spatial = "Fixed-covariance spatial",
    animal = "Animal A-matrix",
    relmat = "Relmat K-matrix",
    provider
  )
}

provider_boundary <- function(provider) {
  switch(
    provider,
    spatial = " no range-estimating spatial support,",
    animal = " no pedigree/Ainv bridge marshalling,",
    relmat = " no Q bridge marshalling,",
    ""
  )
}

diagnose_row <- function(row) {
  if (identical(row[["failure_class"]], "fit_pdhess_false")) {
    return(list(
      precheck_diagnosis = "pdhess_blocker",
      denominator_admission = "not_admitted_pdhess_false",
      next_gate = paste(
        "Run Hessian geometry and stability variants before denominator",
        "accounting or coverage-grid design."
      )
    ))
  }
  if (identical(row[["failure_class"]], "bootstrap_failed_or_nonfinite")) {
    return(list(
      precheck_diagnosis = "bootstrap_blocker",
      denominator_admission = "not_admitted_bootstrap_nonfinite",
      next_gate = paste(
        "Diagnose nonfinite bootstrap rows before denominator accounting",
        "or coverage-grid design."
      )
    ))
  }
  list(
    precheck_diagnosis = "unexpected_interval_status",
    denominator_admission = "not_admitted_unclassified",
    next_gate = paste(
      "Classify interval diagnostics before denominator accounting",
      "or coverage-grid design."
    )
  )
}

rows <- lapply(seq_len(nrow(status)), function(i) {
  row <- status[i, , drop = FALSE]
  provider <- row$structured_type
  diagnosis <- diagnose_row(row)
  data.frame(
    denominator_id = paste0(
      "q4_intercept_denominator_precheck_",
      provider,
      "_",
      endpoint_token(row$endpoint_member)
    ),
    cell_id = row$cell_id,
    formula_cell = row$formula_cell,
    structured_type = provider,
    target_kind = row$target_kind,
    endpoint_member = row$endpoint_member,
    estimand = row$estimand,
    profile_target = row$profile_target,
    source_interval_status = source_status_rel,
    source_interval_artifact = row$source_artifact,
    smoke_interval_status = row$interval_status,
    smoke_n_finite_intervals = row$n_finite_intervals,
    smoke_wald_status = row$wald_status,
    smoke_profile_status = row$profile_status,
    smoke_bootstrap_status = row$bootstrap_status,
    smoke_n_fit_ok = row$n_fit_ok,
    smoke_n_converged = row$n_converged,
    smoke_n_pdhess = row$n_pdhess,
    precheck_diagnosis = diagnosis$precheck_diagnosis,
    denominator_admission = diagnosis$denominator_admission,
    coverage_status = "not_evaluated",
    interval_claim_status = "diagnostic_only",
    status = "covered",
    evidence_url = evidence_rel,
    claim_boundary = paste0(
      claim_prefix(provider),
      " q4 all-four intercept direct-SD denominator precheck only;",
      provider_boundary(provider),
      " derived-correlation intervals still blocked, no interval reliability,",
      " interval coverage, q4 REML, native-TMB q4 REML, q4 AI-REML,",
      " HSquared AI-REML, broad bridge support, public support,",
      " calibrated coverage wording, denominator admission, or DRAC/Totoro",
      " execution promoted."
    ),
    next_gate = diagnosis$next_gate,
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

message(
  "wrote ",
  nrow(out),
  " q4 intercept denominator precheck rows: ",
  output_path
)
