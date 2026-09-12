#!/usr/bin/env Rscript

# Fail-closed verifier for a receipt made by phylo-ou-ayumi-bodymass-ladder.R.
# Usage: Rscript tools/verify-phylo-ou-ayumi-bodymass-receipt.R /output/path

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) stop("Usage: Rscript tools/verify-phylo-ou-ayumi-bodymass-receipt.R <output-dir>", call. = FALSE)
output_dir <- normalizePath(args[[1L]], mustWork = TRUE)
receipt_file <- file.path(output_dir, "receipt.rds")
if (!file.exists(receipt_file)) stop("Missing receipt.rds.", call. = FALSE)
receipt <- readRDS(receipt_file)
required <- c("source_repo", "source_commit", "data_file", "tree_file", "data_sha256",
  "tree_sha256", "rows", "tips", "REML", "receipt_schema_version", "results", "claim_boundary")
missing <- setdiff(required, names(receipt))
if (length(missing)) stop("Receipt lacks: ", paste(missing, collapse = ", "), call. = FALSE)
if (!identical(receipt$receipt_schema_version, 1L) || !isTRUE(receipt$REML)) {
  stop("Receipt has an unexpected schema or REML setting.", call. = FALSE)
}
if (!requireNamespace("digest", quietly = TRUE)) stop("This verifier needs digest.", call. = FALSE)
if (!identical(digest::digest(file = receipt$data_file, algo = "sha256"), receipt$data_sha256) ||
    !identical(digest::digest(file = receipt$tree_file, algo = "sha256"), receipt$tree_sha256)) {
  stop("Source data or tree checksum mismatch.", call. = FALSE)
}
cells <- receipt$results
expected <- expand.grid(model = c("bm", "ou"), residual_scale = c("constant", "climate"), stringsAsFactors = FALSE)
if (!identical(as.character(cells$model), as.character(expected$model)) ||
    !identical(as.character(cells$residual_scale), as.character(expected$residual_scale)) ||
    !all(cells$fit_ok) || nrow(cells) != 4L) {
  stop("Receipt does not contain exactly the required four fitted cells.", call. = FALSE)
}
if (!all(cells$convergence == 0L) || !all(cells$pdHess)) {
  stop("A required cell lacks convergence code zero or a positive-definite Hessian.", call. = FALSE)
}
cat(sprintf("AYUMI_BODYMASS_PHYLO_OU_RECEIPT_PASS rows=%d tips=%d commit=%s\n",
  receipt$rows, receipt$tips, receipt$source_commit
))
