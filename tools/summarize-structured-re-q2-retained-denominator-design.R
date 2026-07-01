#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
overwrite <- "--overwrite=true" %in% args

root <- normalizePath(".", winslash = "/", mustWork = TRUE)
dashboard_dir <- file.path(root, "docs/dev-log/dashboard")

out_path <- file.path(
  dashboard_dir,
  "structured-re-q2-retained-denominator-design.tsv"
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

support <- read_tsv(
  file.path(dashboard_dir, "structured-re-q-series-support-cells.tsv")
)
row_selection <- read_tsv(
  file.path(dashboard_dir, "structured-re-gaussian-lowq-row-selection.tsv")
)
q2_contract <- read_tsv(
  file.path(dashboard_dir, "structured-re-q2-intercept-interval-contract.tsv")
)
q2_smoke <- read_tsv(
  file.path(dashboard_dir, "structured-re-q2-intercept-nibi-smoke.tsv")
)
q2_plus_contract <- read_tsv(
  file.path(dashboard_dir, "structured-re-q2-plus-q2-intercept-contract.tsv")
)
q2_plus_smoke <- read_tsv(
  file.path(dashboard_dir, "structured-re-q2-plus-q2-intercept-nibi-smoke.tsv")
)

support_by_cell <- split(support, support$cell_id)
selection_by_cell <- split(row_selection, row_selection$cell_id)

merge_contract_smoke <- function(contract, smoke, design_family) {
  merged <- merge(
    contract,
    smoke[, c("contract_id", "smoke_id", "smoke_status", "n_rep",
              "n_fit_ok", "n_pdhess", "n_wald_finite", "n_profile_finite",
              "lower_miss", "upper_miss")],
    by = "contract_id",
    all.x = FALSE,
    all.y = FALSE,
    sort = FALSE
  )
  merged$design_family <- design_family
  merged
}

q2_rows <- merge_contract_smoke(q2_contract, q2_smoke, "q2_intercept")
q2_plus_direct <- q2_plus_contract[
  q2_plus_contract$target_kind != "blocked_cross_block_correlation",
  ,
  drop = FALSE
]
q2_plus_rows <- merge_contract_smoke(
  q2_plus_direct,
  q2_plus_smoke,
  "q2_plus_q2_intercept"
)

rows <- rbind(q2_rows, q2_plus_rows)
if (nrow(rows) != 18L) {
  stop("Expected 18 q2 retained-denominator target rows.", call. = FALSE)
}

design_id <- paste0(
  "q2_retained_denominator_design_",
  rows$design_family,
  "_",
  rows$provider,
  "_",
  gsub("[^A-Za-z0-9]+", "_", rows$estimand)
)

is_profile_blocked <- rows$design_family == "q2_plus_q2_intercept" &
  rows$estimand == "cor_sigma1_sigma2_intercept" &
  rows$smoke_status == "nibi_rorqual_substitute_smoke_failed"
is_ready <- !is_profile_blocked
is_location_sd <- rows$target_kind == "direct_sd" &
  grepl("^sd_mu", rows$estimand)
is_sigma_sd <- rows$target_kind == "direct_sd" &
  grepl("^sd_sigma", rows$estimand)
is_correlation <- rows$target_kind == "direct_correlation"

source_row_selection_id <- vapply(rows$cell_id, function(cell_id) {
  selection <- selection_by_cell[[cell_id]]
  if (is.null(selection)) {
    stop("Missing row-selection source for ", cell_id, call. = FALSE)
  }
  selection$selection_id[[1]]
}, character(1L))

linked_status <- vapply(rows$cell_id, function(cell_id) {
  cell <- support_by_cell[[cell_id]]
  if (is.null(cell)) {
    stop("Missing support cell for ", cell_id, call. = FALSE)
  }
  paste(cell$fit_status[[1]], cell$interval_status[[1]], cell$coverage_status[[1]],
    sep = "/"
  )
}, character(1L))

interval_channel <- rows$interval_channel
interval_channel[is_location_sd] <- paste(
  interval_channel[is_location_sd],
  "default_bias_t_location_axis",
  sep = ";"
)
interval_channel[is_sigma_sd] <- paste(
  interval_channel[is_sigma_sd],
  "raw_sigma_side_no_location_bias_t",
  sep = ";"
)
interval_channel[is_correlation] <- paste(
  interval_channel[is_correlation],
  "direct_correlation_not_inherited_from_endpoint_sd",
  sep = ";"
)

denominator_policy <- paste(
  rows$denominator_policy,
  "all_attempted_replicates_retained",
  "fit_convergence_pdhess_wald_profile_nonfinite_warning_rows_retained",
  "finite_denominator_reported",
  "n5_smoke_not_coverage",
  sep = ";"
)

pregrid_n_rep <- ifelse(is_ready, "150", "0")
target_decision <- ifelse(
  is_ready,
  "sr150_pregrid_ready_no_promotion",
  "profile_repair_required_no_pregrid"
)
design_status <- ifelse(
  is_ready,
  "fisher_rose_grace_sr150_pregrid_design_ready_no_promotion",
  "fisher_rose_profile_failure_repair_required_no_pregrid"
)

one_sided_miss_policy <- paste(
  "report lower and upper misses, miss rates, upper:lower ratio, and",
  "profile-specific misses for every retained target; no inference_ready if",
  "severe miss imbalance, finite-profile censoring, or target-level hard",
  "negative remains"
)

allowed_hosts <- ifelse(
  is_ready,
  paste(
    "Nibi primary for SR150 retained-denominator pregrid after",
    "Fisher/Rose/Grace design acceptance; Rorqual confirmation or overflow",
    "only under the same seed manifest; local artifact replay is required;",
    "Totoro/FIIA optional confirmation smoke only"
  ),
  paste(
    "local or Rorqual/Nibi artifact replay for profile-failure repair only;",
    "no denominator pregrid until Fisher/Rose/Grace accept the repaired",
    "finite-profile route"
  )
)

blocked_hosts <- ifelse(
  is_ready,
  paste(
    "Any Nibi/Rorqual/DRAC denominator run that omits this design, mixes hosts",
    "without a new seed manifest, drops attempted rows, or bundles q1, q2",
    "slope, q2-plus failed targets, q4/q8, non-Gaussian, REML, AI-REML, bridge",
    "support, public support, or supported claims"
  ),
  paste(
    "Nibi/Rorqual/DRAC denominator pregrid before the sigma1/sigma2",
    "profile-failure blocker is repaired or explained; cross-block",
    "correlations, q4/q8, non-Gaussian, REML, AI-REML, bridge support, public",
    "support, inference_ready, and supported claims remain blocked"
  )
)

required_artifacts <- paste(
  "raw_replicate_tsv",
  "summary_tsv",
  "seed_manifest",
  "run_log",
  "sessionInfo.txt",
  "git-sha.txt",
  "module-list.txt",
  "scheduler_stdout_stderr",
  "seff_when_available",
  "exact_command_lines",
  "check_log",
  "after_task",
  "mission_control",
  sep = ";"
)

stop_rule <- ifelse(
  is_ready,
  paste(
    "Stop if candidate set changes, linked support cell is not",
    "point_fit/planned/planned, attempted rows are dropped, convergence/pdHess",
    "or profile failures are censored from the denominator, one-sided misses or",
    "warnings are not reported, MCSE remains above 0.01 after top-up, endpoint",
    "SD evidence is inherited by a correlation target, or any interval_status,",
    "coverage_status, inference_ready, supported, or public-support wording",
    "appears before evidence review"
  ),
  paste(
    "Stop before pregrid; repair or explain the q2-plus sigma1/sigma2",
    "finite-profile failure, retain the failed seed and profile message, keep",
    "pregrid_n_rep at 0, and block any interval_status, coverage_status,",
    "inference_ready, supported, or public-support wording"
  )
)

claim_boundary <- ifelse(
  rows$design_family == "q2_intercept",
  paste(
    "This promotes exactly no Q-Series row; it defines the retained-denominator",
    "design for q2 intercept target rows only; Nibi n=5 smoke is fixture",
    "evidence, not coverage; endpoint SD and direct-correlation targets remain",
    "separate; no interval_status, coverage_status, inference_ready, supported,",
    "q1, q2 slope, q2-plus-q2, q4/q8, non-Gaussian interval, REML, AI-REML,",
    "bridge support, or public support claim."
  ),
  paste(
    "This promotes exactly no Q-Series row; it defines the retained-denominator",
    "design for q2-plus-q2 within-block target rows only; Nibi n=5 smoke is",
    "fixture evidence, not coverage; sigma-side targets do not inherit the",
    "location-axis bias+t default; the sigma1/sigma2 profile failure and",
    "cross-block correlations remain blocked; no interval_status,",
    "coverage_status, inference_ready, supported, q2-only location support,",
    "q4/q8, non-Gaussian interval, REML, AI-REML, bridge support, or public",
    "support claim."
  )
)

next_gate <- ifelse(
  is_ready,
  paste(
    "Run an SR150 retained-denominator pregrid on one primary DRAC host with",
    "pinned threads, predeclared seeds, raw replicate TSVs, finite denominator,",
    "convergence, pdHess, profile/Wald finite-status accounting, warnings, and",
    "lower/upper misses; MCSE <= 0.01 is a top-up target, not an SR150 pass",
    "claim; Fisher/Rose/Grace review required before any status-table edit."
  ),
  paste(
    "Repair or explain the retained sigma1/sigma2 finite-profile blocker before",
    "any SR150 pregrid; keep the failed seed, profile message, cross-block",
    "correlation block, and no-promotion boundary visible."
  )
)

out <- data.frame(
  design_id = design_id,
  cell_id = rows$cell_id,
  provider = rows$provider,
  design_family = rows$design_family,
  source_row_selection_id = source_row_selection_id,
  source_interval_contract_id = rows$contract_id,
  source_nibi_smoke_id = rows$smoke_id,
  formula_cell = rows$formula_cell,
  target_kind = rows$target_kind,
  endpoint_member = rows$endpoint_member,
  estimand = rows$estimand,
  profile_target = rows$profile_target,
  interval_channel = interval_channel,
  denominator_policy = denominator_policy,
  pregrid_n_rep = pregrid_n_rep,
  mcse_threshold = "0.01",
  one_sided_miss_policy = one_sided_miss_policy,
  target_decision = target_decision,
  allowed_hosts = allowed_hosts,
  blocked_hosts = blocked_hosts,
  required_artifacts = required_artifacts,
  stop_rule = stop_rule,
  design_status = design_status,
  linked_support_status = linked_status,
  promotion_decision = "do_not_promote",
  evidence_url = paste0(
    "docs/dev-log/after-task/",
    "2026-06-30-q-series-q2-retained-denominator-design.md"
  ),
  claim_boundary = claim_boundary,
  next_gate = next_gate,
  stringsAsFactors = FALSE
)

write_tsv(out, out_path)
