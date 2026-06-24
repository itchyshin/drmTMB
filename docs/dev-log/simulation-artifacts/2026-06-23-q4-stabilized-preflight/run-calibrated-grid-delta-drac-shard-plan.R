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

n_rep <- as.integer(value_arg("n-rep", "500"))
seed_start <- as.integer(value_arg("seed-start", "202607500"))
sd_scales <- as.numeric(strsplit(value_arg("sd-scales", "0.35,0.50"), ",")[[
  1L
]])
n_shards <- as.integer(value_arg("n-shards", "9"))
worker_labels <- strsplit(
  value_arg(
    "worker-labels",
    "drac01,drac02,drac03,drac04,drac05,drac06,drac07,drac08,totoro"
  ),
  ",",
  fixed = TRUE
)[[1L]]
nominal_coverage <- as.numeric(value_arg("nominal-coverage", "0.95"))
failure_rate_reference <- as.numeric(value_arg(
  "failure-rate-reference",
  "0.05"
))

if (is.na(n_rep) || n_rep < 475L) {
  stop(
    "The DRAC shard plan requires --n-rep >= 475 to meet the MCSE gate.",
    call. = FALSE
  )
}
if (is.na(seed_start) || seed_start <= 0L) {
  stop("--seed-start must be a positive integer.", call. = FALSE)
}
if (!length(sd_scales) || any(is.na(sd_scales)) || any(sd_scales <= 0)) {
  stop(
    "--sd-scales must be a comma-separated list of positive numbers.",
    call. = FALSE
  )
}
if (is.na(n_shards) || n_shards < 1L) {
  stop("--n-shards must be a positive integer.", call. = FALSE)
}
if (length(worker_labels) != n_shards || any(!nzchar(worker_labels))) {
  stop("--worker-labels must provide exactly --n-shards labels.", call. = FALSE)
}
if (
  is.na(nominal_coverage) ||
    nominal_coverage <= 0 ||
    nominal_coverage >= 1
) {
  stop("--nominal-coverage must be in (0, 1).", call. = FALSE)
}
if (
  is.na(failure_rate_reference) ||
    failure_rate_reference <= 0 ||
    failure_rate_reference >= 1
) {
  stop("--failure-rate-reference must be in (0, 1).", call. = FALSE)
}

script_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
script_path <- if (length(script_arg)) {
  sub("^--file=", "", script_arg[[1L]])
} else {
  ""
}
artifact_dir <- if (nzchar(script_path) && file.exists(script_path)) {
  dirname(normalizePath(script_path, mustWork = TRUE))
} else {
  getwd()
}
artifact_dir <- normalizePath(artifact_dir, winslash = "/", mustWork = TRUE)
repo_root <- normalizePath(
  file.path(artifact_dir, "..", "..", "..", ".."),
  winslash = "/",
  mustWork = TRUE
)
this_script <- if (nzchar(script_path) && file.exists(script_path)) {
  normalizePath(script_path, winslash = "/", mustWork = TRUE)
} else {
  file.path(artifact_dir, "run-calibrated-grid-delta-drac-shard-plan.R")
}
runner_script <- file.path(
  artifact_dir,
  "run-calibrated-grid-delta-resumable-smoke.R"
)

rel_path <- function(path) {
  normalized <- normalizePath(path, winslash = "/", mustWork = FALSE)
  prefix <- paste0(repo_root, "/")
  if (startsWith(normalized, prefix)) {
    substring(normalized, nchar(prefix) + 1L)
  } else {
    normalized
  }
}

scale_tag <- function(x) {
  gsub("[.]", "", sprintf("%0.2f", x))
}

grid <- expand.grid(
  sd_scale = sd_scales,
  replicate_index = seq_len(n_rep),
  KEEP.OUT.ATTRS = FALSE
)
grid$seed <- seed_start + grid$replicate_index - 1L
grid$cell_index <- seq_len(nrow(grid))
grid$shard_index <- ((grid$cell_index - 1L) %% n_shards) + 1L
grid$worker_label <- worker_labels[grid$shard_index]
grid$cell_id <- paste0(
  "q4_delta_resumable_sd",
  scale_tag(grid$sd_scale),
  "_seed",
  grid$seed
)

output_root <- file.path(
  artifact_dir,
  "q4-derived-correlation-delta-grid-drac-shards"
)
aggregate_dir <- file.path(output_root, "aggregate")
aggregate_manifest <- file.path(
  aggregate_dir,
  "q4-derived-correlation-delta-grid-drac-aggregate-manifest.tsv"
)
aggregate_summary <- file.path(
  aggregate_dir,
  "q4-derived-correlation-delta-grid-drac-aggregate-summary.tsv"
)
plan_path <- file.path(
  artifact_dir,
  "q4-derived-correlation-delta-grid-drac-shard-plan.tsv"
)

