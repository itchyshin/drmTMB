#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
script_arg <- commandArgs(FALSE)[grep("^--file=", commandArgs(FALSE))]
script <- normalizePath(sub("^--file=", "", script_arg[[1L]]), mustWork = TRUE)
root <- normalizePath(file.path(dirname(script), ".."), mustWork = TRUE)
source(file.path(root, "tools", "spatial-q2-confidence-eye-common.R"))
opts <- ce_parse_args(args)
required <- c("stage", "task", "packet", "output", "lib")
if (!all(required %in% names(opts))) {
  stop("Required: --stage --task --packet --output --lib", call. = FALSE)
}
stage <- match.arg(opts$stage, c("smoke", "full"))
task <- as.integer(opts$task)
design <- ce_design(stage)
if (!is.finite(task) || task < 1L || task > nrow(design)) {
  stop("Task index is outside the frozen design.", call. = FALSE)
}
packet <- ce_validate_packet(opts$packet)
library("drmTMB", lib.loc = opts$lib, character.only = TRUE)
row <- design[task, , drop = FALSE]
out <- ce_run_attempt(row, packet)
path <- file.path(
  opts$output,
  sprintf("%s-%s-%03d.tsv", stage, row$rung[[1L]], row$replicate[[1L]])
)
ce_atomic_write_tsv(out, path)
message("wrote ", path)
