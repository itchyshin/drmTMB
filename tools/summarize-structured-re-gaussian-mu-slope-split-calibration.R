#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
overwrite <- "--overwrite=true" %in% args

root <- normalizePath(".", winslash = "/", mustWork = TRUE)
dashboard_dir <- file.path(root, "docs/dev-log/dashboard")
artifact_dir <- file.path(
  root,
  "docs/dev-log/simulation-artifacts/2026-06-29-gaussian-mu-slope-split-calibration-local"
)
base_pregrid_dir <- file.path(
  root,
  "docs/dev-log/simulation-artifacts/2026-06-29-gaussian-mu-slope-coverage-pregrid-local"
)
base_boundary_dir <- file.path(
  root,
  "docs/dev-log/simulation-artifacts/2026-06-29-gaussian-mu-slope-boundary-profile-diagnostic-local"
)
topup_pregrid_dir <- file.path(
  root,
  "docs/dev-log/simulation-artifacts/2026-06-29-gaussian-mu-slope-topup-sr475-local"
)
topup_boundary_dir <- file.path(
  root,
  "docs/dev-log/simulation-artifacts/2026-06-29-gaussian-mu-slope-topup-boundary-profile-local"
)

out_path <- file.path(
  dashboard_dir,
  "structured-re-gaussian-mu-slope-split-calibration.tsv"
)
artifact_summary_path <- file.path(
  artifact_dir,
  "structured-re-gaussian-mu-slope-split-calibration.tsv"
)
artifact_constants_path <- file.path(
  artifact_dir,
  "structured-re-gaussian-mu-slope-split-calibration-constants.tsv"
)

if (
  (file.exists(out_path) ||
    file.exists(artifact_summary_path) ||
    file.exists(artifact_constants_path)) &&
    !overwrite
) {
  stop("Output exists; pass --overwrite=true to replace it.", call. = FALSE)
}

read_tsv <- function(path) {
  utils::read.delim(
    path,
    sep = "\t",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
}

write_tsv <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  utils::write.table(
    x,
    file = path,
    sep = "\t",
    row.names = FALSE,
    quote = FALSE,
    na = ""
  )
}

rel_path <- function(path) {
  sub(paste0("^", gsub("([\\W])", "\\\\\\1", root), "/?"), "", path)
}

as_bool <- function(x) {
  if (is.logical(x)) {
    return(x)
  }
  as.character(x) == "TRUE"
}

fmt4 <- function(x) sprintf("%.4f", x)
fmt6 <- function(x) sprintf("%.6f", x)
mcse_proportion <- function(x) {
  x <- as.logical(x)
  sqrt(mean(x) * (1 - mean(x)) / length(x))
}

apply_boundary_overlay <- function(pregrid_path, boundary_path, slice_id) {
  pregrid <- read_tsv(pregrid_path)
  boundary <- read_tsv(boundary_path)
  key_cols <- c(
    "cell_id",
    "provider",
    "endpoint_member",
    "replicate_index",
    "seed",
    "parameter"
  )
  pregrid$key <- do.call(paste, c(pregrid[key_cols], sep = "\r"))
  boundary$key <- do.call(paste, c(boundary[key_cols], sep = "\r"))
  if (!all(boundary$key %in% pregrid$key)) {
    stop(
      slice_id,
      " boundary rows do not match the pregrid replicate artifact.",
      call. = FALSE
    )
  }

  hybrid <- pregrid
  hybrid$source_slice <- slice_id
  hybrid$hybrid_interval_channel <- "wald"
  hybrid$hybrid_low <- suppressWarnings(as.numeric(hybrid$conf.low))
  hybrid$hybrid_high <- suppressWarnings(as.numeric(hybrid$conf.high))
  hybrid$hybrid_usable_interval <- (as_bool(hybrid$usable_interval) &
    is.finite(hybrid$hybrid_low) &
    is.finite(hybrid$hybrid_high))

  idx <- match(boundary$key, hybrid$key)
  boundary_finite <- as_bool(boundary$profile_finite_interval)
  hybrid$hybrid_interval_channel[idx] <- ifelse(
    boundary_finite,
    "endpoint_profile",
    "endpoint_profile_failed"
  )
  hybrid$hybrid_low[idx] <- suppressWarnings(as.numeric(
    boundary$profile_lower
  ))
  hybrid$hybrid_high[idx] <- suppressWarnings(as.numeric(
    boundary$profile_upper
  ))
  hybrid$hybrid_usable_interval[idx] <- (boundary_finite &
    is.finite(hybrid$hybrid_low[idx]) &
    is.finite(hybrid$hybrid_high[idx]))
  hybrid
}

