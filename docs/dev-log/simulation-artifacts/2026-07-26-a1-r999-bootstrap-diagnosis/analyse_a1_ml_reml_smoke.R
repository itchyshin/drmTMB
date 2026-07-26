#!/usr/bin/env Rscript
# Analysis for the paired ML-versus-REML smoke only.  It deliberately reports
# counts and directional gaps, not confidence intervals or coverage claims.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) stop("Usage: analyse_a1_ml_reml_smoke.R <result_dir>", call. = FALSE)
result_dir <- args[[1L]]
file_arg <- grep("^--file=", commandArgs(), value = TRUE)
script_dir <- if (length(file_arg)) dirname(normalizePath(sub("^--file=", "", file_arg[[1L]]))) else getwd()
source(file.path(script_dir, "a1_ml_reml_common.R"))
files <- list.files(result_dir, pattern = "^a1_ml_reml_g(10|25|50)_n10_sd05_o[0-9]{4}\\.csv$", full.names = TRUE)
if (!length(files)) stop("No ML-REML smoke shards found.", call. = FALSE)
x <- do.call(rbind, lapply(files, read.csv, stringsAsFactors = FALSE))
a1_ml_reml_validate_pairs(x)
summary <- a1_ml_reml_directional_summary(x)
write.csv(summary, file.path(result_dir, "a1_ml_reml_smoke_summary.csv"), row.names = FALSE)
print(summary, row.names = FALSE)
