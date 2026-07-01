#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)

parse_args <- function(args) {
  out <- list(
    artifact_dir = "docs/dev-log/simulation-artifacts/2026-06-29-spatial-sigma-boundary-nibi",
    output = "docs/dev-log/dashboard/structured-re-spatial-sigma-boundary-diagnostic.tsv",
    cluster_host = "nibi",
    cluster_job = NA_character_,
    package_git_sha = NA_character_
  )
  for (arg in args) {
    if (startsWith(arg, "--artifact_dir=")) {
      out$artifact_dir <- sub("^--artifact_dir=", "", arg)
    } else if (startsWith(arg, "--output=")) {
      out$output <- sub("^--output=", "", arg)
    } else if (startsWith(arg, "--cluster_host=")) {
      out$cluster_host <- sub("^--cluster_host=", "", arg)
    } else if (startsWith(arg, "--cluster_job=")) {
      out$cluster_job <- sub("^--cluster_job=", "", arg)
    } else if (startsWith(arg, "--package_git_sha=")) {
      out$package_git_sha <- sub("^--package_git_sha=", "", arg)
    } else {
      stop("Unknown argument: ", arg, call. = FALSE)
    }
  }
  out
}

opts <- parse_args(args)

read_tsv <- function(path) {
  utils::read.delim(
    path,
    sep = "\t",
    stringsAsFactors = FALSE,
    check.names = FALSE
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

truthy <- function(x) as.character(x) %in% c("TRUE", "true", "1")

is_finite_numeric <- function(x) {
  y <- suppressWarnings(as.numeric(x))
  is.finite(y)
}

num <- function(x) suppressWarnings(as.numeric(x))

fmt_num <- function(x, digits = 6L) {
  if (!is.finite(x)) {
    return("NA")
  }
  format(signif(x, digits), scientific = FALSE, trim = TRUE)
}

fmt_rate <- function(x) {
  if (!is.finite(x)) {
    return("NA")
  }
  sprintf("%.4f", x)
}

mcse_prop <- function(x) {
  x <- as.logical(x)
  if (!length(x)) {
    return(NA_real_)
  }
  p <- mean(x)
  sqrt(p * (1 - p) / length(x))
}

clean_text <- function(x) {
  x <- paste(x, collapse = "; ")
  x <- gsub("[\r\n\t]+", " ", x)
  x <- gsub("[^ -~]", "", x)
  x <- gsub(" +", " ", x)
  trimws(x)
}

count_signature <- function(x) {
  if (!length(x)) {
    return("none")
  }
  labels <- names(x)
  labels[!nzchar(labels)] <- "<empty>"
  clean_text(paste0(labels, "=", as.integer(x)))
}

replicate_path <- file.path(
  opts$artifact_dir,
  "03-spatial-sigma_intercept-replicates.tsv"
)
summary_path <- file.path(
  opts$artifact_dir,
  "03-spatial-sigma_intercept-summary.tsv"
)

if (!file.exists(replicate_path)) {
  stop("Missing replicate artifact: ", replicate_path, call. = FALSE)
}
if (!file.exists(summary_path)) {
  stop("Missing summary artifact: ", summary_path, call. = FALSE)
}

replicates <- read_tsv(replicate_path)
summary <- read_tsv(summary_path)

required_replicates <- c(
  "seed",
  "provider",
  "endpoint_member",
  "target_parm",
  "truth_sd",
  "attempt_status",
  "convergence",
  "pdHess",
  "estimate_sd",
  "wald_lower",
  "wald_upper",
  "wald_status",
  "wald_warnings",
  "wald_contains",
  "profile_lower",
  "profile_upper",
  "profile_status",
  "profile_message",
  "profile_contains"
)
missing_replicates <- setdiff(required_replicates, names(replicates))
if (length(missing_replicates)) {
  stop(
    "Replicate artifact is missing columns: ",
    paste(missing_replicates, collapse = ", "),
    call. = FALSE
  )
}

fit_ok <- replicates$attempt_status == "fit_ok"
wald_finite <- is_finite_numeric(replicates$wald_lower) &
  is_finite_numeric(replicates$wald_upper)
profile_finite <- is_finite_numeric(replicates$profile_lower) &
  is_finite_numeric(replicates$profile_upper)
estimate <- num(replicates$estimate_sd)
boundary_like <- !wald_finite & is.finite(estimate) & estimate < 1e-4
covered_wald <- truthy(replicates$wald_contains) & wald_finite
covered_profile <- truthy(replicates$profile_contains) & profile_finite
covered_wald_finite <- truthy(replicates$wald_contains[wald_finite])
covered_profile_finite <- truthy(replicates$profile_contains[profile_finite])
lower_miss_wald <- wald_finite &
  num(replicates$wald_lower) > num(replicates$truth_sd)
upper_miss_wald <- wald_finite &
  num(replicates$wald_upper) < num(replicates$truth_sd)
lower_miss_profile <- profile_finite &
  num(replicates$profile_lower) > num(replicates$truth_sd)
upper_miss_profile <- profile_finite &
  num(replicates$profile_upper) < num(replicates$truth_sd)

profile_messages <- sort(
  table(replicates$profile_message[!profile_finite]),
  decreasing = TRUE
)
warning_messages <- sort(
  table(replicates$wald_warnings[!wald_finite]),
  decreasing = TRUE
)

n_rep <- nrow(replicates)
n_wald_finite <- sum(wald_finite)
n_profile_finite <- sum(profile_finite)
finite_wald_rate <- n_wald_finite / n_rep
diagnostic_verdict <- if (finite_wald_rate >= 0.95) {
  "finite_wald_gate_passed_current_source"
} else if (sum(boundary_like) == sum(!wald_finite)) {
  "boundary_estimate_blocker_reproduced"
} else {
  "mixed_nonfinite_wald_blocker_reproduced"
}

out <- data.frame(
  diagnostic_id = "spatial_sigma_boundary_nibi_current_source",
  cell_id = "qseries_spatial_q1_sigma_one_slope",
  provider = "spatial",
  endpoint_member = "sigma:(Intercept)",
  target_parm = unique(replicates$target_parm)[[1L]],
  source_run = "nibi_current_source_spatial_sigma_intercept_475",
  cluster_host = opts$cluster_host,
  cluster_job = opts$cluster_job,
  package_git_sha = opts$package_git_sha,
  seed_start = min(as.integer(replicates$seed)),
  seed_end = max(as.integer(replicates$seed)),
  planned_reps = n_rep,
  n_fit_ok = sum(fit_ok),
  n_converged = sum(num(replicates$convergence) == 0, na.rm = TRUE),
  n_pdhess = sum(truthy(replicates$pdHess)),
  n_wald_finite = n_wald_finite,
  wald_finite_rate = fmt_rate(finite_wald_rate),
  n_wald_boundary_estimate = sum(boundary_like),
  max_nonfinite_estimate_sd = fmt_num(max(
    estimate[!wald_finite],
    na.rm = TRUE
  )),
  n_wald_covered = sum(covered_wald),
  wald_coverage = fmt_rate(mean(covered_wald_finite)),
  wald_mcse = fmt_num(mcse_prop(covered_wald_finite)),
  wald_retained_coverage = fmt_rate(mean(covered_wald)),
  wald_retained_mcse = fmt_num(mcse_prop(covered_wald)),
  wald_lower_miss = sum(lower_miss_wald),
  wald_upper_miss = sum(upper_miss_wald),
  n_profile_finite = n_profile_finite,
  profile_finite_rate = fmt_rate(n_profile_finite / n_rep),
  n_profile_covered = sum(covered_profile),
  profile_coverage = fmt_rate(mean(covered_profile_finite)),
  profile_mcse = fmt_num(mcse_prop(covered_profile_finite)),
  profile_retained_coverage = fmt_rate(mean(covered_profile)),
  profile_retained_mcse = fmt_num(mcse_prop(covered_profile)),
  profile_lower_miss = sum(lower_miss_profile),
  profile_upper_miss = sum(upper_miss_profile),
  profile_failure_signature = count_signature(profile_messages),
  wald_failure_signature = count_signature(warning_messages),
  diagnostic_verdict = diagnostic_verdict,
  promotion_decision = "do_not_promote",
  evidence_url = replicate_path,
  claim_boundary = paste(
    "Current-source spatial sigma:(Intercept) diagnostic only;",
    "does NOT promote interval_status, coverage_status, inference_ready,",
    "supported, range-estimating spatial, matched mu+sigma, q4/q8, REML,",
    "AI-REML, bridge, or public support."
  ),
  next_gate = if (
    identical(diagnostic_verdict, "finite_wald_gate_passed_current_source")
  ) {
    "Compare against the existing SR1000 blocker, then require Fisher/Rose sign-off before any exact-row status edit."
  } else {
    "Treat as a boundary-estimate blocker; design a sigma-specific interval channel or DGP/estimator adjustment before more top-up."
  },
  stringsAsFactors = FALSE
)

if (nrow(summary) == 1L) {
  expected <- c("n_fit_ok", "n_wald_finite", "n_profile_finite")
  if (all(expected %in% names(summary))) {
    stopifnot(as.integer(summary$n_fit_ok) == out$n_fit_ok)
    stopifnot(as.integer(summary$n_wald_finite) == out$n_wald_finite)
    stopifnot(as.integer(summary$n_profile_finite) == out$n_profile_finite)
  }
}

write_tsv(out, opts$output)
message("wrote ", opts$output)
