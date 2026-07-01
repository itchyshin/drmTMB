#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
overwrite <- "--overwrite=true" %in% args
sync_dashboard <- "--sync-dashboard=true" %in% args

root <- normalizePath(".", winslash = "/", mustWork = TRUE)
dashboard_dir <- file.path(root, "docs/dev-log/dashboard")
out_path <- file.path(
  dashboard_dir,
  "structured-re-gaussian-mu-slope-review-decision.tsv"
)

if (file.exists(out_path) && !overwrite) {
  stop("Output exists; pass --overwrite=true to replace it.", call. = FALSE)
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
  character_cols <- vapply(x, is.character, logical(1L))
  x[character_cols] <- lapply(x[character_cols], function(col) {
    col <- gsub("[\r\n\t]+", " ", col)
    col <- gsub("[^ -~]", "", col)
    gsub(" +", " ", trimws(col))
  })
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

path_dashboard <- function(file) file.path(dashboard_dir, file)

shape_path <- path_dashboard(
  "structured-re-gaussian-mu-slope-interval-shape-diagnostic.tsv"
)
boundary_path <- path_dashboard(
  "structured-re-gaussian-mu-slope-hybrid-boundary-audit.tsv"
)
rule_path <- path_dashboard("structured-re-gaussian-mu-slope-rule-screen.tsv")
split_path <- path_dashboard(
  "structured-re-gaussian-mu-slope-split-calibration.tsv"
)
support_path <- path_dashboard("structured-re-q-series-support-cells.tsv")
lowq_path <- path_dashboard("structured-re-gaussian-lowq-status-audit.tsv")
queue_path <- path_dashboard("structured-re-q-series-next-campaign-queue.tsv")
closure_path <- path_dashboard("structured-re-q-series-closure-triage.tsv")

shape <- read_tsv(shape_path)
boundary <- read_tsv(boundary_path)
rule <- read_tsv(rule_path)
split <- read_tsv(split_path)
support <- read_tsv(support_path)
lowq <- read_tsv(lowq_path)

cells <- c(
  "qseries_phylo_q1_mu_one_slope",
  "qseries_spatial_q1_mu_one_slope",
  "qseries_animal_q1_mu_one_slope",
  "qseries_relmat_q1_mu_one_slope"
)
providers <- c("phylo", "spatial", "animal", "relmat")

if (!all(cells %in% support$cell_id)) {
  stop(
    "Support-cell TSV is missing at least one Gaussian q1 mu one-slope cell.",
    call. = FALSE
  )
}
if (
  !setequal(
    unique(shape$cell_id),
    setdiff(cells, "qseries_animal_q1_mu_one_slope")
  )
) {
  stop(
    "Interval-shape diagnostic must cover phylo, spatial, and relmat q1 mu one-slope cells.",
    call. = FALSE
  )
}
if (!all(cells %in% boundary$cell_id)) {
  stop(
    "Hybrid boundary audit must cover the four q1 mu one-slope cells.",
    call. = FALSE
  )
}

current_rule <- rule[rule$candidate_rule == "current_hybrid", , drop = FALSE]
if (nrow(current_rule) != 1L) {
  stop(
    "Rule screen must contain exactly one current_hybrid row.",
    call. = FALSE
  )
}
large_rule <- rule[
  rule$screen_status == "large_ad_hoc_multiplier_screen_only",
  ,
  drop = FALSE
]
if (nrow(large_rule) < 1L) {
  stop(
    "Rule screen must record the large ad hoc multiplier blockers.",
    call. = FALSE
  )
}

split_slope <- split[split$endpoint_member == "mu:x", , drop = FALSE]
if (
  nrow(split_slope) != 3L ||
    !all(split_slope$holdout_gate_status == "holdout_gate_failed")
) {
  stop(
    "Split calibration must retain failed slope holdout rows.",
    call. = FALSE
  )
}

decision_rows <- lapply(seq_along(cells), function(i) {
  cell_id <- cells[[i]]
  provider <- providers[[i]]
  support_row <- support[support$cell_id == cell_id, , drop = FALSE]
  boundary_row <- boundary[boundary$cell_id == cell_id, , drop = FALSE]
  shape_rows <- shape[shape$cell_id == cell_id, , drop = FALSE]
  split_rows <- split[split$cell_id == cell_id, , drop = FALSE]

  if (cell_id == "qseries_animal_q1_mu_one_slope") {
    row_bucket <- "mu_slope_pregrid_blocked"
    source_interval_shape <- "not_available_animal_hard_blocked_at_sr150"
    denominator_summary <- paste0(
      "SR150 hybrid boundary audit; ",
      boundary_row$n_eligible_target_replicates,
      " target replicates; finite interval rate ",
      fmt4(as.numeric(boundary_row$finite_interval_rate))
    )
    finite_interval_signal <- paste0(
      boundary_row$n_usable_hybrid_intervals,
      "/",
      boundary_row$n_eligible_target_replicates,
      " usable hybrid intervals"
    )
    coverage_signal <- paste0(
      "coverage_all=",
      fmt4(as.numeric(boundary_row$hybrid_coverage_all)),
      "; MCSE=",
      fmt6(as.numeric(boundary_row$hybrid_coverage_mcse))
    )
    miss_signal <- paste0(
      boundary_row$miss_balance,
      "; hard negative before top-up"
    )
    calibration_signal <- "not replayed; animal row is hard-blocked before SR475"
  } else {
    row_bucket <- "mcse_met_upper_tail_blocked"
    source_interval_shape <- "docs/dev-log/dashboard/structured-re-gaussian-mu-slope-interval-shape-diagnostic.tsv"
    denominator_summary <- paste0(
      "SR475 target-level hybrid denominator; ",
      sum(as.integer(shape_rows$n_replicates)),
      " target replicates across intercept and slope"
    )
    finite_interval_signal <- paste0(
      paste0(
        shape_rows$endpoint_member,
        "=",
        shape_rows$n_usable_hybrid_intervals,
        "/",
        shape_rows$n_replicates
      ),
      collapse = "; "
    )
    coverage_signal <- paste0(
      paste0(
        shape_rows$endpoint_member,
        " coverage=",
        shape_rows$hybrid_coverage_all,
        " MCSE=",
        shape_rows$hybrid_coverage_mcse
      ),
      collapse = "; "
    )
    miss_signal <- paste0(
      paste0(
        shape_rows$endpoint_member,
        " lower=",
        shape_rows$n_lower_miss,
        " upper=",
        shape_rows$n_upper_miss
      ),
      collapse = "; "
    )
    calibration_signal <- paste0(
      paste0(
        split_rows$endpoint_member,
        " ",
        split_rows$holdout_gate_status,
        " (",
        split_rows$gate_failures,
        ")"
      ),
      collapse = "; "
    )
  }

  data.frame(
    decision_id = paste0("gaussian_mu_slope_review_decision_", provider),
    cell_id = cell_id,
    provider = provider,
    row_bucket = row_bucket,
    source_interval_shape = source_interval_shape,
    source_boundary_audit = "docs/dev-log/dashboard/structured-re-gaussian-mu-slope-hybrid-boundary-audit.tsv",
    source_rule_screen = "docs/dev-log/dashboard/structured-re-gaussian-mu-slope-rule-screen.tsv",
    source_split_calibration = "docs/dev-log/dashboard/structured-re-gaussian-mu-slope-split-calibration.tsv",
    denominator_summary = denominator_summary,
    finite_interval_signal = finite_interval_signal,
    coverage_signal = coverage_signal,
    miss_signal = miss_signal,
    rule_screen_signal = paste0(
      "current hybrid lower=",
      current_rule$total_lower_miss,
      " upper=",
      current_rule$total_upper_miss,
      "; only large ad hoc 3x variants erase all upper misses"
    ),
    calibration_signal = calibration_signal,
    review_decision = "fisher_rose_noether_interval_rule_required_no_topup",
    promotion_decision = "do_not_promote",
    host_decision = "local_derivation_only_then_totoro_fiia_smoke_after_review",
    blocked_hosts = "Totoro/FIIA/Nibi/Rorqual/Trillium/DRAC top-up before named replacement interval rule",
    linked_fit_status = support_row$fit_status,
    linked_interval_status = support_row$interval_status,
    linked_coverage_status = support_row$coverage_status,
    evidence_url = "docs/dev-log/dashboard/structured-re-gaussian-mu-slope-review-decision.tsv",
    claim_boundary = paste(
      "This promotes exactly no Q-Series row;",
      "Gaussian q1 mu one-slope evidence is reviewed-blocked until Fisher,",
      "Rose, and Noether accept a named replacement interval or calibration",
      "rule; no interval_status, coverage_status, inference_ready, supported,",
      "sigma, q2, q4/q8, non-Gaussian, REML, AI-REML, bridge support,",
      "public support, or host-denominator claim is made."
    ),
    next_gate = paste(
      "Write a target-scoped replacement interval/calibration rule; replay it",
      "against retained artifacts; require all retained target rows to pass",
      "coverage MCSE <= 0.01, finite interval, and one-sided miss-balance",
      "gates; then run one small Totoro/FIIA smoke after Fisher/Rose/Noether",
      "review; do not submit Totoro, Nibi, Rorqual, Trillium, or DRAC",
      "top-up jobs and do not edit support-cell status before that."
    ),
    stringsAsFactors = FALSE
  )
})

out <- do.call(rbind, decision_rows)
write_tsv(out, out_path)

if (sync_dashboard) {
  support_idx <- match(out$cell_id, support$cell_id)
  lowq_idx <- match(out$cell_id, lowq$cell_id)
  if (anyNA(lowq_idx)) {
    stop(
      "Gaussian low-q audit TSV is missing q1 mu one-slope cells.",
      call. = FALSE
    )
  }

  support$claim_boundary[support_idx] <- paste0(
    "Gaussian q1 mu one-slope evidence is reviewed-blocked: ",
    out$provider,
    " remains point_fit/planned/planned because SR475 or SR150 evidence shows ",
    "upper-tail, finite-interval, or hard-boundary blockers. This promotes ",
    "exactly no Q-Series row and does not claim interval_status, coverage_status, ",
    "inference_ready, supported, sigma, q2, q4/q8, non-Gaussian, REML, AI-REML, ",
    "bridge support, host denominator readiness, or public support."
  )
  support$next_gate[support_idx] <- out$next_gate
  support$fit_status[support_idx] <- "point_fit"
  support$interval_status[support_idx] <- "planned"
  support$coverage_status[support_idx] <- "planned"
  write_tsv(support, support_path)

  lowq$inference_signal[lowq_idx] <- paste(
    "Reviewed-blocked q1 mu one-slope interval-shape evidence:",
    "MCSE-qualified SR475 rows still show upper-tail blockers for",
    "phylo/spatial/relmat, and animal is hard-blocked at SR150; interval and",
    "coverage remain planned until a named replacement interval/calibration",
    "rule passes retained-artifact replay and small smoke."
  )
  lowq$next_gate[lowq_idx] <- out$next_gate
  lowq$linked_fit_status[lowq_idx] <- "point_fit"
  lowq$linked_interval_status[lowq_idx] <- "planned"
  lowq$linked_coverage_status[lowq_idx] <- "planned"
  lowq$promotion_decision[lowq_idx] <- "do_not_promote"
  write_tsv(lowq, lowq_path)

  queue <- read_tsv(queue_path)
  queue_idx <- match(
    "qseries_queue_gaussian_mu_slope_shape_rule",
    queue$queue_id
  )
  if (is.na(queue_idx)) {
    stop(
      "Next-campaign queue is missing qseries_queue_gaussian_mu_slope_shape_rule.",
      call. = FALSE
    )
  }
  queue$allowed_hosts[queue_idx] <- paste(
    "local derivation and retained-artifact replay;",
    "Totoro/FIIA only for the first smoke after Fisher/Rose/Noether accept a",
    "named replacement rule; Nibi/Rorqual/Trillium/DRAC only after smoke"
  )
  queue$blocked_hosts[queue_idx] <- paste(
    "Totoro/FIIA/Nibi/Rorqual/Trillium/DRAC top-up before replacement rule",
    "and retained-artifact replay"
  )
  queue$readiness_state[queue_idx] <- paste(
    "Reviewed-blocked: animal has SR150 hard-boundary evidence; phylo, spatial,",
    "and relmat have SR475 MCSE-qualified but upper-tail-blocked evidence;",
    "rule-screen and split-calibration replays are non-promotional."
  )
  queue$required_preconditions[queue_idx] <- paste(
    "New target-scoped interval-shape or calibration rule must be written,",
    "replayed on retained artifacts, and accepted by Fisher/Rose/Noether before",
    "any host smoke or denominator spending."
  )
  queue$next_action[queue_idx] <- paste(
    "Design a replacement interval/calibration rule, replay it on retained",
    "artifacts, then smoke one target on Totoro/FIIA; keep Trillium/DRAC top-up",
    "held until that smoke passes and Grace confirms reproducibility artifacts."
  )
  write_tsv(queue, queue_path)

  closure <- read_tsv(closure_path)
  closure_idx <- match(
    c(
      "qseries_closure_mu_slope_pregrid_blocked",
      "qseries_closure_mcse_met_upper_tail_blocked"
    ),
    closure$triage_id
  )
  if (anyNA(closure_idx)) {
    stop("Closure triage is missing q1 mu-slope blocker rows.", call. = FALSE)
  }
  closure$next_action[closure_idx] <- c(
    "Do not top up on Totoro, Nibi, Rorqual, Trillium, or DRAC until the finite-interval or boundary-profile channel is repaired and replayed.",
    "Run Fisher/Rose/Noether interval-shape review before any support-cell status edit or Trillium/DRAC top-up."
  )
  write_tsv(closure, closure_path)
}

message("Wrote Gaussian mu-slope review decision rows to ", out_path)
