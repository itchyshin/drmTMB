#!/usr/bin/env Rscript
# Orchestration-only scope repair. The frozen writer remains unchanged.
args <- commandArgs(trailingOnly = TRUE)
root_arg <- sub("^--campaign-root=", "", args[grepl("^--campaign-root=", args)])
if (length(root_arg) != 1L || !nzchar(root_arg)) stop("scopefix needs one --campaign-root", call. = FALSE)
helper <- file.path(normalizePath(root_arg, mustWork = TRUE), "source", "drmTMB",
                    "docs", "dev-log", "evidence", "julia-r-parity", "071-ordinary-laplace")
sys.source(file.path(helper, "s7-reconcile-campaign.R"), envir = .GlobalEnv)
sys.source(file.path(helper, "s7-write-coverage-summary.R"), envir = .GlobalEnv)
parsed <- r071_s7_coverage_args(args)
script <- sub("^--file=", "", commandArgs(FALSE)[grepl("^--file=", commandArgs(FALSE))][[1L]])
r071_s7_write_coverage_summary(
  parsed[["campaign-root"]], parsed[["source-root"]], parsed[["drmjl-source-root"]],
  parsed[["out"]], normalizePath(script, mustWork = TRUE), parsed[["source-tree-check"]]
)
cat("S7_COVERAGE_SUMMARY_WRITTEN\n")
