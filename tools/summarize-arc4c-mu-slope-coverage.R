#!/usr/bin/env Rscript
# Fail-closed aggregator for Arc 4c retained shard rows.
script_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
script <- if (length(script_arg)) sub("^--file=", "", script_arg[[1L]]) else "tools/summarize-arc4c-mu-slope-coverage.R"
source(file.path(dirname(normalizePath(script, mustWork = FALSE)), "arc4c-mu-slope-coverage-contract.R"))
args <- commandArgs(trailingOnly = TRUE)
value <- function(name, default = NULL) { x <- grep(paste0("^--", name, "="), args, value = TRUE); if (!length(x)) default else sub(paste0("^--", name, "="), "", x[[length(x)]]) }
if (any(!grepl("^--[A-Za-z][A-Za-z-]*=.+$", args))) arc4c_stop("Summarizer arguments must be named --key=value arguments.")
keys <- sub("^--([^=]+)=.*$", "\\1", args[grepl("^--", args)])
if (any(!keys %in% c("mode", "input-dir", "output-dir", "manifest")) || anyDuplicated(keys)) arc4c_stop("Unknown or duplicate summarizer argument.")
mode <- value("mode", "full")
if (!mode %in% c("smoke", "full")) arc4c_stop("--mode must be smoke or full.")
input <- value("input-dir", NULL); output <- value("output-dir", NULL); manifest_path <- value("manifest", NULL)
if (is.null(input) || is.null(output) || is.null(manifest_path) ||
    !nzchar(input) || !nzchar(output) || !nzchar(manifest_path)) {
  arc4c_stop("Nonempty --input-dir, --output-dir, and --manifest are required.")
}
manifest <- arc4c_read_tsv(manifest_path)
required_manifest <- c("array_index", "logical_task_id", "cell_id", "family", "M", "shard", "replicate_start", "replicate_end")
if (!all(required_manifest %in% names(manifest))) arc4c_stop("Manifest schema mismatch.")
manifest <- manifest[, required_manifest, drop = FALSE]
logical_column <- "logical_task_id"
if (!nrow(manifest) || anyDuplicated(manifest[[logical_column]]) || anyDuplicated(manifest$array_index) || !identical(sort(as.integer(manifest$array_index)), seq_len(nrow(manifest)))) {
  arc4c_stop("Manifest task identifiers must be present and unique.")
}
if (identical(mode, "smoke")) {
  smoke_tasks <- Map(function(i) arc4c_task_from_range(manifest$cell_id[[i]], manifest$family[[i]], manifest$M[[i]],
    manifest$replicate_start[[i]], manifest$replicate_end[[i]], "smoke"), seq_len(nrow(manifest)))
  smoke_key <- vapply(smoke_tasks, function(x) paste(x$cell_id[[1L]], x$M[[1L]], sep = "/"), character(1L))
  expected_key <- as.vector(outer(arc4c_cells$cell_id, arc4c_M, paste, sep = "/"))
  if (!identical(sort(smoke_key), sort(expected_key))) arc4c_stop("Smoke manifest must contain exactly the 12 frozen family/M tasks.")
  ordered <- order(match(manifest$cell_id, arc4c_cells$cell_id), match(manifest$M, arc4c_M))
  if (!identical(as.integer(manifest$logical_task_id[ordered]), seq_len(12L)) || any(as.integer(manifest$shard) != 0L)) arc4c_stop("Smoke logical_task_id/shard mapping mismatch.")
  paths <- vapply(smoke_tasks, function(x) file.path(input, sprintf("arc4c-%s-M%02d-shard000.tsv", x$cell_id[[1L]], x$M[[1L]])), character(1L))
  present <- list.files(input, pattern = "^arc4c-.*-shard000\\.tsv$", full.names = TRUE)
  if (!setequal(normalizePath(present, mustWork = FALSE), normalizePath(paths, mustWork = FALSE))) arc4c_stop("Unexpected or missing smoke shard relative to immutable manifest.")
  raw <- do.call(rbind, Map(arc4c_validate_shard_file, paths, smoke_tasks))
  summary <- do.call(rbind, lapply(split(raw, interaction(raw$cell_id, raw$M, drop = TRUE)), arc4c_summarize_cell))
  summary$smoke_pass <- summary$n_attempted == 1L & summary$n_eligible == 1L & summary$n_profile_in_range == 1L
  selection <- arc4c_smoke_selection(summary)
  arc4c_atomic_write_tsv(raw, file.path(output, "arc4c-smoke-raw.tsv"))
  arc4c_atomic_write_tsv(summary, file.path(output, "arc4c-smoke-summary.tsv"))
  arc4c_atomic_write_tsv(selection, file.path(output, "arc4c-smoke-selection.tsv"))
  print(selection); quit(status = 0L)
}
tasks <- Map(function(i) arc4c_task_from_range(manifest$cell_id[[i]], manifest$family[[i]],
  manifest$M[[i]], manifest$replicate_start[[i]], manifest$replicate_end[[i]], "full", manifest$shard[[i]]), seq_len(nrow(manifest)))
