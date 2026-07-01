#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
overwrite <- "--overwrite=true" %in% args

root <- normalizePath(".", winslash = "/", mustWork = TRUE)
dashboard_dir <- file.path(root, "docs/dev-log/dashboard")
artifact_dir <- file.path(
  root,
  "docs/dev-log/simulation-artifacts/2026-06-29-gaussian-mu-slope-rule-screen-local"
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
  "structured-re-gaussian-mu-slope-rule-screen.tsv"
)
artifact_summary_path <- file.path(
  artifact_dir,
  "structured-re-gaussian-mu-slope-rule-screen.tsv"
)
artifact_target_path <- file.path(
  artifact_dir,
  "structured-re-gaussian-mu-slope-rule-screen-target-detail.tsv"
)

if (
  (file.exists(out_path) ||
    file.exists(artifact_summary_path) ||
    file.exists(artifact_target_path)) &&
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
fmt2 <- function(x) sprintf("%.2f", x)
mcse_proportion <- function(x) {
  x <- as.logical(x)
  sqrt(mean(x) * (1 - mean(x)) / length(x))
}
factor_slug <- function(x) {
  gsub("\\.", "p", fmt2(x))
}
ratio_text <- function(upper, lower) {
  if (lower == 0L && upper > 0L) {
    return("Inf")
  }
  if (lower == 0L && upper == 0L) {
    return("0.0000")
  }
  fmt4(upper / lower)
}
ratio_numeric <- function(upper, lower) {
  ifelse(lower == 0L, ifelse(upper == 0L, 0, Inf), upper / lower)
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

hybrid <- rbind(
  apply_boundary_overlay(base_pregrid_path, base_boundary_path, "sr150_base"),
  apply_boundary_overlay(
    topup_pregrid_path,
    topup_boundary_path,
    "sr151_475_topup"
  )
)
hybrid <- hybrid[
  hybrid$provider %in%
    c("phylo", "relmat", "spatial") &
    hybrid$denominator_role == "pregrid_target",
  ,
  drop = FALSE
]
hybrid$truth_num <- suppressWarnings(as.numeric(hybrid$truth))

candidates <- rbind(
  data.frame(
    candidate_rule = "current_hybrid",
    candidate_factor = 1,
    stringsAsFactors = FALSE
  ),
  expand.grid(
    candidate_rule = c(
      "upper_endpoint_multiplier",
      "log_width_multiplier",
      "profile_boundary_upper_multiplier"
    ),
    candidate_factor = c(1.25, 1.5, 2, 3),
    stringsAsFactors = FALSE
  )
)
candidates$candidate_label <- ifelse(
  candidates$candidate_rule == "current_hybrid",
  "current hybrid Wald/profile",
  paste0(
    gsub("_", " ", candidates$candidate_rule),
    " x",
    fmt2(candidates$candidate_factor)
  )
)

candidate_bounds <- function(x, candidate_rule, candidate_factor) {
  low <- x$hybrid_low
  high <- x$hybrid_high
  usable <- x$hybrid_usable_interval

  if (candidate_rule == "upper_endpoint_multiplier") {
    high <- high * candidate_factor
  } else if (candidate_rule == "log_width_multiplier") {
    positive <- usable & low > 0 & high > 0
    center <- sqrt(low[positive] * high[positive])
    half_width <- log(high[positive] / low[positive]) / 2
    low[positive] <- exp(log(center) - candidate_factor * half_width)
    high[positive] <- exp(log(center) + candidate_factor * half_width)

    boundary_like <- usable & !(low > 0 & high > 0)
    high[boundary_like] <- high[boundary_like] * candidate_factor
  } else if (candidate_rule == "profile_boundary_upper_multiplier") {
    profile_rows <- usable & x$hybrid_interval_channel == "endpoint_profile"
    high[profile_rows] <- high[profile_rows] * candidate_factor
  } else if (candidate_rule != "current_hybrid") {
    stop("Unknown candidate rule: ", candidate_rule, call. = FALSE)
  }

  usable <- usable & is.finite(low) & is.finite(high)
  list(low = low, high = high, usable = usable)
}

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

target_rows <- list()
summary_rows <- list()
target_i <- 1L
summary_i <- 1L

for (candidate_i in seq_len(nrow(candidates))) {
  candidate <- candidates[candidate_i, , drop = FALSE]
  screen_id <- paste0(
    "gaussian_mu_slope_rule_screen_",
    candidate$candidate_rule,
    "_",
    factor_slug(candidate$candidate_factor)
  )
  bounds <- candidate_bounds(
    hybrid,
    candidate$candidate_rule,
    candidate$candidate_factor
  )

  candidate_target_rows <- list()
  for (target_key in split(
    seq_len(nrow(hybrid)),
    paste(hybrid$provider, hybrid$endpoint_member, sep = "\r")
  )) {
    covered <- (bounds$usable[target_key] &
      hybrid$truth_num[target_key] >= bounds$low[target_key] &
      hybrid$truth_num[target_key] <= bounds$high[target_key])
    lower_miss <- (bounds$usable[target_key] &
      hybrid$truth_num[target_key] < bounds$low[target_key])
    upper_miss <- (bounds$usable[target_key] &
      hybrid$truth_num[target_key] > bounds$high[target_key])
    n_lower <- sum(lower_miss)
    n_upper <- sum(upper_miss)
    coverage <- mean(covered)
    coverage_mcse <- mcse_proportion(covered)
    target_status <- if (coverage < 0.95) {
      "target_coverage_below_0_95"
    } else if (n_upper > n_lower) {
      "target_upper_tail_blocked"
    } else if (candidate$candidate_factor >= 3) {
      "target_large_multiplier_screen_only"
    } else {
      "target_screen_only_not_promoted"
    }
    detail <- data.frame(
      screen_id = screen_id,
      target_id = paste0(
        screen_id,
        "_",
        hybrid$provider[target_key][[1L]],
        "_",
        gsub("[^A-Za-z0-9]+", "_", hybrid$endpoint_member[target_key][[1L]])
      ),
      cell_id = hybrid$cell_id[target_key][[1L]],
      provider = hybrid$provider[target_key][[1L]],
      endpoint_member = hybrid$endpoint_member[target_key][[1L]],
      direct_sd_target = hybrid$direct_sd_target[target_key][[1L]],
      n_replicates = length(target_key),
      n_usable_intervals = sum(bounds$usable[target_key]),
      coverage = fmt4(coverage),
      coverage_mcse = fmt6(coverage_mcse),
      n_lower_miss = n_lower,
      n_upper_miss = n_upper,
      upper_lower_miss_ratio = ratio_text(n_upper, n_lower),
      target_status = target_status,
      stringsAsFactors = FALSE
    )
    target_rows[[target_i]] <- detail
    candidate_target_rows[[length(candidate_target_rows) + 1L]] <- detail
    target_i <- target_i + 1L
  }

  candidate_target <- do.call(rbind, candidate_target_rows)
  coverage_num <- as.numeric(candidate_target$coverage)
  mcse_num <- as.numeric(candidate_target$coverage_mcse)
  lower_num <- as.integer(candidate_target$n_lower_miss)
  upper_num <- as.integer(candidate_target$n_upper_miss)
  ratio_num <- ratio_numeric(upper_num, lower_num)
  all_coverage_ge_0_95 <- all(coverage_num >= 0.95)
  all_mcse_le_0_01 <- all(mcse_num <= 0.01)
  n_targets_upper_gt_lower <- sum(upper_num > lower_num)
  large_factor <- candidate$candidate_factor >= 3
  screen_status <- if (candidate$candidate_rule == "current_hybrid") {
    "current_upper_tail_blocked"
  } else if (!all_coverage_ge_0_95) {
    "coverage_below_0_95_blocked"
  } else if (n_targets_upper_gt_lower > 0L) {
    "upper_tail_blocker_remains"
  } else if (large_factor) {
    "large_ad_hoc_multiplier_screen_only"
  } else {
    "screen_only_not_smoke_ready"
  }
  smoke_decision <- switch(
    screen_status,
    current_upper_tail_blocked = "do_not_smoke_current_blocked",
    coverage_below_0_95_blocked = "do_not_smoke_coverage_blocked",
    upper_tail_blocker_remains = "do_not_smoke_upper_tail_blocked",
    large_ad_hoc_multiplier_screen_only = "do_not_smoke_ad_hoc_large_multiplier",
    "do_not_smoke_without_fisher_rose"
  )
  summary_rows[[summary_i]] <- data.frame(
    screen_id = screen_id,
    candidate_rule = candidate$candidate_rule,
    candidate_factor = fmt2(candidate$candidate_factor),
    candidate_label = candidate$candidate_label,
    source_replicates = source_replicates,
    source_boundary_profiles = source_boundary_profiles,
    n_target_rows = nrow(candidate_target),
    n_target_replicates = sum(candidate_target$n_replicates),
    n_usable_intervals = sum(candidate_target$n_usable_intervals),
    min_target_coverage = fmt4(min(coverage_num)),
    max_target_coverage = fmt4(max(coverage_num)),
    max_target_mcse = fmt6(max(mcse_num)),
    total_lower_miss = sum(lower_num),
    total_upper_miss = sum(upper_num),
    max_target_upper_lower_ratio = if (any(is.infinite(ratio_num))) {
      "Inf"
    } else {
      fmt4(max(ratio_num))
    },
    n_targets_upper_gt_lower = n_targets_upper_gt_lower,
    n_targets_coverage_ge_0_95 = sum(coverage_num >= 0.95),
    n_targets_mcse_le_0_01 = sum(mcse_num <= 0.01),
    screen_status = screen_status,
    smoke_decision = smoke_decision,
    promotion_decision = "do_not_promote",
    evidence_url = "docs/dev-log/after-task/2026-06-29-q-series-gaussian-mu-slope-rule-screen.md",
    artifact_dir = rel_path(artifact_dir),
    claim_boundary = paste(
      "Rule-screen replay only; this promotes exactly no Q-Series row;",
      "candidate intervals are post hoc retained-artifact screens and are not confint() defaults;",
      "no inference_ready, supported, sigma, q2, q4/q8, non-Gaussian, REML, AI-REML, or public support claim."
    ),
    next_gate = paste(
      "Fisher/Rose/Noether must derive and accept a principled skew-aware or boundary-aware interval rule before any Totoro/FIIA smoke, DRAC top-up, TSV promotion, or public wording change."
    ),
    stringsAsFactors = FALSE
  )
  summary_i <- summary_i + 1L
}

summary <- do.call(rbind, summary_rows)
target_detail <- do.call(rbind, target_rows)
row.names(summary) <- NULL
row.names(target_detail) <- NULL

write_tsv(summary, out_path)
write_tsv(summary, artifact_summary_path)
write_tsv(target_detail, artifact_target_path)

message("Wrote ", nrow(summary), " rule-screen rows to ", rel_path(out_path))
message(
  "Wrote ",
  nrow(target_detail),
  " target-detail rows to ",
  rel_path(artifact_target_path)
)
