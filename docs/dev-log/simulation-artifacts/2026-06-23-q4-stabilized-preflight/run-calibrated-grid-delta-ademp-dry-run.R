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

n_rep <- as.integer(value_arg("n-rep", "500"))
seed_start <- as.integer(value_arg("seed-start", "202607500"))
sd_scales <- as.numeric(strsplit(value_arg("sd-scales", "0.35,0.50"), ",")[[
  1L
]])
nominal_coverage <- as.numeric(value_arg("nominal-coverage", "0.95"))
coverage_mcse_threshold <- as.numeric(value_arg(
  "coverage-mcse-threshold",
  "0.01"
))
failure_rate_reference <- as.numeric(value_arg(
  "failure-rate-reference",
  "0.05"
))

if (is.na(n_rep) || n_rep < 475L) {
  stop(
    "The ADEMP dry-run requires --n-rep >= 475 to meet the MCSE gate.",
    call. = FALSE
  )
}
if (is.na(seed_start) || seed_start <= 0L) {
  stop("--seed-start must be a positive integer.", call. = FALSE)
}
if (!length(sd_scales) || any(is.na(sd_scales)) || any(sd_scales <= 0)) {
  stop(
    "--sd-scales must be a comma-separated list of positive numbers.",
    call. = FALSE
  )
}
if (
  is.na(nominal_coverage) ||
    nominal_coverage <= 0 ||
    nominal_coverage >= 1
) {
  stop("--nominal-coverage must be in (0, 1).", call. = FALSE)
}
if (
  is.na(coverage_mcse_threshold) ||
    coverage_mcse_threshold <= 0 ||
    coverage_mcse_threshold >= 0.5
) {
  stop("--coverage-mcse-threshold must be in (0, 0.5).", call. = FALSE)
}
if (
  is.na(failure_rate_reference) ||
    failure_rate_reference <= 0 ||
    failure_rate_reference >= 1
) {
  stop("--failure-rate-reference must be in (0, 1).", call. = FALSE)
}

script_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
artifact_dir <- if (length(script_arg)) {
  dirname(normalizePath(sub("^--file=", "", script_arg[[1L]]), mustWork = TRUE))
} else {
  getwd()
}

axis_pairs <- c(
  "mu1_mu2",
  "mu1_sigma1",
  "mu1_sigma2",
  "mu2_sigma1",
  "mu2_sigma2",
  "sigma1_sigma2"
)
target_names <- paste0("cor_", axis_pairs)
coverage_mcse_at_nominal <- sqrt(
  nominal_coverage * (1 - nominal_coverage) / n_rep
)
failure_rate_mcse_at_reference <- sqrt(
  failure_rate_reference * (1 - failure_rate_reference) / n_rep
)
scale_tag <- function(x) {
  gsub("[.]", "", sprintf("%0.2f", x))
}

grid <- expand.grid(
  sd_scale = sd_scales,
  target_name = target_names,
  KEEP.OUT.ATTRS = FALSE,
  stringsAsFactors = FALSE
)
grid$axis_pair <- sub("^cor_", "", grid$target_name)
grid <- grid[order(grid$sd_scale, grid$axis_pair), , drop = FALSE]

claim_boundary <- paste(
  "Q4 derived-correlation ADEMP delta-grid dry-run contract only; no q4",
  "interval reliability, interval coverage, q4 REML, AI-REML, or broad bridge",
  "support is promoted."
)
output_schema <- paste(
  c(
    "replicate_id",
    "seed",
    "sd_scale",
    "axis_pair",
    "target_name",
    "target_kind",
    "true_value",
    "fit_status",
    "convergence",
    "converged",
    "pdHess",
    "max_gradient",
    "warning_context",
    "failure_reason",
    "theta_covariance_status",
    "corpairs_estimate",
    "report_estimate",
    "delta_se",
    "lower",
    "upper",
    "interval_status",
    "boundary_clamped",
    "coverage_indicator",
    "coverage_mcse",
    "failure_rate_mcse",
    "mcse_status"
  ),
  collapse = ";"
)

out <- data.frame(
  dry_run_id = paste0(
    "q4_delta_ademp_sd",
    scale_tag(grid$sd_scale),
    "_",
    grid$axis_pair
  ),
  slice_id = "SR150",
  target = "gaussian_q4_phylo",
  sd_scale = grid$sd_scale,
  axis_pair = grid$axis_pair,
  target_name = grid$target_name,
  target_kind = "derived_correlation",
  true_value = 0.05,
  planned_n_rep = n_rep,
  seed_start = seed_start,
  seed_end = seed_start + n_rep - 1L,
  planned_seed_scale_cells = n_rep * length(sd_scales),
  planned_target_rows = n_rep * length(sd_scales) * length(target_names),
  nominal_coverage = sprintf("%.2f", nominal_coverage),
  coverage_mcse_threshold = sprintf("%.3f", coverage_mcse_threshold),
  coverage_mcse_at_nominal = sprintf("%.6f", coverage_mcse_at_nominal),
  failure_rate_reference = sprintf("%.2f", failure_rate_reference),
  failure_rate_mcse_at_reference = sprintf(
    "%.6f",
    failure_rate_mcse_at_reference
  ),
  interval_method = "wald_delta_finite_difference",
  denominator_policy = paste0(
    "retain_fit_errors_nonconvergence_pdHess_false_warnings_unavailable_",
    "intervals_boundary_clamped_and_finite_rows"
  ),
  boundary_clamp_policy = "count_clamped_rows_separately_and_keep_in_denominator",
  warning_policy = "count_warning_context_by_seed_scale_target",
  failure_policy = "per_seed_scale_target_failure_reason_required",
  mcse_policy = paste(
    "coverage_mcse_threshold_0.01_at_nominal_0.95;",
    "failure_rate_mcse_reported_for_observed_and_reference_rates"
  ),
  output_schema = output_schema,
  status = "dry_run_contract",
  claim_boundary = claim_boundary,
  next_gate = paste(
    "Run the calibrated grid with resumable per-cell outputs and summarise",
    "observed coverage, failure, warning, and boundary-clamp rates with MCSE."
  ),
  stringsAsFactors = FALSE
)

path <- file.path(
  artifact_dir,
  "q4-derived-correlation-delta-grid-ademp-dry-run.tsv"
)
utils::write.table(
  out,
  file = path,
  sep = "\t",
  row.names = FALSE,
  quote = FALSE
)
message("Wrote ", path)
