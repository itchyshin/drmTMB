#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (!identical(args, "--frozen") && !identical(args, "--committed")) {
  stop("Usage: Rscript tools/verify-ou-v1-census.R --frozen|--committed", call. = FALSE)
}

csv <- file.path("docs", "design", "264-ou-v1-capability-manifest.csv")
md <- file.path("docs", "design", "264-ou-v1-capability-manifest.md")
if (!file.exists(csv) || !file.exists(md)) stop("OU v1 census files are missing.", call. = FALSE)
x <- utils::read.csv(csv, stringsAsFactors = FALSE, check.names = FALSE)
required <- c(
  "bm_config_id", "family", "response_structure", "dpar_set", "bm_formula_shape",
  "q", "estimator", "bm_admission_tier", "ou_v1_target", "proposed_ou_fields",
  "test_anchor", "final_status", "notes"
)
if (!all(required %in% names(x)) || nrow(x) != 29L || anyDuplicated(x$bm_config_id) ||
    !all(x$final_status == "FROZEN_PENDING_EVIDENCE") ||
    !all(c("G01", "G15", "G16", "N01", "N12", "X01") %in% x$bm_config_id)) {
  stop("OU v1 census rows or status contract are incomplete.", call. = FALSE)
}
text <- paste(readLines(md, warn = FALSE), collapse = "\n")
for (needle in c("AS+SA", "r_D", "r_S", "temporal")) {
  if (!grepl(needle, text, fixed = TRUE)) stop("OU v1 correlated-OU contract is incomplete.", call. = FALSE)
}
if (identical(args, "--committed")) {
  tracked <- vapply(c(csv, md), function(path) {
    identical(system2("git", c("ls-files", "--error-unmatch", path), stdout = FALSE, stderr = FALSE), 0L)
  }, logical(1L))
  if (!all(tracked)) stop("OU v1 census is not committed or tracked by Git.", call. = FALSE)
}
cat("OU_V1_CENSUS_FROZEN_PASS\n")
