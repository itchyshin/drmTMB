#!/usr/bin/env Rscript
# Post-hoc fail-closed B1 evidence gate.  It binds retained rows to the
# canonical source manifest and records the one permitted replay substitution.

b1_ev_stop <- function(...) stop(..., call. = FALSE)
b1_ev_args <- function(args) {
  if (any(!grepl("^--[A-Za-z][A-Za-z-]*=.+$", args))) b1_ev_stop("Arguments must use --name=value syntax.")
  keys <- sub("^--([^=]+)=.*$", "\\1", args)
  if (anyDuplicated(keys)) b1_ev_stop("Duplicate argument.")
  stats::setNames(sub("^--[^=]+=", "", args), keys)
}
b1_ev_need <- function(x, key) if (!key %in% names(x) || !nzchar(x[[key]])) b1_ev_stop("Missing --", key, "=.") else x[[key]]
b1_ev_sha256 <- function(path) {
  out <- suppressWarnings(system2("sha256sum", path, stdout = TRUE, stderr = TRUE))
  if (!length(out) || !grepl("^[0-9a-f]{64}\\s", out[[1L]])) b1_ev_stop("Cannot sha256sum: ", path)
  sub("\\s.*$", "", out[[1L]])
}
b1_ev_kv <- function(path) {
  x <- readLines(path, warn = FALSE)
  p <- strsplit(x, "=", fixed = TRUE)
  stats::setNames(vapply(p, function(z) paste(z[-1L], collapse = "="), character(1L)), vapply(p, `[[`, character(1L), 1L))
}
b1_ev_main <- function(args = commandArgs(trailingOnly = TRUE)) {
  a <- b1_ev_args(args)
  required <- c("contract", "manifest", "raw", "shard-dir", "original-shard-dir", "replay-task-id", "original-source-sha", "original-receipt-sha", "replay-source-sha", "replay-receipt-sha", "out")
  invisible(lapply(required, function(x) b1_ev_need(a, x)))
  source(a[["contract"]])
  manifest <- utils::read.delim(a[["manifest"]], check.names = FALSE, stringsAsFactors = FALSE)
  canonical <- b1_make_full_manifest()
  if (!identical(names(manifest), names(canonical)) || nrow(manifest) != nrow(canonical) ||
      !isTRUE(all.equal(manifest, canonical, check.attributes = FALSE))) b1_ev_stop("Submitted manifest differs from canonical B1 full manifest.")
  raw <- utils::read.delim(a[["raw"]], check.names = FALSE, stringsAsFactors = FALSE)
  expected <- do.call(rbind, lapply(seq_len(nrow(canonical)), function(i) {
    task <- canonical[i, , drop = FALSE]; reps <- seq.int(task$replicate_start, task$replicate_end)
    data.frame(logical_task_id = task$logical_task_id, cell_id = task$cell_id, family = task$family, dpar = task$dpar,
      effect = task$effect, adapter = task$adapter, adapter_status = task$adapter_status, target = task$target,
      information_rung = task$information_rung, shard = task$shard, replicate = reps,
      seed = seq.int(task$seed_start, task$seed_end), stringsAsFactors = FALSE)
  }))
  binding <- names(expected)
  if (nrow(raw) != nrow(expected) || anyDuplicated(raw[c("logical_task_id", "replicate")])) b1_ev_stop("Raw evidence does not have the canonical 9,600-row task/replicate key.")
  raw <- raw[order(raw$logical_task_id, raw$replicate), , drop = FALSE]
  expected <- expected[order(expected$logical_task_id, expected$replicate), , drop = FALSE]
  for (name in binding) if (!identical(as.character(raw[[name]]), as.character(expected[[name]]))) b1_ev_stop("Raw field differs from canonical map: ", name)
  if (!all(raw$attempt_status %in% c("fit_completed", "fit_error"))) b1_ev_stop("Raw evidence has a nonterminal attempt status.")
  ids <- canonical$logical_task_id
  files <- file.path(a[["shard-dir"]], sprintf("b1-task-%06d.tsv", ids))
  original <- file.path(a[["original-shard-dir"]], sprintf("b1-task-%06d.tsv", ids))
  present <- list.files(a[["shard-dir"]], pattern = "^b1-task-[0-9]{6}\\.tsv$", full.names = TRUE)
  if (!setequal(normalizePath(files, mustWork = FALSE), normalizePath(present, mustWork = FALSE))) b1_ev_stop("Replay shard set differs from canonical task set.")
  if (any(vapply(files, function(x) length(readLines(x, warn = FALSE)) != 11L, logical(1L)))) b1_ev_stop("A replay shard is not exactly header plus ten rows.")
  replay_id <- as.integer(a[["replay-task-id"]])
  for (i in seq_along(ids)) if (ids[[i]] != replay_id && !identical(b1_ev_sha256(files[[i]]), b1_ev_sha256(original[[i]]))) b1_ev_stop("Unexpected replay difference in task ", ids[[i]])
  prov <- file.path(a[["shard-dir"]], sprintf("provenance-logical_%d.txt", ids))
  if (!all(file.exists(prov))) b1_ev_stop("Missing task provenance file.")
  for (i in seq_along(ids)) {
    p <- b1_ev_kv(prov[[i]])
    expected_source <- if (ids[[i]] == replay_id) a[["replay-source-sha"]] else a[["original-source-sha"]]
    expected_receipt <- if (ids[[i]] == replay_id) a[["replay-receipt-sha"]] else a[["original-receipt-sha"]]
    if (!identical(p[["logical_task_id"]], as.character(ids[[i]])) || !identical(p[["source_sha"]], expected_source) ||
        !identical(p[["manifest_sha256"]], b1_ev_sha256(a[["manifest"]])) || !identical(p[["preflight_sha256"]], expected_receipt) ||
        !identical(p[["runner_exit_code"]], "0")) b1_ev_stop("Task provenance mismatch: ", ids[[i]])
  }
  out <- data.frame(key = c("canonical_manifest_sha256", "raw_rows", "fit_completed", "fit_error", "replay_task_id", "permitted_replay_difference", "original_source_sha", "replay_source_sha"),
    value = c(b1_ev_sha256(a[["manifest"]]), nrow(raw), sum(raw$attempt_status == "fit_completed"), sum(raw$attempt_status == "fit_error"), replay_id,
      "task_41_tsv_error_newline_normalization_only", a[["original-source-sha"]], a[["replay-source-sha"]]), stringsAsFactors = FALSE)
  utils::write.table(out, a$out, sep = "\t", quote = FALSE, row.names = FALSE)
  print(out)
}
if (sys.nframe() == 0L) b1_ev_main()
