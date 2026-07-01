#!/usr/bin/env Rscript

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

args <- commandArgs(trailingOnly = TRUE)
if (any(args %in% c("--help", "-h"))) {
  cat(
    paste(
      "Usage: Rscript tools/summarize-structured-re-q2-retained-denominator-repair-smoke-review.R [options]",
      "",
      "Builds a Fisher/Rose/Grace review table from the q2 retained-denominator",
      "repair-smoke dispatch/import sidecar. This is blocker/no-promotion",
      "evidence only: it records whether the small smoke justifies more compute,",
      "records any diagnostic repair-sidecar signal separately, and it never",
      "edits support cells.",
      "",
      "Options:",
      "  --dispatch=PATH        repair-smoke dispatch/import TSV.",
      "  --decision=PATH        prior SR150 Fisher/Rose/Grace decision TSV.",
      "  --repair=PATH          repair-contract TSV.",
      "  --output=PATH          review TSV to write.",
      "  --sync-dashboard=true  update Q-Series next gates and queue text after",
      "                         the no-top-up review.",
      "  --overwrite=true       replace an existing output path.",
      "",
      sep = "\n"
    )
  )
  quit(status = 0)
}

arg_value <- function(name, default = NULL) {
  prefix <- paste0("--", name, "=")
  hit <- grep(paste0("^", prefix), args, value = TRUE)
  if (length(hit) == 0L) {
    return(default)
  }
  sub(prefix, "", hit[[length(hit)]], fixed = TRUE)
}

arg_flag <- function(name, default = FALSE) {
  value <- arg_value(name, NULL)
  if (is.null(value)) {
    return(default)
  }
  tolower(value) %in% c("1", "true", "yes", "y")
}

clean_text <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- "NA"
  x <- gsub("[\r\n\t]+", " ", x)
  x <- gsub("[^ -~]", "", x)
  x <- gsub(" +", " ", x)
  trimws(x)
}

read_tsv <- function(path) {
  utils::read.delim(
    path,
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
}

write_tsv <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  character_cols <- vapply(x, is.character, logical(1L))
  x[character_cols] <- lapply(x[character_cols], clean_text)
  utils::write.table(
    x,
    file = path,
    sep = "\t",
    row.names = FALSE,
    quote = FALSE,
    na = "NA"
  )
}

script_file <- sub(
  "^--file=",
  "",
  grep("^--file=", commandArgs(FALSE), value = TRUE)[1L] %||% "tools"
)
repo_root_candidates <- c(
  Sys.getenv("DRMTMB_REPO_ROOT", ""),
  file.path(dirname(script_file), ".."),
  getwd(),
  file.path(getwd(), ".."),
  file.path(getwd(), "..", "..")
)
repo_root_candidates <- repo_root_candidates[nzchar(repo_root_candidates)]
repo_root <- NA_character_
for (candidate in repo_root_candidates) {
  candidate <- normalizePath(candidate, winslash = "/", mustWork = FALSE)
  if (file.exists(file.path(candidate, "DESCRIPTION"))) {
    repo_root <- candidate
    break
  }
}
if (is.na(repo_root)) {
  stop("Cannot locate drmTMB repo root.", call. = FALSE)
}

rel_path <- function(path) {
  path <- normalizePath(path, winslash = "/", mustWork = FALSE)
  sub(paste0("^", gsub("([\\W])", "\\\\\\1", repo_root), "/?"), "", path)
}

