#!/usr/bin/env Rscript
# Fail-closed B1 aggregation: every immutable task and every attempted
# replicate must be present.  This produces evidence summaries, never ledger
# mutations or promotion verdicts.

script_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
script <- if (length(script_arg)) sub("^--file=", "", script_arg[[1L]]) else "tools/summarize-b1-breadth-validation.R"
source(file.path(dirname(normalizePath(script, mustWork = FALSE)), "b1-breadth-contract.R"))
b1_sum_stop <- function(...) stop(..., call. = FALSE)
b1_sum_args <- function(args) {
  if (any(!grepl("^--[A-Za-z][A-Za-z-]*=.+$", args))) b1_sum_stop("Arguments must use --name=value syntax.")
  keys <- sub("^--([^=]+)=.*$", "\\1", args); if (anyDuplicated(keys)) b1_sum_stop("Duplicate argument.")
  stats::setNames(sub("^--[^=]+=", "", args), keys)
}
b1_sum_main <- function(args = commandArgs(trailingOnly = TRUE)) {
  a <- b1_sum_args(args); allowed <- c("manifest", "input-dir", "output-dir")
  if (length(setdiff(names(a), allowed)) || any(!allowed %in% names(a))) b1_sum_stop("Require only --manifest=, --input-dir=, --output-dir=.")
  manifest <- utils::read.delim(a[["manifest"]], check.names = FALSE, stringsAsFactors = FALSE)
  b1_validate_task_manifest(manifest, if (all(manifest$information_rung == "smoke")) 1L else b1_default_replicates_per_shard)
  expected <- file.path(a[["input-dir"]], sprintf("b1-task-%06d.tsv", manifest$logical_task_id))
  present <- list.files(a[["input-dir"]], pattern = "^b1-task-[0-9]{6}\\.tsv$", full.names = TRUE)
  if (!setequal(normalizePath(expected, mustWork = FALSE), normalizePath(present, mustWork = FALSE))) b1_sum_stop("Unexpected or missing B1 task file relative to immutable manifest.")
  raw <- do.call(rbind, lapply(seq_len(nrow(manifest)), function(i) {
    x <- utils::read.delim(expected[[i]], check.names = FALSE, stringsAsFactors = FALSE)
    task <- manifest[i, , drop = FALSE]
    required <- c("logical_task_id", "cell_id", "information_rung", "replicate", "seed", "attempt_status")
    if (!all(required %in% names(x)) || nrow(x) != task$replicate_end - task$replicate_start + 1L ||
        !identical(sort(as.integer(x$replicate)), seq.int(task$replicate_start, task$replicate_end)) ||
        any(as.integer(x$logical_task_id) != task$logical_task_id)) b1_sum_stop("Invalid retained rows for logical task ", task$logical_task_id, ".")
    x
  }))
  if (anyDuplicated(raw[c("cell_id", "information_rung", "replicate")])) b1_sum_stop("Duplicated B1 replicate evidence.")
  expected_n <- if (all(manifest$information_rung == "smoke")) 1L else b1_replicates_per_rung
  by_cell <- split(raw, interaction(raw$cell_id, raw$information_rung, drop = TRUE))
  summary <- do.call(rbind, lapply(by_cell, function(x) {
    if (nrow(x) != expected_n) b1_sum_stop("Incomplete cell/rung evidence.")
    data.frame(cell_id = x$cell_id[[1L]], family = x$family[[1L]], dpar = x$dpar[[1L]], effect = x$effect[[1L]],
      target = x$target[[1L]], information_rung = x$information_rung[[1L]], n_attempted = nrow(x),
      n_fit_completed = sum(x$attempt_status == "fit_completed"), n_fit_error = sum(x$attempt_status == "fit_error"),
      convergence_zero_rate = mean(x$convergence == 0, na.rm = TRUE), pdHess_true_rate = mean(x$pdHess %in% TRUE, na.rm = TRUE),
      target_estimate_median = stats::median(x$target_estimate, na.rm = TRUE), field_correlation_median = stats::median(x$field_correlation, na.rm = TRUE),
      profile_ready_rate = mean(x$profile_ready %in% TRUE, na.rm = TRUE), stringsAsFactors = FALSE)
  }))
  dir.create(a[["output-dir"]], recursive = TRUE, showWarnings = FALSE)
  utils::write.table(raw, file.path(a[["output-dir"]], "b1-retained-raw.tsv"), sep = "\t", quote = FALSE, row.names = FALSE)
  utils::write.table(summary, file.path(a[["output-dir"]], "b1-per-cell-rung-summary.tsv"), sep = "\t", quote = FALSE, row.names = FALSE)
  print(summary)
}
if (sys.nframe() == 0L) b1_sum_main()
