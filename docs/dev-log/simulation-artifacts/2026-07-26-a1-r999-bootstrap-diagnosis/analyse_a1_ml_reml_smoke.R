#!/usr/bin/env Rscript
# Analysis for the paired ML-versus-REML smoke only.  It deliberately reports
# counts and directional gaps, not confidence intervals or coverage claims.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) stop("Usage: analyse_a1_ml_reml_smoke.R <result_dir> <expected_attempts_per_cell>", call. = FALSE)
result_dir <- args[[1L]]
expected_attempts <- as.integer(args[[2L]])
if (is.na(expected_attempts) || expected_attempts < 1L) stop("expected_attempts_per_cell must be positive.", call. = FALSE)
file_arg <- grep("^--file=", commandArgs(), value = TRUE)
script_dir <- if (length(file_arg)) dirname(normalizePath(sub("^--file=", "", file_arg[[1L]]))) else getwd()
source(file.path(script_dir, "a1_ml_reml_common.R"))
files <- list.files(result_dir, pattern = "^a1_ml_reml_g(10|25|50)_n10_sd05_o[0-9]{4}\\.csv$", full.names = TRUE)
if (!length(files)) stop("No ML-REML smoke shards found.", call. = FALSE)
x <- do.call(rbind, lapply(files, read.csv, stringsAsFactors = FALSE))
a1_ml_reml_validate_pairs(x)
a1_ml_reml_validate_expected_grid(x, a1_ml_reml_expected_grid(expected_attempts))
summary <- a1_ml_reml_directional_summary(x)
write.csv(summary, file.path(result_dir, "a1_ml_reml_smoke_summary.csv"), row.names = FALSE)
print(summary, row.names = FALSE)