dashboard_dir <- file.path(repo_root, "docs", "dev-log", "dashboard")
dispatch_path <- normalizePath(
  arg_value(
    "dispatch",
    file.path(
      dashboard_dir,
      "structured-re-q2-retained-denominator-repair-smoke-dispatch.tsv"
    )
  ),
  winslash = "/",
  mustWork = FALSE
)
decision_path <- normalizePath(
  arg_value(
    "decision",
    file.path(
      dashboard_dir,
      "structured-re-q2-retained-denominator-review-decision.tsv"
    )
  ),
  winslash = "/",
  mustWork = FALSE
)
repair_path <- normalizePath(
  arg_value(
    "repair",
    file.path(
      dashboard_dir,
      "structured-re-q2-retained-denominator-repair-contract.tsv"
    )
  ),
  winslash = "/",
  mustWork = FALSE
)
output_path <- normalizePath(
  arg_value(
    "output",
    file.path(
      dashboard_dir,
      "structured-re-q2-retained-denominator-repair-smoke-review.tsv"
    )
  ),
  winslash = "/",
  mustWork = FALSE
)
overwrite <- arg_flag("overwrite", FALSE)
sync_dashboard <- arg_flag("sync-dashboard", FALSE)

if (file.exists(output_path) && !overwrite) {
  stop("Output exists; pass --overwrite=true to replace it: ", output_path, call. = FALSE)
}

dispatch <- read_tsv(dispatch_path)
decision <- read_tsv(decision_path)
repair <- read_tsv(repair_path)

required_dispatch <- c(
  "cell_id",
  "provider",
  "artifact_status",
  "n_rep",
  "host_class",
  "host_name",
  "observed_target_rows",
  "expected_target_rows",
  "n_fit_ok_min",
  "n_converged_min",
  "n_pdhess_min",
  "n_wald_finite_min",
  "n_profile_finite_min",
  "interval_repair_channel",
  "n_repair_attempted_min",
  "n_repair_finite_min",
  "min_wald_coverage",
  "max_wald_mcse",
  "min_profile_coverage",
  "max_profile_mcse",
  "min_repair_coverage",
  "max_repair_mcse",
  "wald_lower_miss",
  "wald_upper_miss",
  "profile_lower_miss",
  "profile_upper_miss",
  "repair_lower_miss",
  "repair_upper_miss",
  "source_summary",
  "source_replicates",
  "source_seed_manifest",
  "evidence_url",
  "promotion_decision"
)
missing_dispatch <- setdiff(required_dispatch, names(dispatch))
if (length(missing_dispatch) > 0L) {
  stop(
    "repair-smoke dispatch TSV is missing fields: ",
    paste(missing_dispatch, collapse = ", "),
    call. = FALSE
  )
}

required_decision <- c(
  "cell_id",
  "decision_status",
  "topup_decision",
  "status_edit_decision",
  "blocker_targets",
  "source_review_synthesis",
  "source_pregrid_results",
  "claim_boundary"
)
missing_decision <- setdiff(required_decision, names(decision))
if (length(missing_decision) > 0L) {
  stop(
    "q2 retained-denominator decision TSV is missing fields: ",
    paste(missing_decision, collapse = ", "),
    call. = FALSE
  )
}

required_repair <- c("cell_id", "repair_focus", "repair_targets", "claim_boundary")
missing_repair <- setdiff(required_repair, names(repair))
if (length(missing_repair) > 0L) {
  stop(
    "q2 retained-denominator repair-contract TSV is missing fields: ",
    paste(missing_repair, collapse = ", "),
    call. = FALSE
  )
}

cell_order <- c(
  "qseries_phylo_q2_mu1_mu2_intercept",
  "qseries_spatial_q2_mu1_mu2_intercept",
  "qseries_animal_q2_mu1_mu2_intercept",
  "qseries_relmat_q2_mu1_mu2_intercept",
  "qseries_phylo_q2_plus_q2_intercept"
)
if (!setequal(dispatch$cell_id, cell_order)) {
  stop("repair-smoke dispatch rows must be the five q2 repair-contract cells.", call. = FALSE)
}
if (!setequal(decision$cell_id, cell_order) || !setequal(repair$cell_id, cell_order)) {
  stop("repair-smoke review inputs must share the same five cell IDs.", call. = FALSE)
}
if (!all(dispatch$promotion_decision == "do_not_promote")) {
  stop("repair-smoke dispatch rows must not promote support cells.", call. = FALSE)
}

