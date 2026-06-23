#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
value_arg <- function(name, default) {
  prefix <- paste0("--", name, "=")
  hit <- grep(paste0("^", prefix), args, value = TRUE)
  if (!length(hit)) {
    return(default)
  }
  sub(prefix, "", hit[[1L]], fixed = TRUE)
}

n_rep <- as.integer(value_arg("n-rep", "0"))
seed_start <- as.integer(value_arg("seed-start", "202607001"))
if (is.na(n_rep) || n_rep != 0L) {
  stop(
    "This artifact is a dry-run contract only; use --n-rep=0.",
    call. = FALSE
  )
}
if (is.na(seed_start) || seed_start <= 0L) {
  stop("--seed-start must be a positive integer.", call. = FALSE)
}

script_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
artifact_dir <- if (length(script_arg)) {
  dirname(normalizePath(sub("^--file=", "", script_arg[[1L]]), mustWork = TRUE))
} else {
  getwd()
}

out <- data.frame(
  dry_run_id = "q4_stabilized_calibrated_grid_dry_run",
  slice_id = "SR150",
  target = "gaussian_q4_phylo",
  requested_n_rep = n_rep,
  seed_start = seed_start,
  sd_scale_levels = "0.35;0.50",
  direct_sd_targets = paste(
    c("sd_mu1", "sd_mu2", "sd_sigma1", "sd_sigma2"),
    collapse = ";"
  ),
  derived_correlation_targets = paste(
    c(
      "cor_mu1_mu2",
      "cor_mu1_sigma1",
      "cor_mu1_sigma2",
      "cor_mu2_sigma1",
      "cor_mu2_sigma2",
      "cor_sigma1_sigma2"
    ),
    collapse = ";"
  ),
  denominator_fields = paste(
    c(
      "n_total",
      "n_fit_ok",
      "n_converged",
      "n_pdhess",
      "n_profile_attempted",
      "n_profile_finite",
      "n_profile_warning",
      "n_gradient_warning",
      "n_interval_unavailable",
      "n_failed_fit"
    ),
    collapse = ";"
  ),
  warning_fields = paste(
    c(
      "profile_warning_context",
      "gradient_warning_context",
      "regularize_values_duplicate_x_count",
      "failed_fit_message",
      "unavailable_reason"
    ),
    collapse = ";"
  ),
  output_schema = paste(
    c(
      "replicate_id",
      "seed",
      "sd_scale",
      "axis",
      "target_kind",
      "fit_status",
      "interval_method",
      "interval_status",
      "lower",
      "upper",
      "warning_context",
      "failure_reason",
      "coverage_indicator",
      "coverage_mcse",
      "failure_rate_mcse"
    ),
    collapse = ";"
  ),
  status = "dry_run_only",
  claim_boundary = paste(
    "Dry-run grid contract only; no q4 interval reliability, interval coverage,",
    "q4 REML, AI-REML, or broad bridge support is promoted."
  ),
  next_gate = paste(
    "Replace dry-run rows with calibrated replicate outputs only after the",
    "denominator, warning, and MCSE fields are retained."
  )
)

path <- file.path(artifact_dir, "q4-stabilized-calibrated-grid-dry-run.tsv")
utils::write.table(out, path, sep = "\t", row.names = FALSE, quote = FALSE)
message("Wrote ", path)