base_pregrid_path <- file.path(
  base_pregrid_dir,
  "structured-re-gaussian-mu-slope-coverage-pregrid-replicates.tsv"
)
base_boundary_path <- file.path(
  base_boundary_dir,
  "structured-re-gaussian-mu-slope-boundary-profile-diagnostic-detail.tsv"
)
topup_pregrid_path <- file.path(
  topup_pregrid_dir,
  "structured-re-gaussian-mu-slope-coverage-pregrid-replicates.tsv"
)
topup_boundary_path <- file.path(
  topup_boundary_dir,
  "structured-re-gaussian-mu-slope-boundary-profile-diagnostic-detail.tsv"
)

calibration <- apply_boundary_overlay(
  base_pregrid_path,
  base_boundary_path,
  "sr150_calibration"
)
validation <- apply_boundary_overlay(
  topup_pregrid_path,
  topup_boundary_path,
  "sr325_validation"
)
providers <- c("phylo", "relmat", "spatial")
calibration <- calibration[
  calibration$provider %in%
    providers &
    calibration$denominator_role == "pregrid_target",
  ,
  drop = FALSE
]
validation <- validation[
  validation$provider %in%
    providers &
    validation$denominator_role == "pregrid_target",
  ,
  drop = FALSE
]
calibration$truth_num <- suppressWarnings(as.numeric(calibration$truth))
validation$truth_num <- suppressWarnings(as.numeric(validation$truth))

estimate_constant <- function(endpoint_member) {
  x <- calibration[
    calibration$endpoint_member == endpoint_member &
      calibration$hybrid_usable_interval,
    ,
    drop = FALSE
  ]
  log_excess <- log(x$truth_num / x$hybrid_high)
  delta <- max(
    0,
    as.numeric(
      stats::quantile(
        log_excess,
        probs = 0.975,
        names = FALSE,
        type = 8,
        na.rm = TRUE
      )
    )
  )
  data.frame(
    endpoint_member = endpoint_member,
    calibration_n_usable = nrow(x),
    calibration_delta_log_upper = fmt6(delta),
    calibration_upper_multiplier = fmt4(exp(delta)),
    calibration_upper_miss = sum(log_excess > 0),
    calibration_upper_miss_rate = fmt6(mean(log_excess > 0)),
    stringsAsFactors = FALSE
  )
}

constants <- do.call(
  rbind,
  lapply(c("mu:(Intercept)", "mu:x"), estimate_constant)
)
row.names(constants) <- NULL

source_replicates <- paste(
  rel_path(base_pregrid_path),
  rel_path(topup_pregrid_path),
  sep = "; "
)
source_boundary_profiles <- paste(
  rel_path(base_boundary_path),
  rel_path(topup_boundary_path),
  sep = "; "
)