dispatch <- dispatch[match(cell_order, dispatch$cell_id), , drop = FALSE]
decision <- decision[match(cell_order, decision$cell_id), , drop = FALSE]
repair <- repair[match(cell_order, repair$cell_id), , drop = FALSE]

finite_signal <- function(row) {
  paste0(
    "fit_ok_min=", row$n_fit_ok_min,
    ";converged_min=", row$n_converged_min,
    ";pdHess_min=", row$n_pdhess_min,
    ";wald_finite_min=", row$n_wald_finite_min,
    ";profile_finite_min=", row$n_profile_finite_min,
    ";observed_targets=", row$observed_target_rows, "/", row$expected_target_rows
  )
}

coverage_signal <- function(row) {
  paste0(
    "min_wald_coverage=", row$min_wald_coverage,
    ";max_wald_mcse=", row$max_wald_mcse,
    ";min_profile_coverage=", row$min_profile_coverage,
    ";max_profile_mcse=", row$max_profile_mcse
  )
}

miss_signal <- function(row) {
  paste0(
    "wald_lower_upper=", row$wald_lower_miss, "/", row$wald_upper_miss,
    ";profile_lower_upper=", row$profile_lower_miss, "/", row$profile_upper_miss
  )
}

repair_sidecar_signal <- function(row) {
  paste0(
    "interval_repair_channel=", row$interval_repair_channel,
    ";repair_attempted_min=", row$n_repair_attempted_min,
    ";repair_finite_min=", row$n_repair_finite_min,
    ";min_repair_coverage=", row$min_repair_coverage,
    ";max_repair_mcse=", row$max_repair_mcse,
    ";repair_lower_upper=", row$repair_lower_miss, "/", row$repair_upper_miss
  )
}

repair_route_evaluated <- function(row) {
  if (!identical(row$interval_repair_channel, "none")) {
    return(paste(
      "diagnostic_repair_sidecar",
      row$interval_repair_channel,
      "evaluated_primary_endpoint_route_retained"
    ))
  }
  "existing_interval_route_only_no_new_repair"
}

review_status <- function(row) {
  if (identical(row$artifact_status, "repair_smoke_finiteness_review_required_no_promotion")) {
    return("repair_smoke_finiteness_blocked_no_topup")
  }
  if (identical(row$artifact_status, "repair_smoke_mcse_gt_0.01_review_required_no_promotion")) {
    return("repair_smoke_existing_route_not_enough_no_topup")
  }
  if (identical(row$artifact_status, "repair_smoke_completed_review_required_no_promotion")) {
    return("repair_smoke_completed_but_not_promotion_evidence")
  }
  "repair_smoke_not_imported_or_failed_no_topup"
}

fisher_decision <- function(row, prior) {
  sidecar_clause <- if (!identical(row$interval_repair_channel, "none")) {
    paste(
      "diagnostic repair sidecar",
      row$interval_repair_channel,
      "is recorded separately and requires Fisher/Rose/Grace review before",
      "any top-up"
    )
  } else {
    "no named repair sidecar was evaluated"
  }
  if (identical(row$cell_id, "qseries_phylo_q2_plus_q2_intercept")) {
    return(
      paste(
        "block_topup_for_inference; Totoro smoke reran the existing interval",
        "route, has profile finite loss (minimum 14/16), and did not repair",
        "the SR150 pdHess/interval-shape blocker;",
        sidecar_clause
      )
    )
  }
  paste(
    "block_topup_for_inference; Totoro smoke reran the existing interval route",
    "only, has MCSE above 0.01, and does not repair the SR150 interval-shape",
    "blocker recorded as",
    prior$decision_status,
    ";",
    sidecar_clause
  )
}

