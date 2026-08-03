#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
script_arg <- commandArgs(FALSE)[grep("^--file=", commandArgs(FALSE))]
script <- normalizePath(sub("^--file=", "", script_arg[[1L]]), mustWork = TRUE)
root <- normalizePath(file.path(dirname(script), ".."), mustWork = TRUE)
source(file.path(root, "tools", "spatial-q2-confidence-eye-common.R"))
opts <- ce_parse_args(args)
required <- c("stage", "input", "output", "packet")
if (!all(required %in% names(opts))) {
  stop("Required: --stage --input --output --packet", call. = FALSE)
}
stage <- match.arg(opts$stage, c("smoke", "full"))
packet <- ce_validate_packet(opts$packet)
ce_reconcile(stage, opts$input, opts$output, packet)
message("reconciled ", stage, " outcomes into ", opts$output)
