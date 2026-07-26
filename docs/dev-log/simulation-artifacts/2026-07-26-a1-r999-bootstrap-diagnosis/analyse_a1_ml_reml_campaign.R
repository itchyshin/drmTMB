#!/usr/bin/env Rscript
# Final paired analysis for the completed scalar A1 ML-versus-REML campaign.
# This consumes an already authenticated campaign directory; it never launches fits.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) stop("Usage: analyse_a1_ml_reml_campaign.R <result_dir>", call. = FALSE)
result_dir <- args[[1L]]
file_arg <- grep("^--file=", commandArgs(), value = TRUE)
script_dir <- if (length(file_arg)) dirname(normalizePath(sub("^--file=", "", file_arg[[1L]]))) else getwd()
source(file.path(script_dir, "a1_ml_reml_common.R"))

files <- list.files(result_dir, pattern = "^a1_ml_reml_g(10|25|50)_n10_sd05_o[0-9]{4}\\.csv$", full.names = TRUE)
if (!length(files)) stop("No ML-REML campaign shards found.", call. = FALSE)
x <- do.call(rbind, lapply(files, read.csv, stringsAsFactors = FALSE))
a1_ml_reml_validate_expected_grid(x, a1_ml_reml_expected_grid(1000L))
summary <- a1_ml_reml_directional_summary(x)

paired <- do.call(rbind, lapply(split(x, x$cell_id), function(one) {
  ml <- one[one$estimator == "ML", , drop = FALSE]
  reml <- one[one$estimator == "REML", , drop = FALSE]
  key <- c("seed", "attempt_id")
  ml <- ml[order(ml$seed, ml$attempt_id), , drop = FALSE]
  reml <- reml[order(reml$seed, reml$attempt_id), , drop = FALSE]
  if (!isTRUE(all.equal(unname(as.matrix(ml[key])), unname(as.matrix(reml[key])), check.attributes = FALSE))) {
    stop("Paired estimator keys are not aligned.", call. = FALSE)
  }
  directional <- function(z) as.integer(z$profile_miss_direction == "upper") - as.integer(z$profile_miss_direction == "lower")
  reduction <- directional(ml) - directional(reml)
  coverage_change <- as.integer(reml$profile_covers %in% TRUE) - as.integer(ml$profile_covers %in% TRUE)
  set.seed(20260726L + ml$n_groups[[1L]])
  boot <- vapply(seq_len(9999L), function(i) mean(reduction[sample.int(length(reduction), length(reduction), replace = TRUE)]), numeric(1))
  reduction_mean <- mean(reduction)
  ci <- unname(stats::quantile(boot, c(0.025, 0.975), names = FALSE, type = 8))
  coverage_change_mean <- mean(coverage_change)
  data.frame(
    cell_id = ml$cell_id[[1L]], n_groups = ml$n_groups[[1L]], n_attempts = nrow(ml),
    directional_gap_ml = mean(directional(ml)), directional_gap_reml = mean(directional(reml)),
    paired_gap_reduction = reduction_mean, paired_reduction_ci_lower = ci[[1L]], paired_reduction_ci_upper = ci[[2L]],
    coverage_ml = mean(ml$profile_covers %in% TRUE), coverage_reml = mean(reml$profile_covers %in% TRUE),
    coverage_change_reml_minus_ml = coverage_change_mean,
    material_contributor = reduction_mean >= 0.02 && ci[[1L]] > 0 && coverage_change_mean > -0.02,
    stringsAsFactors = FALSE
  )
}))
rownames(paired) <- NULL
write.csv(summary, file.path(result_dir, "a1_ml_reml_campaign_summary.csv"), row.names = FALSE)
write.csv(paired, file.path(result_dir, "a1_ml_reml_paired_decision.csv"), row.names = FALSE)
print(summary, row.names = FALSE)
print(paired, row.names = FALSE)