rose_decision <- function(row) {
  paste(
    "keep_status_unpromoted; repair smoke is diagnostic-only and must not be",
    "summarized as interval_status, coverage_status, inference_ready,",
    "supported, q2 inheritance, q4/q8, non-Gaussian interval, REML, AI-REML,",
    "bridge support, or public support"
  )
}

grace_decision <- function(row) {
  paste(
    "block_cluster_topup; do not spend Totoro, Nibi, Rorqual, Trillium, or",
    "other DRAC cores until a named interval repair route exists and this",
    "same retained-denominator smoke contract passes"
  )
}

topup_decision <- function(row) {
  if (identical(row$cell_id, "qseries_phylo_q2_plus_q2_intercept")) {
    return(
      "blocked_no_topup_until_profile_finiteness_interval_shape_and_held_sigma1_sigma2_correlation_route_are_repaired"
    )
  }
  "blocked_no_topup_until_named_interval_repair_route_is_defined_and_smoke_passes"
}

out <- do.call(rbind, lapply(seq_len(nrow(dispatch)), function(i) {
  row <- dispatch[i, , drop = FALSE]
  prior <- decision[i, , drop = FALSE]
  repair_row <- repair[i, , drop = FALSE]
  data.frame(
    review_id = paste0("q2_retained_denominator_repair_smoke_review_", row$cell_id),
    cell_id = row$cell_id,
    provider = row$provider,
    smoke_artifact_status = row$artifact_status,
    review_status = review_status(row),
    repair_route_evaluated = repair_route_evaluated(row),
    smoke_host = paste(row$host_class, row$host_name, sep = "/"),
    smoke_n_rep = row$n_rep,
    observed_target_rows = row$observed_target_rows,
    expected_target_rows = row$expected_target_rows,
    finite_signal = finite_signal(row),
    coverage_signal = coverage_signal(row),
    miss_balance_signal = miss_signal(row),
    interval_repair_channel = row$interval_repair_channel,
    repair_sidecar_signal = repair_sidecar_signal(row),
    prior_decision_status = prior$decision_status,
    prior_topup_decision = prior$topup_decision,
    repair_focus = repair_row$repair_focus,
    repair_targets = repair_row$repair_targets,
    fisher_decision = fisher_decision(row, prior),
    rose_decision = rose_decision(row),
    grace_decision = grace_decision(row),
    topup_decision = topup_decision(row),
    status_edit_decision = "do_not_promote_keep_point_fit_planned_planned",
    promotion_decision = "do_not_promote",
    evidence_url = row$evidence_url,
    source_dispatch = rel_path(dispatch_path),
    source_prior_decision = rel_path(decision_path),
    source_repair_contract = rel_path(repair_path),
    source_summary = row$source_summary,
    source_replicates = row$source_replicates,
    source_seed_manifest = row$source_seed_manifest,
    claim_boundary = paste(
      "Fisher/Rose/Grace repair-smoke review promotes exactly no Q-Series row;",
      "the Totoro smoke is diagnostic-only and does not change interval_status,",
      "coverage_status, inference_ready, supported, q2 slope inheritance,",
      "q2-plus inheritance, q4/q8, non-Gaussian intervals, REML, AI-REML,",
      "bridge support, public support, or let repair-sidecar metrics replace",
      "the primary interval route without review."
    ),
    next_gate = paste(
      "Do not submit Totoro, Nibi, Rorqual, Trillium, or other DRAC top-up jobs",
      "until a named interval-repair route exists; rerun this small retained-",
      "denominator repair smoke after the repair with source/run-root checks;",
      "this is the small repair smoke gate, then require Fisher/Rose/Grace",
      "review before any SR475/SR1000 top-up, support-cell edit, or",
      "support-cell status edit."
    ),
    stringsAsFactors = FALSE
  )
}))

write_tsv(out, output_path)
message("Wrote q2 repair-smoke review rows to ", rel_path(output_path))

