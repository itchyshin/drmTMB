#!/usr/bin/env Rscript

# Private DRAC worker for one frozen F4R cell.  It is not a public package API.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 4L) {
  stop("Usage: worker.R <source-root> <library> <shard-id> <scratch-shard>", call. = FALSE)
}
source_root <- normalizePath(args[[1L]])
library_root <- normalizePath(args[[2L]])
shard_id <- suppressWarnings(as.integer(args[[3L]]))
scratch_shard <- normalizePath(args[[4L]], mustWork = FALSE)
if (!is.finite(shard_id) || shard_id < 1L || shard_id > 16L) {
  stop("F4R shard-id must be 1..16", call. = FALSE)
}

expected_sha <- trimws(readLines(file.path(source_root, "F4R-SOURCE-SHA.txt"), warn = FALSE))
if (length(expected_sha) != 1L || !grepl("^[0-9a-f]{40}$", expected_sha)) {
  stop("F4R source SHA receipt mismatch", call. = FALSE)
}
expected_blobs <- c(
  "R/associate-pairs-sandwich.R" = "d090f67b74bf5dfee6baa4396a8f45a3c977d6fd",
  "tests/testthat/test-associate-pairs-staged-sandwich.R" = "d36b02b2ad470e641843d4f751ee1c998e6922bf"
)
blob_file <- file.path(source_root, "F4R-SOURCE-BLOBS.tsv")
if (!file.exists(blob_file)) stop("F4R source blob receipt is absent", call. = FALSE)
blobs <- utils::read.delim(blob_file, stringsAsFactors = FALSE, check.names = FALSE)
if (!identical(stats::setNames(blobs$blob, blobs$path), expected_blobs)) {
  stop("F4R source blob receipt mismatch", call. = FALSE)
}

setwd(source_root)
source(file.path(source_root, "tools", "run-arc6-bernoulli-nbinom2-f4r-private.R"), local = .GlobalEnv)
manifest <- f4r_seed_manifest()
f4r_validate_seed_manifest(manifest)
rows <- manifest[manifest$cell_id == sprintf("f4r-c%02d", shard_id), , drop = FALSE]
if (nrow(rows) != 1000L) stop("F4R shard does not contain exactly 1,000 seeds", call. = FALSE)
if (dir.exists(scratch_shard)) stop("F4R refuses to overwrite an existing shard directory", call. = FALSE)
dir.create(scratch_shard, recursive = TRUE, showWarnings = FALSE)
utils::write.table(rows, file.path(scratch_shard, "seed-manifest.tsv"), sep = "\t", row.names = FALSE, quote = FALSE)
utils::write.table(data.frame(path = names(expected_blobs), blob = unname(expected_blobs)), file.path(scratch_shard, "source-blobs.tsv"), sep = "\t", row.names = FALSE, quote = FALSE)
writeLines(c(expected_sha, capture.output(sessionInfo())), file.path(scratch_shard, "provenance.txt"))

loadNamespace("drmTMB", lib.loc = library_root)
ns <- asNamespace("drmTMB")
if (!startsWith(normalizePath(getNamespaceInfo(ns, "path")), library_root)) {
  stop("F4R loaded drmTMB outside the packet library", call. = FALSE)
}
status_path <- file.path(scratch_shard, "all-attempts.tsv")
for (i in seq_len(nrow(rows))) {
  status <- tryCatch(
    f4_run_attempt(rows[i, , drop = FALSE], expected_sha, ns),
    error = function(e) {
      out <- f4_status_template(rows[i, , drop = FALSE], expected_sha)
      out$protocol_status <- "quarantined"
      out$failure_reason <- paste0("unexpected_runner_error:", conditionMessage(e))
      f4_terminalize(out)
    }
  )
  if (!identical(names(status), f4_status_columns) || nrow(status) != 1L ||
      !identical(status$seed, rows$seed[[i]]) || !identical(status$source_sha, expected_sha)) {
    stop("F4R malformed all-attempt status; campaign quarantined", call. = FALSE)
  }
  utils::write.table(status, status_path, sep = "\t", row.names = FALSE,
    quote = FALSE, append = file.exists(status_path), col.names = !file.exists(status_path))
  if (!identical(status$protocol_status, "valid")) {
    stop("F4R protocol quarantine; stopping this shard without a retry", call. = FALSE)
  }
}
written <- utils::read.delim(status_path, stringsAsFactors = FALSE, check.names = FALSE)
if (nrow(written) != 1000L || !identical(names(written), f4_status_columns) ||
    !identical(written$seed, rows$seed)) {
  stop("F4R final status table malformed; campaign quarantined", call. = FALSE)
}
writeLines("complete", file.path(scratch_shard, "RUN-COMPLETE.txt"))
