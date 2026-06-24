#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
value_arg <- function(name, default) {
  prefix <- paste0("--", name, "=")
  hit <- grep(paste0("^", prefix), args, value = TRUE)
  if (!length(hit)) {
    return(default)
  }
  sub(prefix, "", hit[[1L]], fixed = TRUE)
}

bool_arg <- function(name, default = FALSE) {
  value <- tolower(value_arg(name, if (default) "true" else "false"))
  if (!value %in% c("true", "false")) {
    stop("--", name, " must be true or false.", call. = FALSE)
  }
  value == "true"
}

n_shards <- as.integer(value_arg("n-shards", "2"))
expected_cells <- as.integer(value_arg("expected-cells", "4"))
expected_target_rows <- as.integer(value_arg("expected-target-rows", "24"))
require_resume <- bool_arg("require-resume", TRUE)
aggregate_label <- value_arg("aggregate-label", "two_shard_rehearsal")
compute_rate_mcse <- bool_arg("compute-rate-mcse", FALSE)
mcse_status <- if (compute_rate_mcse) {
  paste0(
    "diagnostic_rate_mcse_computed_coverage_not_evaluable_",
    aggregate_label
  )
} else {
  paste0("insufficient_replicates_", aggregate_label)
}
mcse_placeholder <- paste0("not_computed_", aggregate_label)
coverage_mcse <- if (compute_rate_mcse) {
  paste0("not_evaluable_", aggregate_label)
} else {
  mcse_placeholder
}
claim_label <- gsub("_", "-", aggregate_label, fixed = TRUE)

if (is.na(n_shards) || n_shards < 1L) {
  stop("--n-shards must be a positive integer.", call. = FALSE)
}
if (is.na(expected_cells) || expected_cells < 1L) {
  stop("--expected-cells must be a positive integer.", call. = FALSE)
}
if (is.na(expected_target_rows) || expected_target_rows < 1L) {
  stop("--expected-target-rows must be a positive integer.", call. = FALSE)
}

script_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
script_path <- if (length(script_arg)) {
  sub("^--file=", "", script_arg[[1L]])
} else {
  ""
}
script_path <- sub("^['\"]", "", sub("['\"]$", "", script_path))
artifact_dir <- if (nzchar(script_path) && file.exists(script_path)) {
  dirname(normalizePath(script_path, mustWork = TRUE))
} else {
  getwd()
}
artifact_dir <- normalizePath(artifact_dir, winslash = "/", mustWork = TRUE)
repo_root_arg <- value_arg("repo-root", "")
repo_root <- if (nzchar(repo_root_arg)) {
  normalizePath(repo_root_arg, winslash = "/", mustWork = TRUE)
} else {
  normalizePath(
    file.path(artifact_dir, "..", "..", "..", ".."),
    winslash = "/",
    mustWork = TRUE
  )
}

