#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
overwrite <- "--overwrite=true" %in% args

root <- normalizePath(".", winslash = "/", mustWork = TRUE)
dashboard_dir <- file.path(root, "docs/dev-log/dashboard")
pregrid_dir <- file.path(
  root,
  "docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-mu-intercept-pregrid-nibi"
)
topup_dir <- file.path(
  root,
  "docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-mu-intercept-topup-nibi"
)
out_path <- file.path(
  dashboard_dir,
  "structured-re-gaussian-lowq-mu-intercept-sr475-results.tsv"
)
replicate_out_path <- file.path(
  topup_dir,
  "structured-re-gaussian-lowq-mu-intercept-sr475-results-replicates.tsv"
)

if ((file.exists(out_path) || file.exists(replicate_out_path)) && !overwrite) {
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

clean_text <- function(x) gsub("[[:space:]]+", " ", trimws(x))
fmt4 <- function(x) sprintf("%.4f", x)
fmt6 <- function(x) sprintf("%.6f", x)

as_bool <- function(x) {
  if (is.logical(x)) {
    return(x)
  }
  as.character(x) == "TRUE"
}

mcse_proportion <- function(x) {
  x <- as.logical(x)
  sqrt(mean(x) * (1 - mean(x)) / length(x))
}

safe_ratio <- function(num, den) {
  if (den == 0L) {
    return("Inf")
  }
  fmt4(num / den)
}

pregrid_replicates <- read_tsv(file.path(
  pregrid_dir,
  "structured-re-gaussian-lowq-mu-intercept-pregrid-results-replicates.tsv"
))
pregrid_summary <- read_tsv(file.path(
  dashboard_dir,
  "structured-re-gaussian-lowq-mu-intercept-pregrid-results.tsv"
))
topup_dispatch <- read_tsv(file.path(
  dashboard_dir,
  "structured-re-gaussian-lowq-mu-intercept-topup-dispatch.tsv"
))

topup_rep_paths <- list.files(
  file.path(topup_dir, "results"),
  pattern = "^structured-re-gaussian-lowq-mu-intercept-topup-results-replicates[.]tsv$",
  recursive = TRUE,
  full.names = TRUE
)
topup_summary_paths <- list.files(
  file.path(topup_dir, "results"),
  pattern = "^structured-re-gaussian-lowq-mu-intercept-topup-results[.]tsv$",
  recursive = TRUE,
  full.names = TRUE
)

if (length(topup_rep_paths) != 4L || length(topup_summary_paths) != 4L) {
  stop("Expected four imported top-up replicate and summary shards.", call. = FALSE)
}

pregrid_replicates$source_slice <- "sr1_150_pregrid"
pregrid_replicates$source_rep_id <- pregrid_replicates$pregrid_id
pregrid_replicates$slurm_job_id <- pregrid_summary$slurm_job_id[
  match(pregrid_replicates$provider, pregrid_summary$provider)
]

topup_replicates <- do.call(
  rbind,
  lapply(topup_rep_paths, read_tsv)
)
topup_summaries <- do.call(
  rbind,
  lapply(topup_summary_paths, read_tsv)
)
topup_replicates$source_slice <- "sr151_475_topup"
topup_replicates$source_rep_id <- topup_replicates$topup_id
topup_replicates$slurm_job_id <- topup_dispatch$slurm_job_id[
  match(topup_replicates$provider, topup_dispatch$provider)
]

shared_cols <- intersect(names(pregrid_replicates), names(topup_replicates))
replicates <- rbind(
  pregrid_replicates[, shared_cols, drop = FALSE],
  topup_replicates[, shared_cols, drop = FALSE]
)

providers <- c("phylo", "spatial", "animal", "relmat")
if (!identical(sort(unique(replicates$provider)), sort(providers))) {
  stop("Unexpected provider set in SR475 q1 mu-intercept replicates.", call. = FALSE)
}

provider_label <- c(
  phylo = "phylo",
  spatial = "fixed-covariance spatial",
  animal = "animal A-matrix",
  relmat = "relmat K-matrix"
)
provider_boundary <- c(
  phylo = "",
  spatial = "no range-estimating spatial support, ",
  animal = "no pedigree/Ainv bridge marshalling, ",
  relmat = "no Q bridge marshalling, "
)

rows <- lapply(providers, function(provider) {
  x <- replicates[replicates$provider == provider, , drop = FALSE]
  if (nrow(x) != 475L) {
    stop(provider, " does not have 475 retained SR475 replicates.", call. = FALSE)
  }
  ordered_reps <- sort(unique(as.integer(x$replicate_index)))
  if (!identical(ordered_reps, 1:475)) {
    stop(provider, " replicate_index is not exactly 1:475.", call. = FALSE)
  }
  usable <- as_bool(x$usable_interval)
  covered <- as_bool(x$covered) & usable
  fit_ok <- as_bool(x$fit_ok)
  converged <- as_bool(x$converged)
  pdhess <- as_bool(x$pdHess)
  confint_ok <- as_bool(x$confint_ok)
  lower_miss <- as_bool(x$lower_miss) & usable
  upper_miss <- as_bool(x$upper_miss) & usable
  warning_count <- suppressWarnings(as.integer(x$warning_count))
  warning_count[is.na(warning_count)] <- 0L
  n_lower <- sum(lower_miss)
  n_upper <- sum(upper_miss)
  coverage_mcse <- mcse_proportion(covered)
  one_sided_ratio <- if (n_lower == 0L && n_upper == 0L) {
    "balanced_no_misses"
  } else {
    paste0("upper_lower_ratio=", safe_ratio(n_upper, n_lower))
  }
  review_signal <- if (
    coverage_mcse <= 0.01 &&
      mean(fit_ok) == 1 &&
      mean(converged) == 1 &&
      mean(pdhess) == 1 &&
      mean(usable) == 1
  ) {
    "sr475_mcse_met_review_pending"
  } else {
    "sr475_review_required_possible_topup_or_blocker"
  }
  data.frame(
    sr475_id = paste0("gaussian_lowq_mu_intercept_sr475_", provider),
    cell_id = x$cell_id[[1L]],
    provider = provider,
    source_pregrid = "docs/dev-log/dashboard/structured-re-gaussian-lowq-mu-intercept-pregrid-results.tsv",
    source_topup_dispatch = "docs/dev-log/dashboard/structured-re-gaussian-lowq-mu-intercept-topup-dispatch.tsv",
    artifact_dir = "docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-mu-intercept-topup-nibi",
    replicate_artifact = "docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-mu-intercept-topup-nibi/structured-re-gaussian-lowq-mu-intercept-sr475-results-replicates.tsv",
    n_rep = nrow(x),
    n_pregrid = sum(x$source_slice == "sr1_150_pregrid"),
    n_topup = sum(x$source_slice == "sr151_475_topup"),
    seed_min = min(as.integer(x$seed)),
    seed_max = max(as.integer(x$seed)),
    n_fit_ok = sum(fit_ok),
    fit_ok_rate = fmt4(mean(fit_ok)),
    n_converged = sum(converged),
    convergence_rate = fmt4(mean(converged)),
    n_pdhess = sum(pdhess),
    pdhess_rate = fmt4(mean(pdhess)),
    n_confint_ok = sum(confint_ok),
    confint_ok_rate = fmt4(mean(confint_ok)),
    n_usable_intervals = sum(usable),
    finite_interval_rate = fmt4(mean(usable)),
    n_covered = sum(covered),
    coverage = fmt4(mean(covered)),
    coverage_mcse = fmt6(coverage_mcse),
    lower_miss = n_lower,
    upper_miss = n_upper,
    lower_miss_rate = fmt4(mean(lower_miss)),
    upper_miss_rate = fmt4(mean(upper_miss)),
    upper_lower_miss_ratio = safe_ratio(n_upper, n_lower),
    one_sided_miss_signal = one_sided_ratio,
    n_warning_replicates = sum(warning_count > 0L),
    n_retained_denominator = nrow(x),
    slurm_job_ids = paste(sort(unique(x$slurm_job_id)), collapse = ","),
    review_signal = review_signal,
    review_decision = "fisher_rose_grace_sr475_review_required_no_promotion",
    promotion_decision = "do_not_promote",
    linked_fit_status = "point_fit",
    linked_interval_status = "planned",
    linked_coverage_status = "planned",
    evidence_url = "docs/dev-log/after-task/2026-06-30-q-series-q1-mu-sr475-aggregate.md",
    claim_boundary = clean_text(paste0(
      "This promotes exactly no Q-Series row: ",
      provider_label[[provider]],
      " Gaussian q1 mu-intercept SR475 retained-denominator aggregate only; ",
      provider_boundary[[provider]],
      "no interval_status, coverage_status, inference_ready, supported, q1 sigma, ",
      "matched mu+sigma, q2, q4/q8, non-Gaussian interval, REML, AI-REML, ",
      "bridge support, or public support claim."
    )),
    next_gate = paste(
      "Fisher/Rose/Grace must review retained denominator, convergence, pdHess,",
      "finite intervals, warning ledger, lower/upper misses, coverage MCSE,",
      "failure taxonomy, and blocked neighbours before any support-cell status edit;",
      "linked support cells remain point_fit/planned/planned."
    ),
    stringsAsFactors = FALSE
  )
})

out <- do.call(rbind, rows)
row.names(out) <- NULL

write_tsv(replicates, replicate_out_path)
write_tsv(out, out_path)

cat("wrote", out_path, "with", nrow(out), "rows\n")
cat("wrote", replicate_out_path, "with", nrow(replicates), "rows\n")
