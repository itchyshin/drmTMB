#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
overwrite <- "--overwrite=true" %in% args

root <- normalizePath(".", winslash = "/", mustWork = TRUE)
dashboard_dir <- file.path(root, "docs/dev-log/dashboard")
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
  "structured-re-gaussian-mu-slope-hybrid-sr475-audit.tsv"
)
target_out_path <- file.path(
  topup_pregrid_dir,
  "structured-re-gaussian-mu-slope-hybrid-sr475-target-summary.tsv"
)

if ((file.exists(out_path) || file.exists(target_out_path)) && !overwrite) {
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
clean_text <- function(x) gsub("[[:space:]]+", " ", trimws(x))

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
  hybrid$hybrid_interval_status <- hybrid$interval_status
  hybrid$hybrid_usable_interval <- as_bool(hybrid$usable_interval)
  hybrid$hybrid_covered <- as_bool(hybrid$covered)
  hybrid$hybrid_lower_miss <- as_bool(hybrid$lower_miss)
  hybrid$hybrid_upper_miss <- as_bool(hybrid$upper_miss)

  idx <- match(boundary$key, hybrid$key)
  boundary_finite <- as_bool(boundary$profile_finite_interval)
  hybrid$hybrid_interval_status[idx] <- ifelse(
    boundary_finite,
    "profile_boundary_finite",
    "profile_boundary_failed"
  )
  hybrid$hybrid_usable_interval[idx] <- boundary_finite
  hybrid$hybrid_covered[idx] <- as_bool(boundary$profile_covered)
  hybrid$hybrid_lower_miss[idx] <- as_bool(boundary$profile_lower_miss)
  hybrid$hybrid_upper_miss[idx] <- as_bool(boundary$profile_upper_miss)

  list(hybrid = hybrid, boundary = boundary)
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

base <- apply_boundary_overlay(
  base_pregrid_path,
  base_boundary_path,
  "sr150_base"
)
topup <- apply_boundary_overlay(
  topup_pregrid_path,
  topup_boundary_path,
  "sr151_475_topup"
)

hybrid <- rbind(
  base$hybrid[base$hybrid$provider %in% c("phylo", "relmat", "spatial"), ],
  topup$hybrid
)
boundary <- rbind(
  base$boundary[base$boundary$provider %in% c("phylo", "relmat", "spatial"), ],
  topup$boundary
)
eligible <- hybrid[hybrid$denominator_role == "pregrid_target", , drop = FALSE]

target_rows <- do.call(
  rbind,
  lapply(
    split(
      eligible,
      paste(eligible$provider, eligible$endpoint_member, sep = "\r")
    ),
    function(x) {
      covered <- x$hybrid_covered & x$hybrid_usable_interval
      data.frame(
        cell_id = x$cell_id[[1L]],
        provider = x$provider[[1L]],
        endpoint_member = x$endpoint_member[[1L]],
        direct_sd_target = x$direct_sd_target[[1L]],
        n_eligible_target_replicates = nrow(x),
        n_usable_hybrid_intervals = sum(x$hybrid_usable_interval),
        finite_interval_rate = fmt4(mean(x$hybrid_usable_interval)),
        n_covered = sum(covered),
        hybrid_coverage_all = fmt4(mean(covered)),
        hybrid_coverage_mcse = fmt6(mcse_proportion(covered)),
        n_lower_miss = sum(x$hybrid_lower_miss & x$hybrid_usable_interval),
        n_upper_miss = sum(x$hybrid_upper_miss & x$hybrid_usable_interval),
        n_unusable_interval = sum(!x$hybrid_usable_interval),
        target_signal = if (mcse_proportion(covered) <= 0.01) {
          "mcse_met"
        } else {
          "topup_required"
        },
        stringsAsFactors = FALSE
      )
    }
  )
)
row.names(target_rows) <- NULL

provider_label <- c(
  phylo = "phylo",
  relmat = "relmat K-matrix",
  spatial = "fixed-covariance spatial"
)
provider_boundary <- c(
  phylo = "",
  relmat = "no Q bridge marshalling, ",
  spatial = "no range-estimating spatial support, "
)

provider_rows <- do.call(
  rbind,
  lapply(split(eligible, eligible$provider), function(x) {
    provider <- x$provider[[1L]]
    cell_id <- x$cell_id[[1L]]
    usable <- x$hybrid_usable_interval
    covered <- x$hybrid_covered & usable
    provider_targets <- target_rows[
      target_rows$provider == provider,
      ,
      drop = FALSE
    ]
    boundary_rows <- boundary[boundary$provider == provider, , drop = FALSE]
    n_profile_failed <- sum(
      boundary_rows$profile_conf_status == "profile_failed"
    )
    n_profile_finite <- sum(as_bool(boundary_rows$profile_finite_interval))
    n_upper <- sum(x$hybrid_upper_miss & usable)
    n_lower <- sum(x$hybrid_lower_miss & usable)
    worst_i <- which.min(as.numeric(provider_targets$hybrid_coverage_all))
    worst <- provider_targets[worst_i, , drop = FALSE]
    evidence_basis <- sprintf(
      "Hybrid Wald+endpoint-profile SR475 denominator: %s/%s covered, %s/%s usable intervals, coverage_all %s, coverage_usable %s, MCSE %s, misses lower=%s upper=%s, boundary profiles finite=%s failed=%s.",
      sum(covered),
      nrow(x),
      sum(usable),
      nrow(x),
      fmt4(mean(covered)),
      fmt4(sum(covered) / sum(usable)),
      fmt6(mcse_proportion(covered)),
      n_lower,
      n_upper,
      n_profile_finite,
      n_profile_failed
    )
    data.frame(
      audit_id = paste0("gaussian_mu_slope_hybrid_sr475_", provider),
      cell_id = cell_id,
      provider = provider,
      source_pregrid = rel_path(base_pregrid_path),
      source_boundary_profile = rel_path(base_boundary_path),
      source_topup_pregrid = rel_path(topup_pregrid_path),
      source_topup_boundary_profile = rel_path(topup_boundary_path),
      n_seed_replicates = length(unique(x$replicate_index)),
      n_eligible_target_replicates = nrow(x),
      n_usable_hybrid_intervals = sum(usable),
      finite_interval_rate = fmt4(mean(usable)),
      n_profile_boundary_rows = nrow(boundary_rows),
      n_profile_finite = n_profile_finite,
      n_profile_failed = n_profile_failed,
      n_profile_covered = sum(as_bool(boundary_rows$profile_covered)),
      n_covered = sum(covered),
      hybrid_coverage_all = fmt4(mean(covered)),
      hybrid_coverage_usable = fmt4(sum(covered) / sum(usable)),
      hybrid_coverage_mcse = fmt6(mcse_proportion(covered)),
      n_lower_miss = n_lower,
      n_upper_miss = n_upper,
      miss_balance = sprintf("lower=%s upper=%s", n_lower, n_upper),
      worst_target = worst$endpoint_member,
      worst_target_coverage = worst$hybrid_coverage_all,
      worst_target_mcse = worst$hybrid_coverage_mcse,
      worst_target_miss_balance = sprintf(
        "lower=%s upper=%s",
        worst$n_lower_miss,
        worst$n_upper_miss
      ),
      widget_state = "mcse_met_upper_tail_blocked",
      admission_status = "hybrid_sr475_upper_tail_blocked",
      evidence_basis = evidence_basis,
      stability_signal = "hybrid_sr475_all_fits_converged_pdhess_true",
      inference_signal = "not_inference_ready_hybrid_sr475_upper_tail_imbalance_or_profile_failure",
      linked_fit_status = "point_fit",
      linked_interval_status = "planned",
      linked_coverage_status = "planned",
      promotion_decision = "do_not_promote",
      evidence_url = "docs/dev-log/after-task/2026-06-29-q-series-gaussian-mu-slope-sr475-topup.md",
      artifact_dir = rel_path(topup_pregrid_dir),
      claim_boundary = clean_text(paste0(
        provider_label[[provider]],
        " Gaussian q1 mu one-slope hybrid SR475 audit only; ",
        provider_boundary[[provider]],
        "MCSE-qualified retained denominator but upper-tail miss imbalance remains, ",
        "no inference_ready, supported, q2/q4/q8, sigma, non-Gaussian, REML, ",
        "AI-REML, broad bridge support, or public support promoted."
      )),
      next_gate = "Fisher/Rose review of one-sided misses and profile failures before any support-cell status edit; likely skew-aware or boundary-aware interval work before promotion.",
      stringsAsFactors = FALSE
    )
  })
)

provider_rows <- provider_rows[
  match(c("phylo", "relmat", "spatial"), provider_rows$provider),
]
row.names(provider_rows) <- NULL
write_tsv(provider_rows, out_path)
write_tsv(
  target_rows[order(target_rows$provider, target_rows$endpoint_member), ],
  target_out_path
)
cat("wrote", out_path, "with", nrow(provider_rows), "rows\n")
cat("wrote", target_out_path, "with", nrow(target_rows), "rows\n")
