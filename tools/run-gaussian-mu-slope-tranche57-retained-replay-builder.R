#!/usr/bin/env Rscript

`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0L || is.na(x)) y else x
}

args <- commandArgs(TRUE)
if (any(args %in% c("--help", "-h"))) {
  cat(
    paste(
      "Usage: Rscript tools/run-gaussian-mu-slope-tranche57-retained-replay-builder.R [options]",
      "",
      "Options:",
      "  --output-dir=PATH         Artifact directory.",
      "  --overwrite=true          Replace an existing artifact directory.",
      "  --write-dashboard=false   Do not overwrite the dashboard summary sidecar.",
      "",
      "This is a local retained-artifact replay builder only. It reads existing",
      "q1 mu one-slope artifacts and writes detail/summary TSVs without running",
      "fits, selecting an interval rule, or editing support-cell status.",
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

script_file <- sub(
  "^--file=",
  "",
  grep("^--file=", commandArgs(FALSE), value = TRUE)[1L] %||% "tools"
)
repo_root <- normalizePath(file.path(dirname(script_file), ".."))
if (!file.exists(file.path(repo_root, "DESCRIPTION"))) {
  repo_root <- normalizePath(getwd())
}

clean_text <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- "NA"
  x <- gsub("[\r\n\t]+", " ", x)
  x <- gsub("[^ -~]", "", x)
  x <- gsub(" +", " ", x)
  trimws(x)
}

write_tsv <- function(x, path) {
  character_cols <- vapply(x, is.character, logical(1L))
  x[character_cols] <- lapply(x[character_cols], clean_text)
  utils::write.table(
    x,
    path,
    sep = "\t",
    quote = FALSE,
    row.names = FALSE,
    na = "NA"
  )
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

bool <- function(x) {
  tolower(as.character(x)) %in% c("true", "1", "yes")
}

fmt4 <- function(x) {
  ifelse(is.na(x), "NA", sprintf("%.4f", x))
}

fmt6 <- function(x) {
  ifelse(is.na(x), "NA", sprintf("%.6f", x))
}

mcse_proportion <- function(x) {
  x <- x[!is.na(x)]
  if (length(x) == 0L) {
    return(NA_real_)
  }
  p <- mean(x)
  sqrt(p * (1 - p) / length(x))
}

rel <- function(...) {
  file.path(...)
}

dashboard_dir <- file.path(repo_root, "docs", "dev-log", "dashboard")
artifact_root <- file.path(repo_root, "docs", "dev-log", "simulation-artifacts")
default_output_dir <- file.path(
  artifact_root,
  "2026-07-02-gaussian-mu-slope-tranche57-retained-replay-local"
)
output_dir <- normalizePath(
  arg_value("output-dir", default_output_dir),
  mustWork = FALSE
)
overwrite <- arg_flag("overwrite", FALSE)
write_dashboard <- arg_flag("write-dashboard", TRUE)

if (dir.exists(output_dir) && !overwrite) {
  stop(
    "`output-dir` already exists. Use --overwrite=true to replace it: ",
    output_dir,
    call. = FALSE
  )
}
if (dir.exists(output_dir) && overwrite) {
  unlink(output_dir, recursive = TRUE)
}
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

source_specs <- data.frame(
  source_id = c(
    "base_sr150_wald",
    "topup_sr151_475_wald",
    "base_boundary_profile",
    "topup_boundary_profile",
    "rule_screen_targets",
    "split_calibration_targets",
    "tranche55_hold",
    "tranche56_symbolic_contract"
  ),
  source_role = c(
    "wald_replicate_detail",
    "wald_replicate_detail",
    "profile_boundary_detail",
    "profile_boundary_detail",
    "diagnostic_rule_screen_targets",
    "diagnostic_split_calibration_targets",
    "status_hold_decision",
    "symbolic_replay_contract"
  ),
  source_path = c(
    rel("docs", "dev-log", "simulation-artifacts", "2026-06-29-gaussian-mu-slope-coverage-pregrid-local", "structured-re-gaussian-mu-slope-coverage-pregrid-replicates.tsv"),
    rel("docs", "dev-log", "simulation-artifacts", "2026-06-29-gaussian-mu-slope-topup-sr475-local", "structured-re-gaussian-mu-slope-coverage-pregrid-replicates.tsv"),
    rel("docs", "dev-log", "simulation-artifacts", "2026-06-29-gaussian-mu-slope-boundary-profile-diagnostic-local", "structured-re-gaussian-mu-slope-boundary-profile-diagnostic-detail.tsv"),
    rel("docs", "dev-log", "simulation-artifacts", "2026-06-29-gaussian-mu-slope-topup-boundary-profile-local", "structured-re-gaussian-mu-slope-boundary-profile-diagnostic-detail.tsv"),
    rel("docs", "dev-log", "simulation-artifacts", "2026-06-29-gaussian-mu-slope-rule-screen-local", "structured-re-gaussian-mu-slope-rule-screen-target-detail.tsv"),
    rel("docs", "dev-log", "simulation-artifacts", "2026-06-29-gaussian-mu-slope-split-calibration-local", "structured-re-gaussian-mu-slope-split-calibration.tsv"),
    rel("docs", "dev-log", "dashboard", "structured-re-gaussian-mu-slope-tranche55-interval-rule-hold-decision.tsv"),
    rel("docs", "dev-log", "dashboard", "structured-re-gaussian-mu-slope-tranche56-symbolic-interval-rule-contract.tsv")
  ),
  host_label = c(
    "local",
    "local",
    "local",
    "local",
    "local",
    "local",
    "local_dashboard",
    "local_dashboard"
  ),
  denominator_label = c(
    "sr1_150",
    "sr151_475",
    "sr1_150_boundary_profile",
    "sr151_475_boundary_profile",
    "retained_diagnostic_screen",
    "retained_diagnostic_split",
    "not_denominator",
    "not_denominator"
  ),
  required = rep("TRUE", 8L),
  stringsAsFactors = FALSE
)

source_specs$absolute_path <- file.path(repo_root, source_specs$source_path)
source_specs$exists <- file.exists(source_specs$absolute_path)
if (!all(source_specs$exists)) {
  missing <- source_specs$source_path[!source_specs$exists]
  stop("Missing required retained replay source(s): ", paste(missing, collapse = ", "), call. = FALSE)
}

source_specs$n_rows <- vapply(
  source_specs$absolute_path,
  function(path) nrow(read_tsv(path)),
  integer(1L)
)
source_specs$source_status <- "source_resolved"

wald_from_source <- function(spec_row) {
  x <- read_tsv(spec_row$absolute_path)
  data.frame(
    replay_detail_id = paste(
      "tranche57",
      spec_row$source_id,
      x$provider,
      gsub("[^A-Za-z0-9]+", "_", x$endpoint_member),
      x$replicate_index,
      sep = "_"
    ),
    source_id = spec_row$source_id,
    source_role = spec_row$source_role,
    source_path = spec_row$source_path,
    host_label = spec_row$host_label,
    denominator_label = spec_row$denominator_label,
    row_kind = "wald_replicate",
    candidate_rule = "current_hybrid_wald_endpoint",
    cell_id = x$cell_id,
    provider = x$provider,
    endpoint_member = x$endpoint_member,
    direct_sd_target = x$direct_sd_target,
    replicate_index = as.character(x$replicate_index),
    seed = as.character(x$seed),
    truth = as.character(x$truth),
    estimate = as.character(x$estimate),
    conf_low = as.character(x$conf.low),
    conf_high = as.character(x$conf.high),
    finite_interval = as.character(bool(x$usable_interval)),
    covered = as.character(bool(x$covered)),
    lower_miss = as.character(bool(x$lower_miss)),
    upper_miss = as.character(bool(x$upper_miss)),
    fit_ok = as.character(bool(x$fit_ok)),
    converged = as.character(bool(x$converged)),
    pdHess = as.character(bool(x$pdHess)),
    source_status = x$interval_status,
    include_in_replay_denominator = "TRUE",
    claim_boundary = "T57 retained replay input only; current hybrid diagnostic rows are not coverage authorization, interval_status, inference_ready, supported, or host evidence.",
    stringsAsFactors = FALSE
  )
}

profile_from_source <- function(spec_row) {
  x <- read_tsv(spec_row$absolute_path)
  data.frame(
    replay_detail_id = paste(
      "tranche57",
      spec_row$source_id,
      x$provider,
      gsub("[^A-Za-z0-9]+", "_", x$endpoint_member),
      x$replicate_index,
      sep = "_"
    ),
    source_id = spec_row$source_id,
    source_role = spec_row$source_role,
    source_path = spec_row$source_path,
    host_label = spec_row$host_label,
    denominator_label = spec_row$denominator_label,
    row_kind = "profile_boundary_detail",
    candidate_rule = "current_hybrid_boundary_profile",
    cell_id = x$cell_id,
    provider = x$provider,
    endpoint_member = x$endpoint_member,
    direct_sd_target = ifelse(
      x$endpoint_member == "mu:(Intercept)",
      "sd_mu_intercept",
      "sd_mu_x"
    ),
    replicate_index = as.character(x$replicate_index),
    seed = as.character(x$seed),
    truth = as.character(x$truth),
    estimate = as.character(x$wald_estimate),
    conf_low = as.character(x$profile_lower),
    conf_high = as.character(x$profile_upper),
    finite_interval = as.character(bool(x$profile_finite_interval)),
    covered = as.character(bool(x$profile_covered)),
    lower_miss = as.character(bool(x$profile_lower_miss)),
    upper_miss = as.character(bool(x$profile_upper_miss)),
    fit_ok = as.character(bool(x$fit_ok)),
    converged = as.character(bool(x$converged)),
    pdHess = as.character(bool(x$pdHess)),
    source_status = x$diagnostic_verdict,
    include_in_replay_denominator = "FALSE",
    claim_boundary = "T57 boundary/profile diagnostic input only; profile rows are replay strata and not denominator survivors, coverage authorization, interval_status, inference_ready, supported, or host evidence.",
    stringsAsFactors = FALSE
  )
}

diagnostic_from_source <- function(spec_row) {
  x <- read_tsv(spec_row$absolute_path)
  if ("target_id" %in% names(x)) {
    id <- x$target_id
    candidate <- x$screen_id
    status <- x$target_status
    n_rep <- x$n_replicates
    n_usable <- x$n_usable_intervals
    coverage <- x$coverage
    lower <- x$n_lower_miss
    upper <- x$n_upper_miss
    direct <- x$direct_sd_target
  } else {
    id <- x$calibration_id
    candidate <- "split_calibration_holdout"
    status <- x$holdout_gate_status
    n_rep <- x$validation_n_replicates
    n_usable <- x$validation_n_usable
    coverage <- x$validation_coverage
    lower <- x$validation_lower_miss
    upper <- x$validation_upper_miss
    direct <- x$direct_sd_target
  }
  data.frame(
    replay_detail_id = paste("tranche57", spec_row$source_id, id, sep = "_"),
    source_id = spec_row$source_id,
    source_role = spec_row$source_role,
    source_path = spec_row$source_path,
    host_label = spec_row$host_label,
    denominator_label = spec_row$denominator_label,
    row_kind = spec_row$source_role,
    candidate_rule = candidate,
    cell_id = x$cell_id,
    provider = x$provider,
    endpoint_member = x$endpoint_member,
    direct_sd_target = direct,
    replicate_index = "NA",
    seed = "NA",
    truth = "NA",
    estimate = "NA",
    conf_low = "NA",
    conf_high = "NA",
    finite_interval = "NA",
    covered = as.character(!is.na(coverage)),
    lower_miss = as.character(lower > 0L),
    upper_miss = as.character(upper > 0L),
    fit_ok = "NA",
    converged = "NA",
    pdHess = "NA",
    source_status = status,
    include_in_replay_denominator = "FALSE",
    claim_boundary = paste(
      "T57 diagnostic source summary only;",
      "n_replicates=", n_rep,
      "n_usable=", n_usable,
      "coverage=", coverage,
      "lower_miss=", lower,
      "upper_miss=", upper,
      "no executable rule, coverage authorization, interval_status, inference_ready, supported, or host evidence.",
      sep = " "
    ),
    stringsAsFactors = FALSE
  )
}

wald_specs <- source_specs[source_specs$source_role == "wald_replicate_detail", ]
profile_specs <- source_specs[source_specs$source_role == "profile_boundary_detail", ]
diagnostic_specs <- source_specs[
  source_specs$source_role %in% c(
    "diagnostic_rule_screen_targets",
    "diagnostic_split_calibration_targets"
  ),
]

detail <- do.call(
  rbind,
  c(
    lapply(split(wald_specs, seq_len(nrow(wald_specs))), wald_from_source),
    lapply(split(profile_specs, seq_len(nrow(profile_specs))), profile_from_source),
    lapply(split(diagnostic_specs, seq_len(nrow(diagnostic_specs))), diagnostic_from_source)
  )
)
row.names(detail) <- NULL

support_cells <- c(
  "qseries_phylo_q1_mu_one_slope",
  "qseries_spatial_q1_mu_one_slope",
  "qseries_animal_q1_mu_one_slope",
  "qseries_relmat_q1_mu_one_slope"
)
endpoints <- c("mu:(Intercept)", "mu:x")

summarise_target <- function(provider, endpoint) {
  wald <- detail[
    detail$row_kind == "wald_replicate" &
      detail$provider == provider &
      detail$endpoint_member == endpoint,
    ,
    drop = FALSE
  ]
  profile <- detail[
    detail$row_kind == "profile_boundary_detail" &
      detail$provider == provider &
      detail$endpoint_member == endpoint,
    ,
    drop = FALSE
  ]
  rule_screen <- detail[
    detail$source_role == "diagnostic_rule_screen_targets" &
      detail$provider == provider &
      detail$endpoint_member == endpoint,
    ,
    drop = FALSE
  ]
  split_cal <- detail[
    detail$source_role == "diagnostic_split_calibration_targets" &
      detail$provider == provider &
      detail$endpoint_member == endpoint,
    ,
    drop = FALSE
  ]
  finite <- bool(wald$finite_interval)
  covered <- bool(wald$covered)
  lower <- bool(wald$lower_miss)
  upper <- bool(wald$upper_miss)
  n_wald <- nrow(wald)
  n_finite <- sum(finite)
  n_covered <- sum(covered)
  n_lower <- sum(lower)
  n_upper <- sum(upper)
  coverage <- if (n_wald == 0L) NA_real_ else mean(covered)
  finite_rate <- if (n_wald == 0L) NA_real_ else mean(finite)
  mcse <- mcse_proportion(covered)
  ratio <- if (n_lower == 0L) {
    if (n_upper == 0L) 0 else Inf
  } else {
    n_upper / n_lower
  }
  failures <- character()
  if (is.na(finite_rate) || finite_rate < 0.95) failures <- c(failures, "finite_interval_rate_below_0.95")
  if (is.na(coverage) || coverage < 0.95) failures <- c(failures, "coverage_below_0.95")
  if (!is.na(coverage) && coverage > 0.985) failures <- c(failures, "coverage_above_0.985")
  if (is.na(mcse) || mcse > 0.01) failures <- c(failures, "mcse_above_0.01")
  if (is.infinite(ratio) || ratio > 2) failures <- c(failures, "upper_lower_miss_ratio_above_2")
  gate_status <- if (length(failures) == 0L) {
    "current_hybrid_target_passed_diagnostic_only"
  } else {
    "current_hybrid_target_blocked"
  }
  cell <- unique(wald$cell_id)
  if (length(cell) == 0L) {
    cell <- support_cells[grepl(provider, support_cells)]
  }
  data.frame(
    replay_summary_id = paste(
      "tranche57_mu_slope_replay",
      provider,
      gsub("[^A-Za-z0-9]+", "_", endpoint),
      sep = "_"
    ),
    summary_scope = "provider_target",
    cell_id = cell[[1L]],
    provider = provider,
    endpoint_member = endpoint,
    direct_sd_target = ifelse(endpoint == "mu:(Intercept)", "sd_mu_intercept", "sd_mu_x"),
    n_detail_rows = nrow(wald) + nrow(profile) + nrow(rule_screen) + nrow(split_cal),
    n_wald_replay_rows = nrow(wald),
    n_boundary_profile_rows = nrow(profile),
    n_rule_screen_rows = nrow(rule_screen),
    n_split_calibration_rows = nrow(split_cal),
    n_unique_replicates = length(unique(wald$replicate_index)),
    n_wald_finite = n_finite,
    finite_interval_rate = fmt4(finite_rate),
    n_current_hybrid_covered = n_covered,
    current_hybrid_coverage = fmt4(coverage),
    current_hybrid_mcse = fmt6(mcse),
    n_lower_miss = n_lower,
    n_upper_miss = n_upper,
    upper_lower_miss_ratio = ifelse(is.infinite(ratio), "Inf", fmt4(ratio)),
    replay_gate_status = gate_status,
    gate_failures = if (length(failures) == 0L) "none" else paste(failures, collapse = ";"),
    compute_decision = "no_compute_in_tranche57",
    coverage_decision = "coverage_not_authorized",
    promotion_decision = "do_not_promote",
    evidence_url = "docs/dev-log/dashboard/structured-re-gaussian-mu-slope-tranche56-symbolic-interval-rule-contract.tsv",
    artifact_dir = "docs/dev-log/simulation-artifacts/2026-07-02-gaussian-mu-slope-tranche57-retained-replay-local",
    claim_boundary = paste(
      "Tranche 57 local retained replay builder only;",
      "current-hybrid replay is diagnostic input, not an executable interval rule;",
      "no executable interval rule is selected;",
      "no retained replay result is coverage authorization;",
      "no Totoro command; no FIIA command; no Nibi/Rorqual/Trillium/DRAC command;",
      "no top-up; no support-cell status movement; no interval_status;",
      "no coverage_status; no inference_ready; no supported; no q1 sigma;",
      "no matched mu+sigma; no q2; no q4/q8; no non-Gaussian interval;",
      "no REML; no AI-REML; no bridge support; no public support.",
      sep = " "
    ),
    next_gate = "Rose/Fisher/Noether/Grace review this retained replay summary before any candidate-rule equation, host smoke, top-up, coverage, or support-cell status edit.",
    stringsAsFactors = FALSE
  )
}

providers <- c("phylo", "spatial", "animal", "relmat")
summary_rows <- do.call(
  rbind,
  lapply(providers, function(provider) {
    do.call(
      rbind,
      lapply(endpoints, function(endpoint) summarise_target(provider, endpoint))
    )
  })
)
row.names(summary_rows) <- NULL

tranche_failures <- unique(unlist(strsplit(summary_rows$gate_failures, ";", fixed = TRUE)))
tranche_failures <- tranche_failures[tranche_failures != "none"]
summary_total <- data.frame(
  replay_summary_id = "tranche57_mu_slope_replay_tranche_summary",
  summary_scope = "tranche_summary",
  cell_id = "all_four_q1_mu_one_slope_cells",
  provider = "all",
  endpoint_member = "mu:(Intercept);mu:x",
  direct_sd_target = "sd_mu_intercept;sd_mu_x",
  n_detail_rows = nrow(detail),
  n_wald_replay_rows = sum(detail$row_kind == "wald_replicate"),
  n_boundary_profile_rows = sum(detail$row_kind == "profile_boundary_detail"),
  n_rule_screen_rows = sum(detail$source_role == "diagnostic_rule_screen_targets"),
  n_split_calibration_rows = sum(detail$source_role == "diagnostic_split_calibration_targets"),
  n_unique_replicates = length(unique(detail$replicate_index[detail$row_kind == "wald_replicate"])),
  n_wald_finite = sum(bool(detail$finite_interval[detail$row_kind == "wald_replicate"])),
  finite_interval_rate = "mixed_by_target",
  n_current_hybrid_covered = sum(bool(detail$covered[detail$row_kind == "wald_replicate"])),
  current_hybrid_coverage = "mixed_by_target",
  current_hybrid_mcse = "mixed_by_target",
  n_lower_miss = sum(bool(detail$lower_miss[detail$row_kind == "wald_replicate"])),
  n_upper_miss = sum(bool(detail$upper_miss[detail$row_kind == "wald_replicate"])),
  upper_lower_miss_ratio = "mixed_by_target",
  replay_gate_status = "local_replay_built_no_rule_selected",
  gate_failures = if (length(tranche_failures) == 0L) "none" else paste(sort(tranche_failures), collapse = ";"),
  compute_decision = "no_compute_in_tranche57",
  coverage_decision = "coverage_not_authorized",
  promotion_decision = "do_not_promote",
  evidence_url = "docs/dev-log/dashboard/structured-re-gaussian-mu-slope-tranche56-symbolic-interval-rule-contract.tsv",
  artifact_dir = "docs/dev-log/simulation-artifacts/2026-07-02-gaussian-mu-slope-tranche57-retained-replay-local",
  claim_boundary = paste(
    "Tranche 57 local retained replay builder only;",
    "detail and summary artifacts were constructed from existing local sources;",
    "no executable interval rule is selected; no Totoro command; no FIIA command;",
    "no Nibi/Rorqual/Trillium/DRAC command; no top-up; no coverage result;",
    "no support-cell status movement; no interval_status; no coverage_status;",
    "no inference_ready; no supported; no q1 sigma; no matched mu+sigma;",
    "no q2; no q4/q8; no non-Gaussian interval; no REML; no AI-REML;",
    "no bridge support; no public support.",
    sep = " "
  ),
  next_gate = "Review the replay artifacts with Rose/Fisher/Noether/Grace; only then write a candidate-rule equation or runner contract, still before any host smoke or status edit.",
  stringsAsFactors = FALSE
)
summary_rows <- rbind(summary_rows, summary_total)

source_index_path <- file.path(
  output_dir,
  "structured-re-gaussian-mu-slope-tranche57-retained-replay-source-index.tsv"
)
detail_path <- file.path(
  output_dir,
  "structured-re-gaussian-mu-slope-tranche57-retained-replay-detail.tsv"
)
summary_path <- file.path(
  output_dir,
  "structured-re-gaussian-mu-slope-tranche57-retained-replay-summary.tsv"
)
run_log_path <- file.path(
  output_dir,
  "structured-re-gaussian-mu-slope-tranche57-retained-replay-run-log.tsv"
)
dashboard_summary_path <- file.path(
  dashboard_dir,
  "structured-re-gaussian-mu-slope-tranche57-retained-replay-summary.tsv"
)

source_index <- source_specs[
  ,
  c(
    "source_id",
    "source_role",
    "source_path",
    "host_label",
    "denominator_label",
    "required",
    "exists",
    "n_rows",
    "source_status"
  )
]
write_tsv(source_index, source_index_path)
write_tsv(detail, detail_path)
write_tsv(summary_rows, summary_path)
if (write_dashboard) {
  write_tsv(summary_rows, dashboard_summary_path)
}

run_log <- data.frame(
  run_id = "tranche57_mu_slope_retained_replay_builder",
  run_scope = "local_retained_artifact_replay_builder_only",
  source_count = nrow(source_index),
  detail_rows = nrow(detail),
  summary_rows = nrow(summary_rows),
  output_dir = "docs/dev-log/simulation-artifacts/2026-07-02-gaussian-mu-slope-tranche57-retained-replay-local",
  dashboard_written = as.character(write_dashboard),
  compute_decision = "no_compute_in_tranche57",
  coverage_decision = "coverage_not_authorized",
  promotion_decision = "do_not_promote",
  claim_boundary = paste(
    "Local retained-artifact replay builder only;",
    "no fit, no simulation, no executable interval rule, no host command,",
    "no coverage authorization, and no support-cell status edit.",
    sep = " "
  ),
  stringsAsFactors = FALSE
)
write_tsv(run_log, run_log_path)

message("wrote ", source_index_path)
message("wrote ", detail_path)
message("wrote ", summary_path)
if (write_dashboard) {
  message("wrote ", dashboard_summary_path)
}
