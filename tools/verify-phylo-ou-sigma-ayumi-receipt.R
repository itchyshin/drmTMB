#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
out <- if (length(args) == 1L) args[[1L]] else "/private/tmp/phylo-ou-sigma-ayumi-receipt"
preflight_path <- file.path(out, "preflight-500-tip.csv")
full_path <- file.path(out, "all-species.csv")
if (!file.exists(preflight_path) || !file.exists(full_path)) {
  stop("Both bounded and all-species Ayumi feasibility receipts are required.", call. = FALSE)
}
preflight <- utils::read.csv(preflight_path, stringsAsFactors = FALSE)
full <- utils::read.csv(full_path, stringsAsFactors = FALSE)
required <- c(
  "scope", "n_rows", "n_tips", "convergence", "pdHess", "logLik", "AIC",
  "alpha_mu", "alpha_sigma", "max_gradient", "REML", "optimizer_eval_max",
  "optimizer_iter_max", "warning_count", "elapsed_seconds", "data_sha256",
  "tree_sha256", "source_commit", "drmTMB_commit"
)
valid_receipt <- function(receipt, scope, rows) {
  nrow(receipt) == 1L && all(required %in% names(receipt)) &&
    receipt$scope[[1L]] == scope && receipt$n_rows[[1L]] == rows &&
    receipt$n_tips[[1L]] == rows &&
    all(nzchar(unlist(receipt[c("data_sha256", "tree_sha256", "source_commit")]))) &&
    identical(receipt$REML[[1L]], FALSE) &&
    identical(receipt$optimizer_eval_max[[1L]], 1000L) &&
    identical(receipt$optimizer_iter_max[[1L]], 1000L) &&
    all(is.finite(unlist(receipt[c("logLik", "AIC", "alpha_mu", "alpha_sigma", "max_gradient", "elapsed_seconds")])))
}
if (!valid_receipt(preflight, "deterministic_real_data_subtree_preflight", 500L) ||
    !valid_receipt(full, "all_species_one_row_per_tip_feasibility", 10440L) ||
    !identical(preflight$data_sha256, full$data_sha256) ||
    !identical(preflight$tree_sha256, full$tree_sha256) ||
    !identical(preflight$source_commit, full$source_commit)) {
  stop("Ayumi feasibility receipt is incomplete or has the wrong scope.", call. = FALSE)
}
full_rds <- readRDS(file.path(out, "all-species.rds"))
if (!identical(full_rds$controls$REML, FALSE) ||
    !identical(full_rds$controls$optimizer$eval.max, 1000L) ||
    !identical(full_rds$controls$optimizer$iter.max, 1000L) ||
    !grepl("phylo\\(1 \\| species, tree = tree, model = 'ou'\\)", full_rds$formula)) {
  stop("Ayumi receipt does not retain the fitted formula and controls.", call. = FALSE)
}
cat("PHYLO_OU_SIGMA_AYUMI_RECEIPT_PASS\\n")