rel_path <- function(path) {
  normalized <- normalizePath(path, winslash = "/", mustWork = FALSE)
  prefix <- paste0(repo_root, "/")
  ifelse(
    startsWith(normalized, prefix),
    substring(normalized, nchar(prefix) + 1L),
    normalized
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

read_cell_output <- function(path) {
  rows <- read_tsv(path)
  rows$cell_output_path <- rel_path(path)
  rows
}

binomial_mcse <- function(events, trials) {
  rate <- events / trials
  ifelse(trials > 0L, sqrt(rate * (1 - rate) / trials), NA_real_)
}

mean_mcse <- function(x) {
  if (length(x) < 2L) {
    return(NA_real_)
  }
  stats::sd(x) / sqrt(length(x))
}

shard_root <- normalizePath(
  value_arg(
    "shard-root",
    file.path(
      artifact_dir,
      "q4-derived-correlation-delta-grid-two-shard-rehearsal"
    )
  ),
  winslash = "/",
  mustWork = TRUE
)
aggregate_dir <- file.path(shard_root, "aggregate")
dir.create(aggregate_dir, recursive = TRUE, showWarnings = FALSE)

manifest_paths <- file.path(
  shard_root,
  sprintf("shard_%02d", seq_len(n_shards)),
  sprintf(
    "q4-derived-correlation-delta-grid-shard_%02d-manifest.tsv",
    seq_len(n_shards)
  )
)
run_log_paths <- file.path(
  shard_root,
  sprintf("shard_%02d", seq_len(n_shards)),
  sprintf(
    "q4-derived-correlation-delta-grid-shard_%02d-run-log.tsv",
    seq_len(n_shards)
  )
)
missing_manifests <- manifest_paths[!file.exists(manifest_paths)]
missing_run_logs <- run_log_paths[!file.exists(run_log_paths)]
if (length(missing_manifests)) {
  stop(
    "Missing shard manifests: ",
    paste(rel_path(missing_manifests), collapse = ", "),
    call. = FALSE
  )
}
if (length(missing_run_logs)) {
  stop(
    "Missing shard run logs: ",
    paste(rel_path(missing_run_logs), collapse = ", "),
    call. = FALSE
  )
}

manifests <- do.call(rbind, lapply(manifest_paths, read_tsv))
run_logs <- do.call(rbind, lapply(run_log_paths, read_tsv))
cell_output_entries <- unlist(strsplit(
  manifests$cell_outputs,
  ";",
  fixed = TRUE
))
cell_output_entries <- cell_output_entries[nzchar(cell_output_entries)]
duplicated_cell_outputs <- sort(unique(
  cell_output_entries[duplicated(cell_output_entries)]
))
cell_outputs <- unique(cell_output_entries)
missing_cell_outputs <- file.path(repo_root, cell_outputs)[
  !file.exists(file.path(repo_root, cell_outputs))
]
if (length(missing_cell_outputs)) {
  stop(
    "Missing cell output files: ",
    paste(rel_path(missing_cell_outputs), collapse = ", "),
    call. = FALSE
  )
}
cell_rows <- do.call(
  rbind,
  lapply(file.path(repo_root, cell_outputs), read_cell_output)
)

unique_cells <- length(unique(run_logs$cell_id))
computed_cell_ids <- run_logs$cell_id[run_logs$action == "computed"]
duplicated_computed_cells <- sort(unique(
  computed_cell_ids[duplicated(computed_cell_ids)]
))
computed_actions <- sum(run_logs$action == "computed")
skipped_actions <- sum(run_logs$action == "skipped_existing")
finite_delta_rows <- sum(cell_rows$interval_status == "finite_delta_diagnostic")
warning_rows <- sum(cell_rows$warning_context != "none")
failure_rows <- sum(
  cell_rows$fit_status != "fit_ok" |
    cell_rows$interval_status != "finite_delta_diagnostic" |
    cell_rows$pdHess != TRUE
)
boundary_clamped_rows <- sum(cell_rows$boundary_clamped == TRUE)
coverage_evaluable_rows <- sum(
  !startsWith(cell_rows$coverage_indicator, "not_")
)
failure_flag <- (cell_rows$fit_status != "fit_ok" |
  cell_rows$interval_status != "finite_delta_diagnostic" |
  cell_rows$pdHess != TRUE)
manifest_failure_rate_mcse <- mcse_placeholder
if (compute_rate_mcse) {
  cell_rows$failure_flag_for_mcse <- failure_flag
  cell_failure_fractions <- stats::aggregate(
    failure_flag_for_mcse ~ cell_output_path,
    data = cell_rows,
    FUN = mean
  )
  manifest_failure_rate_mcse <- mean_mcse(
    cell_failure_fractions$failure_flag_for_mcse
  )
}

aggregate_status <- "aggregate_verified"
if (unique_cells != expected_cells || nrow(cell_rows) != expected_target_rows) {
  aggregate_status <- "aggregate_count_mismatch"
}
if (length(duplicated_computed_cells) || length(duplicated_cell_outputs)) {
  aggregate_status <- "aggregate_duplicate_cell_ids"
}
if (
  aggregate_status == "aggregate_verified" &&
    require_resume &&
    skipped_actions < expected_cells
) {
  aggregate_status <- "aggregate_resume_not_verified"
}

claim_boundary <- paste(
  "Q4 derived-correlation",
  claim_label,
  "aggregate rehearsal only; no q4 interval",
  "reliability, interval coverage, q4 REML, AI-REML, HSquared transfer, or",
  "broad bridge support is promoted."
)
denominator_policy <- paste0(
  "retain_fit_errors_nonconvergence_pdHess_false_warnings_unavailable_",
  "intervals_boundary_clamped_and_finite_rows"
)

manifest <- data.frame(
  aggregate_id = paste0("q4_delta_grid_", aggregate_label, "_aggregate"),
  slice_id = "SR150",
  target = "gaussian_q4_phylo",
  n_shards = n_shards,
  shard_manifests = paste(rel_path(manifest_paths), collapse = ";"),
  shard_run_logs = paste(rel_path(run_log_paths), collapse = ";"),
  unique_cells = unique_cells,
  computed_actions = computed_actions,
  skipped_actions = skipped_actions,
  expected_cells = expected_cells,
  expected_target_rows = expected_target_rows,
  observed_target_rows = nrow(cell_rows),
  finite_delta_rows = finite_delta_rows,
  retained_denominator_rows = nrow(cell_rows),
  warning_rows = warning_rows,
  failure_rows = failure_rows,
  boundary_clamped_rows = boundary_clamped_rows,
  coverage_evaluable_rows = coverage_evaluable_rows,
  coverage_mcse = coverage_mcse,
  failure_rate_mcse = manifest_failure_rate_mcse,
  mcse_status = mcse_status,
  denominator_policy = denominator_policy,
  aggregate_status = aggregate_status,
  claim_boundary = claim_boundary,
  next_gate = paste(
    "Use this aggregate contract for larger shards only after every shard",
    "writes private outputs and the aggregate sees unique cells plus retained",
    "denominator rows."
  ),
  stringsAsFactors = FALSE
)

cell_rows$observed_rows <- 1L
cell_rows$finite_delta_flag <- cell_rows$interval_status ==
  "finite_delta_diagnostic"
cell_rows$warning_flag <- cell_rows$warning_context != "none"
cell_rows$failure_flag <- failure_flag
cell_rows$boundary_clamped_flag <- cell_rows$boundary_clamped == TRUE
cell_rows$coverage_evaluable_flag <- !startsWith(
  cell_rows$coverage_indicator,
  "not_"
)
summary <- stats::aggregate(
  cbind(
    observed_rows,
    finite_delta_rows = finite_delta_flag,
    warning_rows = warning_flag,
    failure_rows = failure_flag,
    boundary_clamped_rows = boundary_clamped_flag,
    coverage_evaluable_rows = coverage_evaluable_flag
  ) ~ target_name,
  data = cell_rows,
  FUN = sum
)
summary$retained_denominator_rows <- summary$observed_rows
summary$coverage_rate <- ifelse(
  summary$coverage_evaluable_rows > 0L,
  as.character(
    summary$coverage_evaluable_rows / summary$retained_denominator_rows
  ),
  paste0("not_evaluable_", aggregate_label)
)
summary$failure_rate <- summary$failure_rows / summary$retained_denominator_rows
summary$warning_rate <- summary$warning_rows / summary$retained_denominator_rows
summary$boundary_clamp_rate <- (summary$boundary_clamped_rows /
  summary$retained_denominator_rows)
summary$coverage_mcse <- coverage_mcse
if (compute_rate_mcse) {
  summary$failure_rate_mcse <- binomial_mcse(
    summary$failure_rows,
    summary$retained_denominator_rows
  )
  summary$warning_rate_mcse <- binomial_mcse(
    summary$warning_rows,
    summary$retained_denominator_rows
  )
  summary$boundary_clamp_rate_mcse <- binomial_mcse(
    summary$boundary_clamped_rows,
    summary$retained_denominator_rows
  )
} else {
  summary$failure_rate_mcse <- mcse_placeholder
  summary$warning_rate_mcse <- mcse_placeholder
  summary$boundary_clamp_rate_mcse <- mcse_placeholder
}
summary$aggregate_label <- aggregate_label
summary$mcse_status <- mcse_status
summary$claim_boundary <- claim_boundary

manifest_path <- file.path(
  aggregate_dir,
  paste0(
    "q4-derived-correlation-delta-grid-",
    aggregate_label,
    "-aggregate-manifest.tsv"
  )
)
summary_path <- file.path(
  aggregate_dir,
  paste0(
    "q4-derived-correlation-delta-grid-",
    aggregate_label,
    "-aggregate-summary.tsv"
  )
)
utils::write.table(
  manifest,
  file = manifest_path,
  sep = "\t",
  row.names = FALSE,
  quote = FALSE,
  na = ""
)
utils::write.table(
  summary,
  file = summary_path,
  sep = "\t",
  row.names = FALSE,
  quote = FALSE,
  na = ""
)
message("Wrote ", manifest_path)
message("Wrote ", summary_path)
if (aggregate_status != "aggregate_verified") {
  stop("Aggregate status is ", aggregate_status, call. = FALSE)
}
