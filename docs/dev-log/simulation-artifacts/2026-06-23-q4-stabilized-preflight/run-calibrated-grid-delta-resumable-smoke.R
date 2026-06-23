#!/usr/bin/env Rscript

suppressPackageStartupMessages(devtools::load_all(quiet = TRUE))

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

n_rep <- as.integer(value_arg("n-rep", "1"))
seed_start <- as.integer(value_arg("seed-start", "202607500"))
sd_scales <- as.numeric(strsplit(value_arg("sd-scales", "0.35"), ",")[[
  1L
]])
cell_limit <- as.integer(value_arg("cell-limit", "1"))
shard_index <- as.integer(value_arg("shard-index", "1"))
n_shards <- as.integer(value_arg("n-shards", "1"))
force <- bool_arg("force", FALSE)
reset_log <- bool_arg("reset-log", FALSE)
reset_output <- bool_arg("reset-output", FALSE)
allow_large <- bool_arg("allow-large", FALSE)
run_label <- value_arg("run-label", "resumable_smoke")

if (is.na(n_rep) || n_rep < 1L) {
  stop("--n-rep must be a positive integer.", call. = FALSE)
}
if (n_rep > 2L && !allow_large) {
  stop(
    "This r54 local runner blocks n-rep > 2 unless --allow-large=true.",
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
if (is.na(cell_limit) || cell_limit < 1L) {
  stop("--cell-limit must be a positive integer.", call. = FALSE)
}
if (is.na(n_shards) || n_shards < 1L) {
  stop("--n-shards must be a positive integer.", call. = FALSE)
}
if (is.na(shard_index) || shard_index < 1L || shard_index > n_shards) {
  stop("--shard-index must be between 1 and --n-shards.", call. = FALSE)
}

script_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
script_path <- if (length(script_arg)) {
  sub("^--file=", "", script_arg[[1L]])
} else {
  ""
}
artifact_dir <- if (length(script_arg)) {
  if (file.exists(script_path)) {
    dirname(normalizePath(script_path, mustWork = TRUE))
  } else {
    getwd()
  }
} else {
  getwd()
}
this_script <- if (nzchar(script_path) && file.exists(script_path)) {
  normalizePath(script_path, winslash = "/", mustWork = TRUE)
} else {
  file.path(artifact_dir, "run-calibrated-grid-delta-resumable-smoke.R")
}
repo_root <- normalizePath(
  file.path(artifact_dir, "..", "..", "..", ".."),
  winslash = "/",
  mustWork = TRUE
)
artifact_dir <- normalizePath(artifact_dir, winslash = "/", mustWork = TRUE)

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

smoke_script <- file.path(artifact_dir, "run-calibrated-grid-delta-smoke.R")
if (!file.exists(smoke_script)) {
  stop("Missing delegated smoke script: ", smoke_script, call. = FALSE)
}

output_root <- value_arg(
  "output-root",
  file.path(artifact_dir, "q4-derived-correlation-delta-grid-resumable-smoke")
)
manifest_path <- file.path(
  value_arg(
    "manifest-dir",
    artifact_dir
  ),
  value_arg(
    "manifest-file",
    "q4-derived-correlation-delta-grid-resumable-smoke-manifest.tsv"
  )
)
run_log_path <- file.path(
  value_arg(
    "run-log-dir",
    artifact_dir
  ),
  value_arg(
    "run-log-file",
    "q4-derived-correlation-delta-grid-resumable-smoke-run-log.tsv"
  )
)

if (reset_output && dir.exists(output_root)) {
  unlink(output_root, recursive = TRUE, force = TRUE)
}
if (reset_log && file.exists(run_log_path)) {
  unlink(run_log_path)
}
dir.create(output_root, recursive = TRUE, showWarnings = FALSE)
dir.create(dirname(manifest_path), recursive = TRUE, showWarnings = FALSE)
dir.create(dirname(run_log_path), recursive = TRUE, showWarnings = FALSE)

claim_boundary <- paste(
  "Q4 derived-correlation delta-grid resumability smoke only; no q4 interval",
  "reliability, interval coverage, q4 REML, AI-REML, or broad bridge support",
  "is promoted."
)
denominator_policy <- paste0(
  "retain_fit_errors_nonconvergence_pdHess_false_warnings_unavailable_",
  "intervals_boundary_clamped_and_finite_rows"
)

grid <- expand.grid(
  sd_scale = sd_scales,
  replicate_index = seq_len(n_rep),
  KEEP.OUT.ATTRS = FALSE
)
grid$seed <- seed_start + grid$replicate_index - 1L
grid$cell_index <- seq_len(nrow(grid))
grid <- grid[seq_len(min(cell_limit, nrow(grid))), , drop = FALSE]
grid <- grid[
  ((grid$cell_index - 1L) %% n_shards) + 1L == shard_index,
  ,
  drop = FALSE
]
if (!nrow(grid)) {
  stop("Shard has no seed-scale cells under the requested grid.", call. = FALSE)
}
grid$cell_id <- paste0(
  "q4_delta_resumable_sd",
  scale_tag(grid$sd_scale),
  "_seed",
  grid$seed
)

read_cell <- function(path) {
  utils::read.delim(
    path,
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
}

run_cell <- function(row) {
  cell_id <- row[["cell_id"]]
  cell_dir <- file.path(output_root, cell_id)
  cell_file <- paste0(cell_id, ".tsv")
  cell_path <- file.path(cell_dir, cell_file)
  dir.create(cell_dir, recursive = TRUE, showWarnings = FALSE)
  previous_output_detected <- file.exists(cell_path)

  action <- "skipped_existing"
  child_status <- 0L
  if (force || !previous_output_detected) {
    action <- "computed"
    child_args <- c(
      "--vanilla",
      shQuote(smoke_script),
      "--n-rep=1",
      paste0("--seed-start=", row[["seed"]]),
      paste0("--sd-scale=", row[["sd_scale"]]),
      shQuote(paste0("--output-dir=", cell_dir)),
      paste0("--output-file=", cell_file)
    )
    child_output <- system2(
      file.path(R.home("bin"), "Rscript"),
      child_args,
      stdout = TRUE,
      stderr = TRUE
    )
    child_status <- attr(child_output, "status")
    if (is.null(child_status)) {
      child_status <- 0L
    }
    if (!identical(child_status, 0L)) {
      stop(
        "Delegated smoke failed for ",
        cell_id,
        ": ",
        paste(child_output, collapse = " | "),
        call. = FALSE
      )
    }
  }

  rows <- read_cell(cell_path)
  finite_delta <- rows$interval_status == "finite_delta_diagnostic"
  failure_rows <- rows$fit_status != "fit_ok" |
    rows$interval_status != "finite_delta_diagnostic" |
    rows$pdHess != TRUE
  warning_rows <- rows$warning_context != "none"
  boundary_clamped <- rows$boundary_clamped == TRUE
  coverage_evaluable <- !startsWith(rows$coverage_indicator, "not_")

  data.frame(
    run_label = run_label,
    cell_id = cell_id,
    slice_id = "SR150",
    target = "gaussian_q4_phylo",
    seed = row[["seed"]],
    sd_scale = row[["sd_scale"]],
    cell_index = row[["cell_index"]],
    cell_output = rel_path(cell_path),
    action = action,
    previous_output_detected = previous_output_detected,
    child_status = child_status,
    observed_target_rows = nrow(rows),
    finite_delta_rows = sum(finite_delta),
    retained_denominator_rows = nrow(rows),
    warning_rows = sum(warning_rows),
    failure_rows = sum(failure_rows),
    boundary_clamped_rows = sum(boundary_clamped),
    coverage_evaluable_rows = sum(coverage_evaluable),
    coverage_mcse = "not_computed_resumability_smoke",
    failure_rate_mcse = "not_computed_resumability_smoke",
    mcse_status = "insufficient_replicates_resumability_smoke",
    resumability_status = if (action == "skipped_existing") {
      "skipped_existing_output"
    } else {
      "computed_cell_output"
    },
    denominator_policy = denominator_policy,
    claim_boundary = claim_boundary,
    next_gate = paste(
      "Run the full r53 ADEMP grid with the same per-cell output contract and",
      "summarise coverage, failure, warning, and boundary-clamp rates with MCSE."
    ),
    stringsAsFactors = FALSE
  )
}

new_log <- do.call(
  rbind,
  lapply(seq_len(nrow(grid)), function(i) run_cell(grid[i, , drop = FALSE]))
)
run_log <- if (file.exists(run_log_path)) {
  rbind(read_cell(run_log_path), new_log)
} else {
  new_log
}
utils::write.table(
  run_log,
  file = run_log_path,
  sep = "\t",
  row.names = FALSE,
  quote = FALSE,
  na = ""
)

cell_outputs <- unique(new_log$cell_output)
cell_rows <- do.call(
  rbind,
  lapply(file.path(repo_root, cell_outputs), read_cell)
)
computed_actions <- sum(run_log$action == "computed")
skipped_actions <- sum(run_log$action == "skipped_existing")
resumability_status <- if (computed_actions >= 1L && skipped_actions >= 1L) {
  "resume_skip_verified"
} else {
  "pending_second_invocation"
}

manifest <- data.frame(
  manifest_id = "q4_derived_delta_grid_resumable_smoke_manifest",
  slice_id = "SR150",
  target = "gaussian_q4_phylo",
  source_script = rel_path(this_script),
  delegated_smoke_script = rel_path(smoke_script),
  contract_source = "q4-derived-correlation-delta-grid-ademp-dry-run.tsv",
  output_root = rel_path(output_root),
  manifest_artifact = rel_path(manifest_path),
  run_log_artifact = rel_path(run_log_path),
  cell_outputs = paste(cell_outputs, collapse = ";"),
  planned_n_rep = n_rep,
  scale_levels = paste(sd_scales, collapse = ";"),
  cell_limit = nrow(grid),
  observed_cells = length(cell_outputs),
  computed_actions = computed_actions,
  skipped_actions = skipped_actions,
  observed_target_rows = nrow(cell_rows),
  finite_delta_rows = sum(
    cell_rows$interval_status == "finite_delta_diagnostic"
  ),
  retained_denominator_rows = nrow(cell_rows),
  warning_rows = sum(cell_rows$warning_context != "none"),
  failure_rows = sum(
    cell_rows$fit_status != "fit_ok" |
      cell_rows$interval_status != "finite_delta_diagnostic" |
      cell_rows$pdHess != TRUE
  ),
  boundary_clamped_rows = sum(cell_rows$boundary_clamped == TRUE),
  coverage_evaluable_rows = sum(
    !startsWith(cell_rows$coverage_indicator, "not_")
  ),
  coverage_mcse = "not_computed_resumability_smoke",
  failure_rate_mcse = "not_computed_resumability_smoke",
  mcse_status = "insufficient_replicates_resumability_smoke",
  resumability_status = resumability_status,
  denominator_policy = denominator_policy,
  status = "resumability_smoke_verified",
  claim_boundary = claim_boundary,
  next_gate = paste(
    "Run the full r53 ADEMP grid with this resumable cell contract before",
    "moving SR150 or making coverage wording."
  ),
  stringsAsFactors = FALSE
)

utils::write.table(
  manifest,
  file = manifest_path,
  sep = "\t",
  row.names = FALSE,
  quote = FALSE,
  na = ""
)
message("Wrote ", manifest_path)
message("Wrote ", run_log_path)