if (sync_dashboard) {
  review_rel <- rel_path(output_path)
  direct_sd_endpoint_cell <- "qseries_phylo_q2_mu1_mu2_intercept"
  direct_sd_endpoint_evidence <- paste0(
    "docs/dev-log/dashboard/",
    "structured-re-q2-direct-sd-endpoint-route-smoke.tsv"
  )
  direct_sd_endpoint_status <- "q2_direct_sd_endpoint_route_smoke_blocked_no_topup"
  direct_sd_endpoint_run_mode <- "q2_direct_sd_endpoint_route_failed_design_next"
  support_path <- file.path(dashboard_dir, "structured-re-q-series-support-cells.tsv")
  lowq_path <- file.path(dashboard_dir, "structured-re-gaussian-lowq-status-audit.tsv")
  selection_path <- file.path(dashboard_dir, "structured-re-gaussian-lowq-row-selection.tsv")
  closure_path <- file.path(dashboard_dir, "structured-re-q-series-closure-triage.tsv")
  queue_path <- file.path(dashboard_dir, "structured-re-q-series-next-campaign-queue.tsv")

  support <- read_tsv(support_path)
  support_idx <- match(out$cell_id, support$cell_id)
  if (anyNA(support_idx)) {
    stop(
      "Support-cell TSV is missing repair-smoke review cells: ",
      paste(out$cell_id[is.na(support_idx)], collapse = ", "),
      call. = FALSE
    )
  }
  support$claim_boundary[support_idx] <- out$claim_boundary
  support$evidence_url[support_idx] <- review_rel
  support$next_gate[support_idx] <- out$next_gate
  support$fit_status[support_idx] <- "point_fit"
  support$interval_status[support_idx] <- "planned"
  support$coverage_status[support_idx] <- "planned"
  direct_support_idx <- match(direct_sd_endpoint_cell, support$cell_id)
  if (!is.na(direct_support_idx)) {
    support$evidence_url[direct_support_idx] <- direct_sd_endpoint_evidence
  }
  write_tsv(support, support_path)

  lowq <- read_tsv(lowq_path)
  lowq_idx <- match(out$cell_id, lowq$cell_id)
  if (anyNA(lowq_idx)) {
    stop(
      "Gaussian low-q audit TSV is missing repair-smoke review cells: ",
      paste(out$cell_id[is.na(lowq_idx)], collapse = ", "),
      call. = FALSE
    )
  }
  lowq$evidence_basis[lowq_idx] <- paste(
    "Fisher/Rose/Grace repair-smoke review from",
    review_rel,
    "source dispatch",
    out$source_dispatch,
    "source prior decision",
    out$source_prior_decision,
    "source repair contract",
    out$source_repair_contract
  )
  lowq$inference_signal[lowq_idx] <- paste(
    out$review_status,
    out$repair_route_evaluated,
    "named interval-repair route required before any top-up;",
    "no interval_status, coverage_status, inference_ready, supported, top-up,",
    "or status-promotion claim"
  )
  lowq$evidence_url[lowq_idx] <- review_rel
  lowq$claim_boundary[lowq_idx] <- out$claim_boundary
  lowq$next_gate[lowq_idx] <- out$next_gate
  lowq$linked_fit_status[lowq_idx] <- "point_fit"
  lowq$linked_interval_status[lowq_idx] <- "planned"
  lowq$linked_coverage_status[lowq_idx] <- "planned"
  lowq$promotion_decision[lowq_idx] <- "do_not_promote"
  direct_lowq_idx <- match(direct_sd_endpoint_cell, lowq$cell_id)
  if (!is.na(direct_lowq_idx)) {
    lowq$evidence_basis[direct_lowq_idx] <- paste(
      "Direct-SD endpoint-route blocker from",
      direct_sd_endpoint_evidence,
      "remains the row-state authority; retained-denominator repair-smoke",
      "review is also recorded in",
      review_rel,
      "source dispatch",
      out$source_dispatch[match(direct_sd_endpoint_cell, out$cell_id)],
      "source prior decision",
      out$source_prior_decision[match(direct_sd_endpoint_cell, out$cell_id)],
      "source repair contract",
      out$source_repair_contract[match(direct_sd_endpoint_cell, out$cell_id)]
    )
    lowq$evidence_url[direct_lowq_idx] <- direct_sd_endpoint_evidence
  }
  write_tsv(lowq, lowq_path)

  selection <- read_tsv(selection_path)
  selection_idx <- match(out$cell_id, selection$cell_id)
  if (anyNA(selection_idx)) {
    stop(
      "Gaussian low-q row-selection TSV is missing repair-smoke review cells: ",
      paste(out$cell_id[is.na(selection_idx)], collapse = ", "),
      call. = FALSE
    )
  }
  selection$selection_status[selection_idx] <- out$review_status
  selection$run_mode[selection_idx] <- "q2_named_interval_repair_design_first"
  selection$required_preconditions[selection_idx] <- paste(
    "Use",
    review_rel,
    "as the current q2 retained-denominator evidence surface; the Totoro",
    "existing-route smoke is linked to source repair contract",
    rel_path(repair_path),
    "and source prior decision",
    rel_path(decision_path),
    "but the",
    "existing-route smoke was diagnostic-only, so write a named interval-repair",
    "route first. First bounded slice is qseries_phylo_q2_mu1_mu2_intercept",
    "sd_mu2_intercept under endpoint_zero_boundary_profile_channel; direct",
    "correlation and q2-plus routes remain separate. Support cells remain",
    "point_fit/planned/planned; no-promotion boundary is active. Any Totoro",
    "smoke must stay at 50 workers and <=100 workers, include cleanup, and",
    "must not become a mixed-host denominator."
  )
  q2_plus_selection_idx <- selection_idx[
    out$cell_id == "qseries_phylo_q2_plus_q2_intercept"
  ]
  if (length(q2_plus_selection_idx) == 1L && !is.na(q2_plus_selection_idx)) {
    selection$required_preconditions[q2_plus_selection_idx] <- paste(
      selection$required_preconditions[q2_plus_selection_idx],
      "The q2-plus row remains separately blocked: retained pregrid had",
      "pdHess=149/150 patterns and the held sigma1/sigma2 correlation route",
      "must be repaired or explicitly blocked before any top-up."
    )
  }
  selection$evidence_url[selection_idx] <- review_rel
  selection$claim_boundary[selection_idx] <- paste(
    "Gaussian low-q row-selection contract only; this promotes exactly no",
    "Q-Series row; selection status is not interval_status, coverage_status,",
    "inference_ready, supported, sigma, q2, q4/q8, non-Gaussian, REML, AI-REML,",
    "bridge support, or public support. Current repair-smoke review promotes",
    "exactly no Q-Series row and keeps the same no-promotion boundary."
  )
  selection$next_gate[selection_idx] <- out$next_gate
  selection$linked_fit_status[selection_idx] <- "point_fit"
  selection$linked_interval_status[selection_idx] <- "planned"
  selection$linked_coverage_status[selection_idx] <- "planned"
  selection$promotion_decision[selection_idx] <- "do_not_promote"
  direct_selection_idx <- match(direct_sd_endpoint_cell, selection$cell_id)
  if (!is.na(direct_selection_idx)) {
    selection$selection_status[direct_selection_idx] <- direct_sd_endpoint_status
    selection$run_mode[direct_selection_idx] <- direct_sd_endpoint_run_mode
    selection$required_preconditions[direct_selection_idx] <- paste(
      "Primary row-state evidence remains",
      direct_sd_endpoint_evidence,
      "because the endpoint_zero_boundary_profile_channel direct-SD route",
      "failed and must be designed next; the retained-denominator repair-smoke",
      "review is separately recorded in",
      review_rel,
      "with source repair contract",
      rel_path(repair_path),
      "and source prior decision",
      rel_path(decision_path),
      "and is diagnostic-only. First bounded slice remains",
      "qseries_phylo_q2_mu1_mu2_intercept sd_mu2_intercept under",
      "endpoint_zero_boundary_profile_channel; direct correlation and q2-plus",
      "routes remain separate. Support cells remain point_fit/planned/planned;",
      "no-promotion boundary is active. Any Totoro smoke must stay at 50",
      "workers and <=100 workers, include cleanup, and must not become a",
      "mixed-host denominator."
    )
    selection$evidence_url[direct_selection_idx] <- direct_sd_endpoint_evidence
  }
  write_tsv(selection, selection_path)

  closure <- read_tsv(closure_path)
  closure_idx <- match("qseries_closure_gaussian_lowq_gate_required", closure$triage_id)
  if (is.na(closure_idx)) {
    stop(
      "Closure triage TSV is missing qseries_closure_gaussian_lowq_gate_required.",
      call. = FALSE
    )
  }
  closure$status_meaning[closure_idx] <- paste(
    "Gaussian low-q gate rows now include q2 retained-denominator cells whose",
    "Totoro repair-smoke review is recorded in", review_rel,
    "and blocks top-up because only the existing interval route was rerun;",
    "support cells remain point_fit/planned/planned and no row is",
    "inference_ready or supported from this review."
  )
  closure$next_action[closure_idx] <- paste(
    "Do not submit q2 retained-denominator Totoro, Nibi, Rorqual, Trillium,",
    "or other DRAC top-up jobs until a named interval-repair route exists and",
    "passes the same small retained-denominator smoke; continue separate q1",
    "sigma and other low-q repairs under their own row-specific contracts."
  )
  closure$promotion_boundary[closure_idx] <- paste(
    "The q2 repair-smoke review is not interval_status, coverage_status,",
    "inference_ready, supported, q2-slope inheritance, q2-plus inheritance,",
    "q4/q8, non-Gaussian interval, REML, AI-REML, bridge, or public support."
  )
  write_tsv(closure, closure_path)

  queue <- read_tsv(queue_path)
  queue_idx <- match("qseries_queue_gaussian_lowq_interval_design", queue$queue_id)
  if (is.na(queue_idx)) {
    stop(
      "Next-campaign queue TSV is missing qseries_queue_gaussian_lowq_interval_design.",
      call. = FALSE
    )
  }
  queue$readiness_state[queue_idx] <- paste(
    queue$readiness_state[queue_idx],
    "Q2 retained-denominator repair smoke has now been reviewed in",
    review_rel,
    "as existing-route-only diagnostic evidence: four q2 intercept rows need",
    "a named interval-repair route before top-up, and the q2-plus row remains",
    "profile-finiteness blocked."
  )
  queue$required_preconditions[queue_idx] <- paste(
    queue$required_preconditions[queue_idx],
    "For q2 retained-denominator rows, write the named interval-repair route",
    "first, replay retained artifacts if possible, rerun the small smoke on",
    "one host with pinned threads, and get Fisher/Rose/Grace review before",
    "SR475/SR1000 top-up or any support-cell status edit."
  )
  queue$stop_rule[queue_idx] <- paste(
    queue$stop_rule[queue_idx],
    "Stop if q2 retained-denominator compute is escalated on Totoro, Nibi,",
    "Rorqual, Trillium, or DRAC without a named interval-repair route that",
    "already passed the small smoke."
  )
  queue$next_action[queue_idx] <- paste(
    "For q2 retained-denominator rows, do not top up; design a named",
    "interval-repair route, then repeat the small smoke and review before",
    "cluster escalation. For q1 sigma animal/relmat, write the route-hardening",
    "or blocker decision from SR150 evidence before any top-up; keep remaining",
    "support cells point_fit/planned/planned until audit-authorized status edits."
  )
  write_tsv(queue, queue_path)

  message("Synced q2 repair-smoke review dashboard gates.")
}