manifest_key <- function(x) paste(x$cell_id, x$M, x$shard, sep = "/")
if (anyDuplicated(vapply(tasks, function(x) manifest_key(x[1, ]), character(1L)))) arc4c_stop("Manifest has duplicate cell/M/shard tasks.")
all_tasks <- do.call(rbind, tasks)
selected_M <- split(unique(manifest[c("cell_id", "M")])$M, unique(manifest[c("cell_id", "M")])$cell_id)
valid_M_set <- function(x) {
  x <- sort(as.integer(x))
  identical(x, c(16L, 32L, 64L)) || identical(x, c(8L, 16L, 32L, 64L))
}
if (!all(vapply(selected_M, valid_M_set, logical(1L)))) {
  arc4c_stop("Every selected family must contain M=16,32,64 and may additionally contain exploratory M=8.")
}
expected_logical <- ((match(manifest$cell_id, arc4c_cells$cell_id) - 1L) * length(arc4c_M) + match(as.integer(manifest$M), arc4c_M) - 1L) * 120L + as.integer(manifest$shard)
if (anyNA(expected_logical) || !identical(as.integer(manifest$logical_task_id), as.integer(expected_logical))) arc4c_stop("Full logical_task_id mapping mismatch.")
for (x in split(all_tasks, interaction(all_tasks$cell_id, all_tasks$M, drop = TRUE))) {
  if (!identical(sort(as.integer(x$replicate)), seq_len(arc4c_full_replicates))) arc4c_stop("Manifest does not provide r=1:1200 exactly for every selected cell.")
}
paths <- vapply(tasks, function(x) file.path(input, sprintf("arc4c-%s-M%02d-shard%03d.tsv", x$cell_id[[1L]], x$M[[1L]], x$shard[[1L]])), character(1L))
present <- list.files(input, pattern = "^arc4c-.*-shard[0-9]{3}\\.tsv$", full.names = TRUE)
if (!setequal(normalizePath(present, mustWork = FALSE), normalizePath(paths, mustWork = FALSE))) arc4c_stop("Unexpected or missing shard TSV relative to immutable manifest.")
raw <- arc4c_aggregate_shards(paths, tasks)
arc4c_validate_complete_full_cells(raw)
summary <- do.call(rbind, lapply(split(raw, interaction(raw$cell_id, raw$M, drop = TRUE)), arc4c_summarize_cell))
summary$calibration_label <- vapply(seq_len(nrow(summary)), function(i) arc4c_calibration(summary[i, , drop = FALSE]), character(1L))
verdict <- do.call(rbind, lapply(split(summary, summary$cell_id), function(x) {
  v <- arc4c_family_verdict(x)
  data.frame(cell_id = x$cell_id[[1L]], family = x$family[[1L]], promote = v$promote,
    deployment_floor = v$floor, verdict_reason = v$reason, stringsAsFactors = FALSE)
}))
arc4c_atomic_write_tsv(raw, file.path(output, "arc4c-raw.tsv"))
arc4c_atomic_write_tsv(summary, file.path(output, "arc4c-summary.tsv"))
arc4c_atomic_write_tsv(verdict, file.path(output, "arc4c-family-verdict.tsv"))
print(summary)