coverage_mcse_at_nominal <- sqrt(
  nominal_coverage * (1 - nominal_coverage) / n_rep
)
failure_rate_mcse_at_reference <- sqrt(
  failure_rate_reference * (1 - failure_rate_reference) / n_rep
)
claim_boundary <- paste(
  "Q4 derived-correlation DRAC shard plan only; no q4 interval reliability,",
  "interval coverage, q4 REML, AI-REML, HSquared transfer, or broad bridge",
  "support is promoted."
)
denominator_policy <- paste0(
  "retain_fit_errors_nonconvergence_pdHess_false_warnings_unavailable_",
  "intervals_boundary_clamped_and_finite_rows"
)

rows <- lapply(seq_len(n_shards), function(i) {
  shard <- grid[grid$shard_index == i, , drop = FALSE]
  shard_tag <- sprintf("shard_%02d", i)
  shard_root <- file.path(output_root, shard_tag)
  shard_manifest <- file.path(
    shard_root,
    paste0("q4-derived-correlation-delta-grid-", shard_tag, "-manifest.tsv")
  )
  shard_run_log <- file.path(
    shard_root,
    paste0("q4-derived-correlation-delta-grid-", shard_tag, "-run-log.tsv")
  )
  shard_cells <- file.path(shard_root, "cells")
  command <- paste(
    "Rscript --vanilla",
    shQuote(rel_path(runner_script)),
    paste0("--n-rep=", n_rep),
    paste0("--seed-start=", seed_start),
    paste0("--sd-scales=", paste(sd_scales, collapse = ",")),
    paste0("--cell-limit=", nrow(grid)),
    paste0("--n-shards=", n_shards),
    paste0("--shard-index=", i),
    paste0("--run-label=r57_", shard_tag),
    paste0("--output-root=", shQuote(rel_path(shard_cells))),
    paste0("--manifest-dir=", shQuote(rel_path(shard_root))),
    paste0(
      "--manifest-file=q4-derived-correlation-delta-grid-",
      shard_tag,
      "-manifest.tsv"
    ),
    paste0("--run-log-dir=", shQuote(rel_path(shard_root))),
    paste0(
      "--run-log-file=q4-derived-correlation-delta-grid-",
      shard_tag,
      "-run-log.tsv"
    ),
    "--force=false",
    "--allow-large=true"
  )
  data.frame(
    shard_id = paste0("q4_delta_drac_", shard_tag),
    slice_id = "SR150",
    target = "gaussian_q4_phylo",
    worker_label = worker_labels[[i]],
    worker_role = if (grepl("^drac", worker_labels[[i]])) {
      "drac_cpu_worker"
    } else {
      "totoro_cpu_worker"
    },
    n_shards = n_shards,
    shard_index = i,
    planned_n_rep = n_rep,
    seed_start = min(shard$seed),
    seed_end = max(shard$seed),
    scale_levels = paste(sd_scales, collapse = ";"),
    planned_total_cells = nrow(grid),
    planned_total_target_rows = nrow(grid) * 6L,
    planned_shard_cells = nrow(shard),
    planned_shard_target_rows = nrow(shard) * 6L,
    cell_index_min = min(shard$cell_index),
    cell_index_max = max(shard$cell_index),
    shard_output_root = rel_path(shard_cells),
    shard_manifest = rel_path(shard_manifest),
    shard_run_log = rel_path(shard_run_log),
    aggregate_manifest = rel_path(aggregate_manifest),
    aggregate_summary = rel_path(aggregate_summary),
    runner_command = command,
    resume_command = sub(
      "--force=false",
      "--force=false",
      command,
      fixed = TRUE
    ),
    write_isolation = "private_shard_root_no_shared_append",
    assignment_policy = "round_robin_by_seed_scale_cell_index",
    aggregate_gate = paste(
      "aggregate only after every shard manifest exists; require unique",
      "cell_id values,",
      nrow(grid),
      "seed-scale cells,",
      nrow(grid) * 6L,
      "target rows, and MCSE fields before SR150 can move"
    ),
    denominator_policy = denominator_policy,
    coverage_mcse_at_nominal = sprintf("%.6f", coverage_mcse_at_nominal),
    failure_rate_mcse_at_reference = sprintf(
      "%.6f",
      failure_rate_mcse_at_reference
    ),
    mcse_status = "planned_mcse_gate_not_run",
    status = "planned_not_run",
    claim_boundary = claim_boundary,
    next_gate = paste(
      "Run a two-shard rehearsal, aggregate private shard outputs, then dispatch",
      "the full 9-shard calibrated grid only if the aggregate validator passes."
    ),
    stringsAsFactors = FALSE
  )
})

plan <- do.call(rbind, rows)
utils::write.table(
  plan,
  file = plan_path,
  sep = "\t",
  row.names = FALSE,
  quote = FALSE,
  na = ""
)
message("Wrote ", plan_path)
