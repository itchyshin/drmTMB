#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
overwrite <- "--overwrite=true" %in% args

root <- normalizePath(".", winslash = "/", mustWork = TRUE)
dashboard_dir <- file.path(root, "docs/dev-log/dashboard")
artifact_dir <- file.path(
  root,
  "docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-sigma-intercept-pregrid-nibi"
)
summary_in <- file.path(
  artifact_dir,
  "structured-re-gaussian-lowq-sigma-intercept-local-smoke.tsv"
)
replicate_in <- file.path(
  artifact_dir,
  "structured-re-gaussian-lowq-sigma-intercept-local-smoke-replicates.tsv"
)
seed_in <- file.path(
  artifact_dir,
  "structured-re-gaussian-lowq-sigma-intercept-local-smoke-seed-manifest.tsv"
)
summary_copy <- file.path(
  artifact_dir,
  "structured-re-gaussian-lowq-sigma-intercept-pregrid-results.tsv"
)
replicate_copy <- file.path(
  artifact_dir,
  "structured-re-gaussian-lowq-sigma-intercept-pregrid-results-replicates.tsv"
)
seed_copy <- file.path(
  artifact_dir,
  "structured-re-gaussian-lowq-sigma-intercept-pregrid-results-seed-manifest.tsv"
)
dispatch_path <- file.path(
  dashboard_dir,
  "structured-re-gaussian-lowq-sigma-intercept-pregrid-dispatch.tsv"
)
out_path <- file.path(
  dashboard_dir,
  "structured-re-gaussian-lowq-sigma-intercept-pregrid-results.tsv"
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
safe_ratio <- function(num, den) {
  if (den == 0L) {
    return(if (num == 0L) "balanced_no_lower_miss" else "Inf")
  }
  fmt4(num / den)
}

for (path in c(summary_in, replicate_in, seed_in, dispatch_path)) {
  if (!file.exists(path)) {
    stop("Missing required input: ", path, call. = FALSE)
  }
}

if (!file.copy(summary_in, summary_copy, overwrite = TRUE) ||
    !file.copy(replicate_in, replicate_copy, overwrite = TRUE) ||
    !file.copy(seed_in, seed_copy, overwrite = TRUE)) {
  stop("Could not write standardized artifact copies.", call. = FALSE)
}

summary <- read_tsv(summary_in)
dispatch <- read_tsv(dispatch_path)
providers <- c("animal", "relmat")

if (!identical(summary$provider, providers)) {
  stop("Expected animal and relmat summary rows in provider order.", call. = FALSE)
}
if (!identical(dispatch$provider, providers)) {
  stop("Expected animal and relmat dispatch rows in provider order.", call. = FALSE)
}

dispatch$submit_status <- "completed_imported_reviewed_blocked_no_topup"
dispatch$claim_boundary <- paste(
  "This promotes exactly no Q-Series row;",
  "Nibi retry job 16982458 completed 0:0 and artifacts were imported and",
  "reviewed for q1 sigma animal/relmat SR150 retained-denominator evidence",
  "after failed job 16982141; this is diagnostic-blocked evidence with",
  "finite raw Wald interval rate",
  "0.7667 and warning replicates 118/150, not reviewed coverage evidence;",
  "no interval_status, coverage_status, inference_ready, supported,",
  "location-axis bias+t correction, q1 mu, matched mu+sigma, q2, q4/q8,",
  "non-Gaussian interval, REML, AI-REML, bridge support, or public support claim."
)
dispatch$next_gate <- paste(
  "Previous Nibi job 16982141 failed before simulation because the runner",
  "required devtools; retry job 16982458 completed 0:0 from the",
  "installed-package fallback; imported artifacts are in",
  "docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-sigma-intercept-pregrid-nibi;",
  "Fisher/Gauss/Rose reviewed the finite denominator, 115/150 usable intervals,",
  "warnings 118/150, lower/upper misses, MCSE 0.012190, profile failures,",
  "boundary rows, and failure taxonomy; the sigma interval route must be",
  "hardened or replaced before any SR475/SR1000 top-up or status edit."
)
write_tsv(dispatch, dispatch_path)

artifact_rel <- "docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-sigma-intercept-pregrid-nibi"
rows <- lapply(seq_len(nrow(summary)), function(i) {
  row <- summary[i, , drop = FALSE]
  dispatch_row <- dispatch[dispatch$provider == row$provider, , drop = FALSE]
  n_rep <- as.integer(row$n_rep)
  n_usable <- as.integer(row$n_usable_wald_intervals)
  n_lower <- as.integer(row$lower_miss)
  n_upper <- as.integer(row$upper_miss)
  finite_rate <- as.numeric(row$finite_wald_interval_rate)
  warning_reps <- as.integer(row$n_warning_replicates)
  data.frame(
    pregrid_id = paste0("gaussian_lowq_sigma_intercept_pregrid_", row$provider),
    cell_id = row$cell_id,
    provider = row$provider,
    source_row_selection = "docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv",
    artifact_dir = artifact_rel,
    n_rep = n_rep,
    n_fit_ok = as.integer(row$n_fit_ok),
    n_converged = as.integer(row$n_converged),
    n_pdhess = as.integer(row$n_pdhess),
    n_confint_ok = as.integer(row$n_confint_ok),
    n_usable_intervals = n_usable,
    finite_interval_rate = fmt4(finite_rate),
    n_covered = as.integer(row$n_covered),
    coverage = fmt4(as.numeric(row$coverage)),
    coverage_mcse = fmt6(as.numeric(row$coverage_mcse)),
    lower_miss = n_lower,
    upper_miss = n_upper,
    lower_miss_rate = fmt4(n_lower / n_rep),
    upper_miss_rate = fmt4(n_upper / n_rep),
    upper_lower_miss_ratio = safe_ratio(n_upper, n_lower),
    pregrid_status = "sr150_pregrid_completed_diagnostic_blocked_no_topup",
    review_decision = "fisher_gauss_rose_route_hardening_required_no_topup",
    promotion_decision = "do_not_promote",
    evidence_url = artifact_rel,
    claim_boundary = paste(
      "This promotes exactly no Q-Series row;",
      "Nibi SR150 q1 sigma animal/relmat artifacts are imported for",
      "Fisher/Gauss/Rose review only; raw Wald uses small_sample_df=none and",
      "bias_correct=none; finite raw Wald interval rate is 0.7667 and warning",
      "replicates are 118/150, so this is diagnostic-blocked rather than a",
      "coverage pass; no interval_status, coverage_status, inference_ready,",
      "supported, location-axis bias+t correction, q1 mu, matched mu+sigma,",
      "q2, q4/q8, non-Gaussian interval, REML, AI-REML, bridge support, or",
      "public support claim."
    ),
    next_gate = paste(
      "Fisher/Gauss/Rose reviewed the retained denominator, finite intervals",
      "115/150, warnings 118/150, lower/upper misses, MCSE 0.012190, profile",
      "failures, boundary rows, failure taxonomy, and blocked neighbours;",
      "harden or replace the sigma interval route before any SR475/SR1000 top-up",
      "or any status-table edit; linked support cells remain point_fit/planned/planned."
    ),
    source_contract_id = dispatch_row$source_contract_id,
    source_contract = "docs/dev-log/dashboard/structured-re-gaussian-lowq-sigma-intercept-denominator-contract.tsv",
    host_class = row$host_class,
    host_name = row$host_name,
    n_warning_replicates = warning_reps,
    n_retained_denominator = n_rep,
    slurm_job_id = dispatch_row$slurm_job_id,
    run_root = dispatch_row$run_root,
    source_dispatch_id = dispatch_row$dispatch_id,
    artifact_status = "completed_imported_reviewed_blocked_no_topup",
    stringsAsFactors = FALSE
  )
})

result_rows <- do.call(rbind, rows)
write_tsv(result_rows, out_path)

support_path <- file.path(dashboard_dir, "structured-re-q-series-support-cells.tsv")
lowq_path <- file.path(dashboard_dir, "structured-re-gaussian-lowq-status-audit.tsv")
closure_path <- file.path(dashboard_dir, "structured-re-q-series-closure-triage.tsv")
queue_path <- file.path(dashboard_dir, "structured-re-q-series-next-campaign-queue.tsv")
support <- read_tsv(support_path)
lowq <- read_tsv(lowq_path)
closure <- read_tsv(closure_path)
queue <- read_tsv(queue_path)
support_idx <- match(result_rows$cell_id, support$cell_id)
lowq_idx <- match(result_rows$cell_id, lowq$cell_id)
if (anyNA(support_idx)) {
  stop(
    "Support-cell TSV is missing q1 sigma pregrid result cells: ",
    paste(result_rows$cell_id[is.na(support_idx)], collapse = ", "),
    call. = FALSE
  )
}
if (anyNA(lowq_idx)) {
  stop(
    "Gaussian low-q audit TSV is missing q1 sigma pregrid result cells: ",
    paste(result_rows$cell_id[is.na(lowq_idx)], collapse = ", "),
    call. = FALSE
  )
}

support$claim_boundary[support_idx] <- paste0(
  "Gaussian low-q q1 sigma-intercept Nibi SR150 pregrid evidence is ",
  "reviewed diagnostic-blocked evidence only; ",
  result_rows$provider,
  " has 150/150 fit, convergence, pdHess, and confint success, but only ",
  "115/150 usable raw-Wald intervals and 118/150 warning replicates with ",
  "raw log-SD Wald, small_sample_df=none, bias_correct=none; it promotes ",
  "exactly no Q-Series row and does not claim interval_status, ",
  "coverage_status, inference_ready, supported, q1 mu, matched mu+sigma, ",
  "q2, q4/q8, non-Gaussian, REML, AI-REML, bridge support, denominator pass, ",
  "or public support."
)
support$next_gate[support_idx] <- paste(
  "Fisher/Gauss/Rose reviewed the SR150 retained denominator, finite interval",
  "censoring 115/150, warning ledger 118/150, lower/upper misses, MCSE",
  "0.012190, profile failures, boundary rows, and failure taxonomy; harden",
  "or replace the sigma interval route before SR475/SR1000 top-up,",
  "Nibi/Rorqual/DRAC denominator escalation, TSV promotion, inference_ready,",
  "supported, or public-support claim; keep support cells point_fit/planned/planned."
)
support$fit_status[support_idx] <- "point_fit"
support$interval_status[support_idx] <- "planned"
support$coverage_status[support_idx] <- "planned"
write_tsv(support, support_path)

lowq$inference_signal[lowq_idx] <- paste(
  "SR150 pregrid is reviewed diagnostic-blocked by finite raw-Wald interval",
  "rate 0.7667 and warning ledger 118/150; interval and coverage remain",
  "planned; sigma interval route must be hardened before top-up or promotion"
)
lowq$next_gate[lowq_idx] <- paste(
  "Fisher/Gauss/Rose reviewed the SR150 retained denominator, finite interval",
  "censoring 115/150, warning ledger 118/150, lower/upper misses, MCSE",
  "0.012190, profile failures, boundary rows, one-sided misses, profile policy,",
  "and failure taxonomy; harden or replace the sigma interval route before",
  "any SR475/SR1000 top-up, Nibi/Rorqual/DRAC escalation, TSV promotion,",
  "inference_ready, supported, or public support claim; keep support cells",
  "point_fit/planned/planned."
)
lowq$linked_fit_status[lowq_idx] <- "point_fit"
lowq$linked_interval_status[lowq_idx] <- "planned"
lowq$linked_coverage_status[lowq_idx] <- "planned"
lowq$promotion_decision[lowq_idx] <- "do_not_promote"
write_tsv(lowq, lowq_path)

queue_idx <- match("qseries_queue_gaussian_lowq_interval_design", queue$queue_id)
if (is.na(queue_idx)) {
  stop(
    "Next-campaign queue TSV is missing qseries_queue_gaussian_lowq_interval_design.",
    call. = FALSE
  )
}
queue$readiness_state[queue_idx] <- paste(
  "Nibi SR475 q1 mu-intercept retained-denominator aggregate promoted",
  "phylo/spatial/relmat to inference_ready with caveats after Rose/Fisher/Grace",
  "review; animal remains blocked by 473/475 usable intervals and retained",
  "wald_at_boundary infinite intervals at seeds 812407 and 812444.",
  "Animal/relmat q1 sigma SR150 pregrid is reviewed diagnostic-blocked by",
  "115/150 usable raw-Wald intervals and 118/150 warning replicates; the",
  "sigma interval route must be hardened or replaced before top-up.",
  "Q2 retained-denominator repair smoke has been reviewed as existing-route-only",
  "diagnostic evidence: four q2 intercept rows need a named interval-repair",
  "route before top-up, and the q2-plus row remains profile-finiteness blocked."
)
queue$next_action[queue_idx] <- paste(
  "For q2 retained-denominator rows, do not top up; design a named",
  "interval-repair route, then repeat the small smoke and review before",
  "cluster escalation. For q1 sigma animal/relmat, the blocker decision is",
  "recorded; design a hardened or replacement sigma interval route, then",
  "repeat a small smoke before any SR475/SR1000 top-up. Keep remaining support",
  "cells point_fit/planned/planned until audit-authorized status edits."
)
write_tsv(queue, queue_path)

closure_idx <- match("qseries_closure_gaussian_lowq_gate_required", closure$triage_id)
if (is.na(closure_idx)) {
  stop(
    "Closure triage TSV is missing qseries_closure_gaussian_lowq_gate_required.",
    call. = FALSE
  )
}
closure$status_meaning[closure_idx] <- paste(
  "Gaussian low-q gate rows include q2 retained-denominator cells whose Totoro",
  "repair-smoke review blocks top-up because only the existing interval route",
  "was rerun, plus q1 sigma animal/relmat cells whose SR150 review blocks",
  "top-up because the raw-Wald route has 115/150 usable intervals and 118/150",
  "warning replicates; support cells remain point_fit/planned/planned and no",
  "row is inference_ready or supported from these reviews."
)
closure$next_action[closure_idx] <- paste(
  "Do not submit q2 retained-denominator or q1 sigma animal/relmat Totoro,",
  "Nibi, Rorqual, Trillium, or other DRAC top-up jobs until the relevant named",
  "interval-repair route exists and passes a small retained-denominator smoke;",
  "continue other low-q repairs under their own row-specific contracts."
)
write_tsv(closure, closure_path)

message("Wrote Gaussian low-q sigma SR150 pregrid dashboard rows to ", out_path)
