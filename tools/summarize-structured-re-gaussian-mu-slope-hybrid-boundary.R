#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
overwrite <- "--overwrite=true" %in% args

root <- normalizePath(".", winslash = "/", mustWork = TRUE)
pregrid_dir <- file.path(
  root,
  "docs/dev-log/simulation-artifacts/2026-06-29-gaussian-mu-slope-coverage-pregrid-local"
)
boundary_dir <- file.path(
  root,
  "docs/dev-log/simulation-artifacts/2026-06-29-gaussian-mu-slope-boundary-profile-diagnostic-local"
)
out_path <- file.path(
  root,
  "docs/dev-log/dashboard/structured-re-gaussian-mu-slope-hybrid-boundary-audit.tsv"
)

if (file.exists(out_path) && !overwrite) {
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

fmt4 <- function(x) sprintf("%.4f", x)
fmt6 <- function(x) sprintf("%.6f", x)
mcse_proportion <- function(x) {
  x <- as.logical(x)
  sqrt(mean(x) * (1 - mean(x)) / length(x))
}
clean_text <- function(x) gsub("[[:space:]]+", " ", trimws(x))

pregrid <- read_tsv(file.path(
  pregrid_dir,
  "structured-re-gaussian-mu-slope-coverage-pregrid-replicates.tsv"
))
boundary <- read_tsv(file.path(
  boundary_dir,
  "structured-re-gaussian-mu-slope-boundary-profile-diagnostic-detail.tsv"
))

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
    "Boundary profile detail rows no longer match the pregrid replicate artifact."
  )
}

hybrid <- pregrid
hybrid$hybrid_interval_status <- hybrid$interval_status
hybrid$hybrid_usable_interval <- hybrid$usable_interval == "TRUE"
hybrid$hybrid_covered <- hybrid$covered == "TRUE"
hybrid$hybrid_lower_miss <- hybrid$lower_miss == "TRUE"
hybrid$hybrid_upper_miss <- hybrid$upper_miss == "TRUE"

idx <- match(boundary$key, hybrid$key)
boundary_finite <- boundary$profile_finite_interval == "TRUE"
hybrid$hybrid_interval_status[idx] <- ifelse(
  boundary_finite,
  "profile_boundary_finite",
  "profile_boundary_failed"
)
hybrid$hybrid_usable_interval[idx] <- boundary_finite
hybrid$hybrid_covered[idx] <- boundary$profile_covered == "TRUE"
hybrid$hybrid_lower_miss[idx] <- boundary$profile_lower_miss == "TRUE"
hybrid$hybrid_upper_miss[idx] <- boundary$profile_upper_miss == "TRUE"

provider_label <- c(
  animal = "animal A-matrix",
  phylo = "phylo",
  relmat = "relmat K-matrix",
  spatial = "fixed-covariance spatial"
)
provider_boundary <- c(
  animal = "no pedigree/Ainv bridge marshalling, ",
  phylo = "",
  relmat = "no Q bridge marshalling, ",
  spatial = "no range-estimating spatial support, "
)

