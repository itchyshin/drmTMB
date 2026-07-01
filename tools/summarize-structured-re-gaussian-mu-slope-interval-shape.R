#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
overwrite <- "--overwrite=true" %in% args

root <- normalizePath(".", winslash = "/", mustWork = TRUE)
dashboard_dir <- file.path(root, "docs/dev-log/dashboard")
artifact_dir <- file.path(
  root,
  "docs/dev-log/simulation-artifacts/2026-06-29-gaussian-mu-slope-interval-shape-local"
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
  "structured-re-gaussian-mu-slope-interval-shape-diagnostic.tsv"
)
artifact_summary_path <- file.path(
  artifact_dir,
  "structured-re-gaussian-mu-slope-interval-shape-diagnostic.tsv"
)
artifact_miss_path <- file.path(
  artifact_dir,
  "structured-re-gaussian-mu-slope-interval-shape-upper-miss-rows.tsv"
)

if (
  (file.exists(out_path) ||
    file.exists(artifact_summary_path) ||
    file.exists(artifact_miss_path)) &&
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
fmtg <- function(x) {
  if (length(x) == 0L || all(is.na(x))) {
    return("NA")
  }
  formatC(x, digits = 4L, format = "fg", flag = "#")
}
clean_text <- function(x) gsub("[[:space:]]+", " ", trimws(x))
mcse_proportion <- function(x) {
  x <- as.logical(x)
  sqrt(mean(x) * (1 - mean(x)) / length(x))
}
endpoint_slug <- function(x) {
  x <- gsub("mu:\\(Intercept\\)", "mu_intercept", x)
  x <- gsub("mu:x", "mu_x", x)
  gsub("[^A-Za-z0-9]+", "_", x)
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
    stop(slice_id, " boundary rows do not match the pregrid artifact.")
  }

  hybrid <- pregrid
  hybrid$source_slice <- slice_id
  hybrid$hybrid_interval_channel <- "wald"
  hybrid$hybrid_usable_interval <- as_bool(hybrid$usable_interval)
  hybrid$hybrid_covered <- as_bool(hybrid$covered)
  hybrid$hybrid_lower_miss <- as_bool(hybrid$lower_miss)
  hybrid$hybrid_upper_miss <- as_bool(hybrid$upper_miss)
  hybrid$hybrid_estimate <- suppressWarnings(as.numeric(hybrid$estimate))
  hybrid$hybrid_conf_high <- suppressWarnings(as.numeric(hybrid$conf.high))

  idx <- match(boundary$key, hybrid$key)
  boundary_finite <- as_bool(boundary$profile_finite_interval)
  hybrid$hybrid_interval_channel[idx] <- ifelse(
    boundary_finite,
    "endpoint_profile",
    "endpoint_profile_failed"
  )
  hybrid$hybrid_usable_interval[idx] <- boundary_finite
  hybrid$hybrid_covered[idx] <- as_bool(boundary$profile_covered)
  hybrid$hybrid_lower_miss[idx] <- as_bool(boundary$profile_lower_miss)
  hybrid$hybrid_upper_miss[idx] <- as_bool(boundary$profile_upper_miss)
  hybrid$hybrid_estimate[idx] <- suppressWarnings(as.numeric(
    boundary$wald_estimate
  ))
  hybrid$hybrid_conf_high[idx] <- suppressWarnings(as.numeric(
    boundary$profile_upper
  ))

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

providers <- c("phylo", "relmat", "spatial")
hybrid <- rbind(
  base$hybrid[base$hybrid$provider %in% providers, ],
  topup$hybrid
)
boundary <- rbind(
  base$boundary[base$boundary$provider %in% providers, ],
  topup$boundary
)
eligible <- hybrid[hybrid$denominator_role == "pregrid_target", , drop = FALSE]

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

provider_label <- c(
  phylo = "phylo",
  relmat = "relmat K-matrix",
  spatial = "fixed-covariance spatial"
)

rows <- do.call(
  rbind,
  lapply(
    split(eligible, paste(eligible$provider, eligible$endpoint_member)),
    function(x) {
      provider <- x$provider[[1L]]
      endpoint <- x$endpoint_member[[1L]]
      usable <- x$hybrid_usable_interval
      covered <- x$hybrid_covered & usable
      lower_miss <- x$hybrid_lower_miss & usable
      upper_miss <- x$hybrid_upper_miss & usable
      boundary_rows <- boundary[
        boundary$provider == provider & boundary$endpoint_member == endpoint,
        ,
        drop = FALSE
      ]
      upper_estimate <- x$hybrid_estimate[upper_miss]
      upper_conf_high <- x$hybrid_conf_high[upper_miss]
      n_lower <- sum(lower_miss)
      n_upper <- sum(upper_miss)
      ratio <- if (n_lower == 0L) {
        "Inf"
      } else {
        fmt4(n_upper / n_lower)
      }
      verdict <- if (n_upper > n_lower) {
        "interval_shape_upper_tail_blocker"
      } else {
        "interval_shape_tail_blocker"
      }
      data.frame(
        diagnostic_id = paste0(
          "gaussian_mu_slope_interval_shape_",
          provider,
          "_",
          endpoint_slug(endpoint)
        ),
        cell_id = x$cell_id[[1L]],
        provider = provider,
        endpoint_member = endpoint,
        direct_sd_target = x$direct_sd_target[[1L]],
        source_replicates = source_replicates,
        source_boundary_profiles = source_boundary_profiles,
        n_replicates = nrow(x),
        n_usable_hybrid_intervals = sum(usable),
        finite_interval_rate = fmt4(mean(usable)),
        n_covered = sum(covered),
        hybrid_coverage_all = fmt4(mean(covered)),
        hybrid_coverage_mcse = fmt6(mcse_proportion(covered)),
        n_lower_miss = n_lower,
        n_upper_miss = n_upper,
        upper_lower_miss_ratio = ratio,
        n_wald_lower_miss = sum(
          as_bool(x$lower_miss) & as_bool(x$usable_interval)
        ),
        n_wald_upper_miss = sum(
          as_bool(x$upper_miss) & as_bool(x$usable_interval)
        ),
        n_profile_boundary_rows = nrow(boundary_rows),
        n_profile_finite = sum(as_bool(boundary_rows$profile_finite_interval)),
        n_profile_failed = sum(
          boundary_rows$profile_conf_status == "profile_failed"
        ),
        n_profile_upper_miss = sum(as_bool(boundary_rows$profile_upper_miss)),
        median_estimate_all = fmtg(stats::median(
          x$hybrid_estimate,
          na.rm = TRUE
        )),
        median_estimate_upper_miss = fmtg(stats::median(
          upper_estimate,
          na.rm = TRUE
        )),
        median_conf_high_upper_miss = fmtg(stats::median(
          upper_conf_high,
          na.rm = TRUE
        )),
        upper_miss_estimate_range = paste(
          fmtg(min(upper_estimate, na.rm = TRUE)),
          fmtg(max(upper_estimate, na.rm = TRUE)),
          sep = ".."
        ),
        diagnostic_verdict = verdict,
        linked_interval_status = "planned",
        linked_coverage_status = "planned",
        promotion_decision = "do_not_promote",
        evidence_url = "docs/dev-log/after-task/2026-06-29-q-series-gaussian-mu-slope-interval-shape-diagnostic.md",
        claim_boundary = clean_text(paste0(
          "This promotes exactly no q-series row; ",
          provider_label[[provider]],
          " Gaussian q1 mu one-slope ",
          endpoint,
          " interval-shape diagnostic only; SR475 MCSE-qualified retained denominator ",
          "still shows upper-tail miss pressure, so interval_status and coverage_status stay planned; ",
          "no inference_ready, supported, sigma, q2, q4/q8, non-Gaussian, REML, AI-REML, ",
          "or public support claim."
        )),
        next_gate = "Fisher/Rose must approve a new interval-shape or calibration rule before any DRAC top-up, TSV promotion, or public wording change.",
        stringsAsFactors = FALSE
      )
    }
  )
)
rows <- rows[order(match(rows$provider, providers), rows$endpoint_member), ]
row.names(rows) <- NULL

upper_miss_rows <- eligible[
  eligible$hybrid_usable_interval & eligible$hybrid_upper_miss,
  c(
    "cell_id",
    "provider",
    "endpoint_member",
    "direct_sd_target",
    "replicate_index",
    "seed",
    "parameter",
    "truth",
    "hybrid_interval_channel",
    "hybrid_estimate",
    "hybrid_conf_high",
    "source_slice"
  ),
  drop = FALSE
]
upper_miss_rows <- upper_miss_rows[
  order(
    match(upper_miss_rows$provider, providers),
    upper_miss_rows$endpoint_member,
    upper_miss_rows$replicate_index
  ),
]
row.names(upper_miss_rows) <- NULL

write_tsv(rows, out_path)
write_tsv(rows, artifact_summary_path)
write_tsv(upper_miss_rows, artifact_miss_path)
cat(
  "wrote",
  rel_path(out_path),
  "with",
  nrow(rows),
  "rows and",
  nrow(upper_miss_rows),
  "upper-miss rows\n"
)
