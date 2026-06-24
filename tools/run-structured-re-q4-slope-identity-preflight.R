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
  "structured-re-q4-slope-identity-preflight.tsv"
)

qseries <- utils::read.delim(
  qseries_path,
  sep = "\t",
  quote = "",
  check.names = FALSE,
  stringsAsFactors = FALSE
)

providers <- c("phylo", "spatial", "animal", "relmat")
formula_cell <- c(
  phylo = "phylo(1 + x | p | species, tree = tree) in all four endpoints",
  spatial = "spatial(1 + x | p | site, coords = coords) in all four endpoints",
  animal = "animal(1 + x | p | id, A = A) in all four endpoints",
  relmat = "relmat(1 + x | p | id, K = K) in all four endpoints"
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

endpoint_members <- c(
  "mu1:(Intercept)",
  "mu1:x",
  "mu2:(Intercept)",
  "mu2:x",
  "sigma1:(Intercept)",
  "sigma1:x",
  "sigma2:(Intercept)",
  "sigma2:x"
)
direct_sd_targets <- c(
  "sd_mu1_intercept",
  "sd_mu1_x",
  "sd_mu2_intercept",
  "sd_mu2_x",
  "sd_sigma1_intercept",
  "sd_sigma1_x",
  "sd_sigma2_intercept",
  "sd_sigma2_x"
)

rows <- lapply(providers, function(provider) {
  cell_id <- paste0("qseries_", provider, "_q4_all_four_one_slope_planned")
  qrow <- qseries[qseries$cell_id == cell_id, , drop = FALSE]
  if (nrow(qrow) != 1L) {
    stop("Expected one q-series row for ", cell_id, call. = FALSE)
  }
  boundary <- paste0(
    provider_prefix[[provider]],
    " q4 all-four one-slope identity preflight only;",
    provider_boundary[[provider]],
    " runtime, extractor output, bridge parity, intervals, coverage, q4 REML, AI-REML, and broad bridge support remain planned."
  )
  data.frame(
    identity_id = paste0("q4_slope_", provider, "_identity_preflight"),
    cell_id = cell_id,
    formula_cell = unname(formula_cell[[provider]]),
    structured_type = provider,
    dimension_pattern = "q8",
    endpoint_set = "mu1+mu2+sigma1+sigma2",
    slope_class = "labelled_slope_covariance",
    desired_endpoint_member_set = paste(endpoint_members, collapse = ";"),
    coefficient_order = paste(rep(c("(Intercept)", "x"), 4L), collapse = ";"),
    planned_direct_sd_target_set = paste(direct_sd_targets, collapse = ";"),
    direct_sd_target_count = length(direct_sd_targets),
    labelled_covariance_pair_count = choose(length(endpoint_members), 2L),
    covariance_layout = "labelled_structured_endpoint_covariance",
    extractor_identity_gate = "preflight_only",
    runtime_status = qrow$fit_status,
    bridge_status = qrow$bridge_status,
    interval_status = qrow$interval_status,
    coverage_status = qrow$coverage_status,
    source_qseries_status = "docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv",
    evidence_url = "docs/dev-log/after-task/2026-06-24-q4-slope-identity-preflight.md",
    claim_boundary = boundary,
    next_gate = "Implement coefficient-aware q4 all-four one-slope runtime mapping and extractor tests before bridge, interval, coverage, or public-support work.",
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
