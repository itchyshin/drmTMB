#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
script_arg <- commandArgs(FALSE)[grep("^--file=", commandArgs(FALSE))]
script <- normalizePath(sub("^--file=", "", script_arg[[1L]]), mustWork = TRUE)
root <- normalizePath(file.path(dirname(script), ".."), mustWork = TRUE)
source(file.path(root, "tools", "spatial-q2-confidence-eye-common.R"))
opts <- ce_parse_args(args)
if (!"output" %in% names(opts)) stop("Required: --output", call. = FALSE)
output <- normalizePath(opts$output, mustWork = FALSE)
dir.create(output, recursive = TRUE, showWarnings = FALSE)
source_sha <- trimws(system2("git", c("-C", root, "rev-parse", "HEAD"), stdout = TRUE))
status <- system2("git", c("-C", root, "status", "--porcelain"), stdout = TRUE)
if (length(status)) stop("Packet build requires a clean source tree.", call. = FALSE)

members <- c(
  "docs/design/249-spatial-q2-confidence-eye-joint-calibration.md",
  "tools/spatial-q2-confidence-eye-common.R",
  "tools/run-spatial-q2-confidence-eye-task.R",
  "tools/reconcile-spatial-q2-confidence-eye.R",
  "tools/slurm/spatial-q2-confidence-eye.sbatch"
)
for (member in members) {
  destination <- file.path(output, member)
  dir.create(dirname(destination), recursive = TRUE, showWarnings = FALSE)
  if (!file.copy(file.path(root, member), destination, overwrite = TRUE)) {
    stop("Could not copy packet member: ", member, call. = FALSE)
  }
}
archive <- file.path(output, "drmTMB-source.tar.gz")
status_code <- system2(
  "git",
  c("-C", root, "archive", "--format=tar.gz", paste0("--output=", archive), source_sha)
)
if (!identical(status_code, 0L)) stop("git archive failed.", call. = FALSE)
manifest_members <- c(members, "drmTMB-source.tar.gz")
manifest <- data.frame(
  path = manifest_members,
  sha256 = vapply(file.path(output, manifest_members), ce_sha256_file, character(1L)),
  stringsAsFactors = FALSE
)
ce_atomic_write_tsv(manifest, file.path(output, "manifest.tsv"))
metadata <- data.frame(
  key = c("source_sha", "packet_sha256", "created_utc"),
  value = c(
    source_sha,
    ce_sha256_file(file.path(output, "manifest.tsv")),
    format(Sys.time(), tz = "UTC", usetz = TRUE)
  ),
  stringsAsFactors = FALSE
)
ce_atomic_write_tsv(metadata, file.path(output, "metadata.tsv"))
ce_validate_packet(output)
message("built packet ", output)
