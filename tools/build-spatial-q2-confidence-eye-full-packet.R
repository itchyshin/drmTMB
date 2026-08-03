#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
script_arg <- commandArgs(FALSE)[grep("^--file=", commandArgs(FALSE))]
script <- normalizePath(sub("^--file=", "", script_arg[[1L]]), mustWork = TRUE)
root <- normalizePath(file.path(dirname(script), ".."), mustWork = TRUE)
source(file.path(root, "tools", "spatial-q2-confidence-eye-common.R"))
opts <- ce_parse_args(args)
required <- c("output", "smoke-packet", "smoke-evidence")
if (!all(required %in% names(opts))) {
  stop("Required: --output --smoke-packet --smoke-evidence", call. = FALSE)
}
status <- system2("git", c("-C", root, "status", "--porcelain"), stdout = TRUE)
if (length(status)) stop("Full packet build requires a clean source tree.", call. = FALSE)
builder_sha <- trimws(system2("git", c("-C", root, "rev-parse", "HEAD"), stdout = TRUE))
smoke <- ce_validate_packet(opts[["smoke-packet"]])
evidence <- normalizePath(opts[["smoke-evidence"]], mustWork = TRUE)
decision <- utils::read.delim(file.path(evidence, "decision.tsv"), stringsAsFactors = FALSE)
resources <- utils::read.delim(file.path(evidence, "resource-projection.tsv"), stringsAsFactors = FALSE)
if (nrow(decision) != 1L || decision$verdict[[1L]] != "SMOKE_COMPLETE" ||
    nrow(resources) != 1L || !isTRUE(resources$within_cpu_hour_bound[[1L]]) ||
    !isTRUE(resources$within_wall_hour_bound[[1L]]) ||
    resources$completed_array_tasks[[1L]] != 60L) {
  stop("Smoke evidence does not authorize the full packet.", call. = FALSE)
}

output <- normalizePath(opts$output, mustWork = FALSE)
dir.create(output, recursive = TRUE, showWarnings = FALSE)
members <- c(
  "docs/design/249-spatial-q2-confidence-eye-joint-calibration.md",
  "tools/spatial-q2-confidence-eye-common.R",
  "tools/reconcile-spatial-q2-confidence-eye.R",
  "tools/collect-spatial-q2-confidence-eye-full-receipt.R",
  "tools/submit-spatial-q2-confidence-eye-full.sh",
  "tools/slurm/setup-spatial-q2-confidence-eye.sbatch",
  "tools/slurm/spatial-q2-confidence-eye-full.sbatch"
)
for (member in members) {
  destination <- file.path(output, member)
  dir.create(dirname(destination), recursive = TRUE, showWarnings = FALSE)
  if (!file.copy(file.path(root, member), destination, overwrite = TRUE)) {
    stop("Could not copy full packet member: ", member, call. = FALSE)
  }
}
for (member in c("SOURCE_SHA", "drmTMB-source.tar.gz")) {
  if (!file.copy(file.path(smoke$packet_dir, member), file.path(output, member), overwrite = TRUE)) {
    stop("Could not copy smoke source member: ", member, call. = FALSE)
  }
}
evidence_members <- c(
  "decision.tsv", "target-summary.tsv", "raw-target-outcomes.tsv",
  "resource-projection.tsv", "sacct.tsv", "submission.tsv", "r-environment.tsv"
)
dir.create(file.path(output, "smoke-evidence"), showWarnings = FALSE)
for (member in evidence_members) {
  if (!file.copy(file.path(evidence, member), file.path(output, "smoke-evidence", member), overwrite = TRUE)) {
    stop("Could not copy smoke evidence member: ", member, call. = FALSE)
  }
}
manifest_members <- c(
  members,
  "SOURCE_SHA",
  "drmTMB-source.tar.gz",
  file.path("smoke-evidence", evidence_members)
)
manifest <- data.frame(
  path = manifest_members,
  sha256 = vapply(file.path(output, manifest_members), ce_sha256_file, character(1L)),
  stringsAsFactors = FALSE
)
ce_atomic_write_tsv(manifest, file.path(output, "manifest.tsv"))
metadata <- data.frame(
  key = c("source_sha", "packet_sha256", "builder_sha", "smoke_packet_sha256", "created_utc"),
  value = c(
    smoke$source_sha,
    ce_sha256_file(file.path(output, "manifest.tsv")),
    builder_sha,
    smoke$packet_sha256,
    format(Sys.time(), tz = "UTC", usetz = TRUE)
  ),
  stringsAsFactors = FALSE
)
ce_atomic_write_tsv(metadata, file.path(output, "metadata.tsv"))
ce_validate_packet(output)
message("built full packet ", output)