eligible <- hybrid[hybrid$denominator_role == "pregrid_target", , drop = FALSE]
rows <- lapply(split(eligible, eligible$provider), function(x) {
  provider <- x$provider[[1L]]
  cell_id <- x$cell_id[[1L]]
  usable <- x$hybrid_usable_interval
  covered <- x$hybrid_covered & usable
  coverage_all <- sum(covered) / nrow(x)
  coverage_usable <- if (sum(usable) > 0L) {
    sum(covered) / sum(usable)
  } else {
    NA_real_
  }
  boundary_rows <- boundary[boundary$provider == provider, , drop = FALSE]
  n_profile_failed <- sum(boundary_rows$profile_conf_status == "profile_failed")
  n_profile_finite <- sum(boundary_rows$profile_finite_interval == "TRUE")
  n_upper <- sum(x$hybrid_upper_miss & usable)
  n_lower <- sum(x$hybrid_lower_miss & usable)
  hard_blocked <- coverage_all < 0.90
  widget_state <- if (hard_blocked) {
    "mu_slope_pregrid_blocked"
  } else {
    "topup_required"
  }
  admission_status <- if (hard_blocked) {
    "hybrid_boundary_hard_blocked"
  } else {
    "hybrid_boundary_topup_candidate"
  }
  inference_signal <- if (hard_blocked) {
    "not_inference_ready_hybrid_coverage_hard_negative"
  } else {
    "not_inference_ready_hybrid_sr150_mcse_above_0.01"
  }
  evidence_basis <- sprintf(
    "Hybrid Wald+endpoint-profile SR150 denominator: %s/%s covered, %s/%s usable intervals, coverage_all %s, coverage_usable %s, MCSE %s, misses lower=%s upper=%s, boundary profiles finite=%s failed=%s.",
    sum(covered),
    nrow(x),
    sum(usable),
    nrow(x),
    fmt4(coverage_all),
    fmt4(coverage_usable),
    fmt6(mcse_proportion(covered)),
    n_lower,
    n_upper,
    n_profile_finite,
    n_profile_failed
  )
  next_gate <- if (hard_blocked) {
    "Do not top up this row until the hybrid boundary-profile interval channel no longer shows a target-level hard negative."
  } else {
    "Top up the hybrid Wald+endpoint-profile retained denominator to MCSE <= 0.01 and audit one-sided misses before any inference_ready wording."
  }
  data.frame(
    audit_id = paste0("gaussian_mu_slope_hybrid_boundary_", provider),
    cell_id = cell_id,
    provider = provider,
    source_pregrid = "docs/dev-log/simulation-artifacts/2026-06-29-gaussian-mu-slope-coverage-pregrid-local/structured-re-gaussian-mu-slope-coverage-pregrid-replicates.tsv",
    source_boundary_profile = "docs/dev-log/simulation-artifacts/2026-06-29-gaussian-mu-slope-boundary-profile-diagnostic-local/structured-re-gaussian-mu-slope-boundary-profile-diagnostic-detail.tsv",
    n_eligible_target_replicates = nrow(x),
    n_usable_hybrid_intervals = sum(usable),
    finite_interval_rate = fmt4(mean(usable)),
    n_profile_boundary_rows = nrow(boundary_rows),
    n_profile_finite = n_profile_finite,
    n_profile_failed = n_profile_failed,
    n_profile_covered = sum(boundary_rows$profile_covered == "TRUE"),
    n_covered = sum(covered),
    hybrid_coverage_all = fmt4(coverage_all),
    hybrid_coverage_usable = fmt4(coverage_usable),
    hybrid_coverage_mcse = fmt6(mcse_proportion(covered)),
    n_lower_miss = n_lower,
    n_upper_miss = n_upper,
    miss_balance = sprintf("lower=%s upper=%s", n_lower, n_upper),
    widget_state = widget_state,
    admission_status = admission_status,
    evidence_basis = evidence_basis,
    stability_signal = "hybrid_wald_plus_endpoint_profile_boundary_accounting",
    inference_signal = inference_signal,
    linked_fit_status = "point_fit",
    linked_interval_status = "planned",
    linked_coverage_status = "planned",
    promotion_decision = "do_not_promote",
    evidence_url = "docs/dev-log/after-task/2026-06-29-q-series-gaussian-mu-slope-hybrid-boundary-audit.md",
    artifact_dir = "docs/dev-log/simulation-artifacts/2026-06-29-gaussian-mu-slope-boundary-profile-diagnostic-local",
    claim_boundary = clean_text(paste0(
      provider_label[[provider]],
      " Gaussian q1 mu one-slope hybrid boundary audit only; ",
      provider_boundary[[provider]],
      "SR150 evidence only, no MCSE-qualified coverage, inference_ready, supported, ",
      "q2/q4/q8, sigma, non-Gaussian, REML, AI-REML, broad bridge support, or public support promoted."
    )),
    next_gate = next_gate,
    stringsAsFactors = FALSE
  )
})

out <- do.call(rbind, rows)
out <- out[match(c("animal", "phylo", "relmat", "spatial"), out$provider), ]
row.names(out) <- NULL
write_tsv(out, out_path)
cat("wrote", out_path, "with", nrow(out), "rows\n")