rows <- list()
row_i <- 1L
for (constant_i in seq_len(nrow(constants))) {
  endpoint <- constants$endpoint_member[[constant_i]]
  delta <- as.numeric(constants$calibration_delta_log_upper[[constant_i]])
  endpoint_validation <- validation[
    validation$endpoint_member == endpoint,
    ,
    drop = FALSE
  ]
  for (provider in providers) {
    x <- endpoint_validation[
      endpoint_validation$provider == provider,
      ,
      drop = FALSE
    ]
    high_calibrated <- x$hybrid_high * exp(delta)
    usable <- x$hybrid_usable_interval & is.finite(high_calibrated)
    covered <- usable &
      x$truth_num >= x$hybrid_low &
      x$truth_num <= high_calibrated
    lower_miss <- usable & x$truth_num < x$hybrid_low
    upper_miss <- usable & x$truth_num > high_calibrated
    coverage <- mean(covered)
    coverage_mcse <- mcse_proportion(covered)
    lower_rate <- mean(lower_miss)
    upper_rate <- mean(upper_miss)
    n_lower <- sum(lower_miss)
    n_upper <- sum(upper_miss)
    total_misses <- n_lower + n_upper
    failures <- character()
    if (coverage < 0.94) {
      failures <- c(failures, "coverage_below_0_94")
    }
    if (coverage > 0.985) {
      failures <- c(failures, "coverage_above_0_985")
    }
    if (upper_rate > 0.035) {
      failures <- c(failures, "upper_miss_rate_above_0_035")
    }
    if (lower_rate > 0.035) {
      failures <- c(failures, "lower_miss_rate_above_0_035")
    }
    if (n_upper > 2 * n_lower && total_misses >= 10L) {
      failures <- c(failures, "upper_lower_miss_ratio_above_2")
    }
    if (coverage_mcse > 0.01) {
      failures <- c(failures, "mcse_above_0_01")
    }
    gate_status <- if (length(failures)) {
      "holdout_gate_failed"
    } else {
      "holdout_gate_passed_screen_only"
    }
    rows[[row_i]] <- data.frame(
      calibration_id = paste0(
        "gaussian_mu_slope_split_calibration_",
        provider,
        "_",
        gsub("[^A-Za-z0-9]+", "_", endpoint)
      ),
      cell_id = x$cell_id[[1L]],
      provider = provider,
      endpoint_member = endpoint,
      direct_sd_target = x$direct_sd_target[[1L]],
      source_replicates = source_replicates,
      source_boundary_profiles = source_boundary_profiles,
      calibration_slice = "sr150_base",
      validation_slice = "sr151_475_topup_holdout",
      calibration_n_usable = constants$calibration_n_usable[[constant_i]],
      calibration_delta_log_upper = constants$calibration_delta_log_upper[[
        constant_i
      ]],
      calibration_upper_multiplier = constants$calibration_upper_multiplier[[
        constant_i
      ]],
      validation_n_replicates = nrow(x),
      validation_n_usable = sum(usable),
      validation_finite_rate = fmt4(mean(usable)),
      validation_coverage = fmt4(coverage),
      validation_mcse = fmt6(coverage_mcse),
      validation_lower_miss = n_lower,
      validation_upper_miss = n_upper,
      validation_lower_miss_rate = fmt6(lower_rate),
      validation_upper_miss_rate = fmt6(upper_rate),
      holdout_gate_status = gate_status,
      gate_failures = if (length(failures)) {
        paste(failures, collapse = ";")
      } else {
        "none"
      },
      smoke_decision = if (length(failures)) {
        "do_not_smoke_holdout_failed"
      } else {
        "do_not_smoke_without_fisher_rose_noether"
      },
      promotion_decision = "do_not_promote",
      evidence_url = "docs/dev-log/after-task/2026-06-29-q-series-gaussian-mu-slope-split-calibration.md",
      artifact_dir = rel_path(artifact_dir),
      claim_boundary = paste(
        "Split-sample calibration replay only; this promotes exactly no Q-Series row;",
        "constants are learned on SR150 and validated on SR325 holdout;",
        "no inference_ready, supported, sigma, q2, q4/q8, non-Gaussian, REML, AI-REML, or public support claim."
      ),
      next_gate = paste(
        "Do not run Totoro/FIIA/DRAC or edit the TSV until Fisher/Rose/Noether derive a principled rule that passes every holdout target without provider-specific constants."
      ),
      stringsAsFactors = FALSE
    )
    row_i <- row_i + 1L
  }
}

summary <- do.call(rbind, rows)
row.names(summary) <- NULL

write_tsv(summary, out_path)
write_tsv(summary, artifact_summary_path)
write_tsv(constants, artifact_constants_path)

message(
  "Wrote ",
  nrow(summary),
  " split-calibration rows to ",
  rel_path(out_path)
)
message(
  "Wrote ",
  nrow(constants),
  " calibration constants to ",
  rel_path(artifact_constants_path)
)
