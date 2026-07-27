#!/usr/bin/env Rscript
# Pure B1 DRAC dispatch planner.  It freezes manifests and derives an array
# layout, but deliberately never calls sbatch or loads drmTMB.

script_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
script <- if (length(script_arg)) sub("^--file=", "", script_arg[[1L]]) else {
  candidates <- c("tools/prepare-b1-drac-dispatch.R", "../../tools/prepare-b1-drac-dispatch.R")
  hits <- candidates[file.exists(candidates)]
  if (length(hits)) hits[[1L]] else "tools/prepare-b1-drac-dispatch.R"
}
source(file.path(dirname(normalizePath(script, mustWork = FALSE)), "b1-breadth-contract.R"))

b1_dispatch_stop <- function(...) stop(..., call. = FALSE)
b1_dispatch_args <- function(args) {
  if (any(!grepl("^--[A-Za-z][A-Za-z-]*=.+$", args))) b1_dispatch_stop("Arguments must use --name=value syntax.")
  keys <- sub("^--([^=]+)=.*$", "\\1", args)
  if (anyDuplicated(keys)) b1_dispatch_stop("Duplicate dispatch argument.")
  stats::setNames(sub("^--[^=]+=", "", args), keys)
}
b1_dispatch_need <- function(x, key) if (is.null(x[[key]]) || !nzchar(x[[key]])) b1_dispatch_stop("Missing --", key, "=.") else x[[key]]
b1_dispatch_integer <- function(x, name, lower = 1L, upper = Inf) {
  out <- suppressWarnings(as.integer(x))
  if (length(out) != 1L || is.na(out) || out < lower || out > upper) b1_dispatch_stop(name, " must be an integer in range.")
  out
}
b1_dispatch_partition <- function(manifest, max_array_size, concurrency) {
  b1_validate_task_manifest(manifest)
  max_array_size <- b1_dispatch_integer(max_array_size, "max-array-size")
  concurrency <- b1_dispatch_integer(concurrency, "concurrency", upper = 1000L)
  parts <- split(manifest, ceiling(seq_len(nrow(manifest)) / max_array_size))
  caps <- rep.int(floor(concurrency / length(parts)), length(parts))
  caps[seq_len(concurrency %% length(parts))] <- caps[seq_len(concurrency %% length(parts))] + 1L
  plan <- do.call(rbind, Map(function(part, i, cap) data.frame(
    partition_id = i, n_tasks = nrow(part), concurrency_cap = cap,
    logical_task_min = min(part$logical_task_id), logical_task_max = max(part$logical_task_id),
    stringsAsFactors = FALSE
  ), parts, seq_along(parts), caps))
  if (any(plan$n_tasks > max_array_size) || sum(plan$concurrency_cap) != concurrency) b1_dispatch_stop("Invalid partition plan.")
  list(parts = parts, plan = plan)
}
b1_dispatch_main <- function(args = commandArgs(trailingOnly = TRUE)) {
  a <- b1_dispatch_args(args); mode <- b1_dispatch_need(a, "mode")
  if (identical(mode, "smoke-manifest")) {
    allowed <- c("mode", "out"); if (length(setdiff(names(a), allowed))) b1_dispatch_stop("Unsupported smoke-manifest argument.")
    utils::write.table(b1_make_smoke_manifest(), b1_dispatch_need(a, "out"), sep = "\t", quote = FALSE, row.names = FALSE)
  } else if (identical(mode, "full-manifest")) {
    allowed <- c("mode", "out", "reps-per-shard"); if (length(setdiff(names(a), allowed))) b1_dispatch_stop("Unsupported full-manifest argument.")
    reps <- if (!"reps-per-shard" %in% names(a)) b1_default_replicates_per_shard else b1_dispatch_integer(a[["reps-per-shard"]], "reps-per-shard")
    utils::write.table(b1_make_full_manifest(reps), b1_dispatch_need(a, "out"), sep = "\t", quote = FALSE, row.names = FALSE)
  } else if (identical(mode, "partition-full")) {
    allowed <- c("mode", "manifest", "out-dir", "max-array-size", "concurrency")
    if (length(setdiff(names(a), allowed))) b1_dispatch_stop("Unsupported partition-full argument.")
    manifest <- utils::read.delim(b1_dispatch_need(a, "manifest"), check.names = FALSE, stringsAsFactors = FALSE)
    result <- b1_dispatch_partition(manifest, b1_dispatch_need(a, "max-array-size"), b1_dispatch_need(a, "concurrency"))
    out_dir <- b1_dispatch_need(a, "out-dir"); dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
    utils::write.table(result$plan, file.path(out_dir, "b1-array-partitions.tsv"), sep = "\t", quote = FALSE, row.names = FALSE)
    for (i in seq_along(result$parts)) {
      x <- result$parts[[i]]; x$array_index <- seq_len(nrow(x))
      utils::write.table(x, file.path(out_dir, sprintf("b1-full-manifest-partition-%03d.tsv", i)), sep = "\t", quote = FALSE, row.names = FALSE)
    }
  } else b1_dispatch_stop("Unsupported --mode=", mode)
}

if (sys.nframe() == 0L) b1_dispatch_main()
