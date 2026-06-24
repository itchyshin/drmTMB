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
qseries_path <- file.path(
  dashboard_dir,
  "structured-re-q-series-support-cells.tsv"
)
output_path <- file.path(
  dashboard_dir,
  "structured-re-q4-location-slope-interval-diagnostic-plan.tsv"
)

qseries <- utils::read.delim(
  qseries_path,
  sep = "\t",
  quote = "",
  check.names = FALSE,
  stringsAsFactors = FALSE
)

providers <- c("phylo", "spatial", "animal", "relmat")
provider_group <- c(
  phylo = "species",
  spatial = "site",
  animal = "id",
  relmat = "id"
)
provider_prefix <- c(
  phylo = "Phylo",
  spatial = "Fixed-covariance spatial",
  animal = "Animal A-matrix",
  relmat = "Relmat K-matrix"
)
provider_boundary <- c(
  phylo = "",
  spatial = " range-estimating spatial support,",
  animal = " pedigree/Ainv bridge marshalling,",
  relmat = " Q precision marshalling,"
)

endpoint_details <- data.frame(
  endpoint_member = c(
    "mu1:(Intercept)",
    "mu1:x",
    "mu2:(Intercept)",
    "mu2:x"
  ),
  family_axis = "mu",
  endpoint = c("mu1", "mu1", "mu2", "mu2"),
  term = c("1", "0 + x", "1", "0 + x"),
  estimand = c(
    "sd_mu1_intercept",
    "sd_mu1_x",
    "sd_mu2_intercept",
    "sd_mu2_x"
  ),
  stringsAsFactors = FALSE
)

member_token <- function(member) {
  gsub("[()]", "", gsub(":", "_", member))
}

denominator_fields <- paste(
  c(
    "coverage_denominator",
    "n_total",
    "n_fit_ok",
    "n_failed_fit",
    "n_pdhess",
    "n_interval_finite",
    "n_interval_unavailable",
    "coverage_mcse"
  ),
  collapse = ";"
)

rows <- list()
row_index <- 0L

for (provider in providers) {
  cell_id <- paste0("qseries_", provider, "_q4_mu1_mu2_one_slope")
  qrow <- qseries[qseries$cell_id == cell_id, , drop = FALSE]
  if (nrow(qrow) != 1L) {
    stop("Expected one q-series row for ", cell_id, call. = FALSE)
  }
  group <- unname(provider_group[[provider]])
  direct_boundary <- paste0(
    unname(provider_prefix[[provider]]),
    " q4 location one-slope direct-SD interval diagnostic plan only; no",
    " interval reliability, interval coverage, q4 REML, AI-REML, broad",
    " bridge support, public support, broader q8 support, partial",
    " location-scale support,",
    unname(provider_boundary[[provider]]),
    " or calibrated coverage wording is promoted."
  )
  derived_boundary <- paste0(
    unname(provider_prefix[[provider]]),
    " q4 location one-slope derived-correlation interval diagnostic plan",
    " only; derived correlation interval reconstruction is not available,",
    " and no interval reliability, interval coverage, q4 REML, AI-REML,",
    " broad bridge support, public support, broader q8 support, partial",
    " location-scale support,",
    unname(provider_boundary[[provider]]),
    " or calibrated coverage wording is promoted."
  )
  for (i in seq_len(nrow(endpoint_details))) {
    detail <- endpoint_details[i, , drop = FALSE]
    row_index <- row_index + 1L
    rows[[row_index]] <- data.frame(
      diagnostic_id = paste0(
        "q4_location_slope_interval_",
        provider,
        "_",
        detail$estimand
      ),
      cell_id = cell_id,
      formula_cell = qrow$formula_cell,
      structured_type = provider,
      target_kind = "direct_sd",
      endpoint_member = detail$endpoint_member,
      estimand = detail$estimand,
      profile_target = paste0(
        "sd:",
        detail$family_axis,
        ":",
        detail$endpoint,
        ":",
        provider,
        "(",
        detail$term,
        " | p | ",
        group,
        ")"
      ),
      interval_methods = "wald;profile;bootstrap",
      required_fit_evidence = paste(
        c(
          "point_fit",
          "extractor_ready",
          "profile_targets_direct_ready",
          "same_target_fixture_parity"
        ),
        collapse = ";"
      ),
      required_interval_evidence = paste(
        c("finite_direct_sd_intervals_by_method", "coverage_mcse<=0.01"),
        collapse = ";"
      ),
      denominator_fields = denominator_fields,
      current_blocker = "interval_diagnostics_not_run",
      status = "planned",
      evidence_url = "docs/dev-log/after-task/2026-06-24-q4-location-slope-interval-diagnostic-plan.md",
      claim_boundary = direct_boundary,
      next_gate = "Run deterministic target-level Wald/profile/bootstrap smoke before calibrated coverage wording.",
      stringsAsFactors = FALSE
    )
  }

  for (left_index in seq_len(nrow(endpoint_details) - 1L)) {
    for (right_index in seq.int(left_index + 1L, nrow(endpoint_details))) {
      left <- endpoint_details$endpoint_member[[left_index]]
      right <- endpoint_details$endpoint_member[[right_index]]
      estimand <- paste0(
        "cor_",
        member_token(left),
        "_",
        member_token(right)
      )
      row_index <- row_index + 1L
      rows[[row_index]] <- data.frame(
        diagnostic_id = paste0(
          "q4_location_slope_interval_",
          provider,
          "_",
          estimand
        ),
        cell_id = cell_id,
        formula_cell = qrow$formula_cell,
        structured_type = provider,
        target_kind = "derived_correlation",
        endpoint_member = paste(left, right, sep = "+"),
        estimand = estimand,
        profile_target = paste0(
          "derived:",
          provider,
          ":cor(",
          left,
          ",",
          right,
          " | p | ",
          group,
          ")"
        ),
        interval_methods = "delta;profile;bootstrap",
        required_fit_evidence = paste(
          c(
            "point_fit",
            "extractor_ready",
            "corpairs_point_reconstruction",
            "same_target_fixture_parity",
            "derived_interval_reconstruction_planned"
          ),
          collapse = ";"
        ),
        required_interval_evidence = paste(
          c(
            "finite_derived_correlation_intervals_by_method",
            "coverage_mcse<=0.01"
          ),
          collapse = ";"
        ),
        denominator_fields = denominator_fields,
        current_blocker = "derived_correlation_interval_reconstruction_not_available",
        status = "planned",
        evidence_url = "docs/dev-log/after-task/2026-06-24-q4-location-slope-interval-diagnostic-plan.md",
        claim_boundary = derived_boundary,
        next_gate = "Design derived-correlation interval reconstruction before calibrated coverage wording.",
        stringsAsFactors = FALSE
      )
    }
  }
}

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
