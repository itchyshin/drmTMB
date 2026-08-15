#!/usr/bin/env Rscript
# Execute a source-bound ordinary RE-SD intercept profile gate.
#
# The slope runner owns the shared retained-receipt semantics.  This thin
# adapter replaces only its frozen registry, allowed cells, artifact stem, and
# production fixture provider; no profile acceptance logic is duplicated.

`%||%` <- function(x, y) if (is.null(x) || !length(x)) y else x

intercept_file_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
intercept_script <- normalizePath(
  if (length(intercept_file_arg)) sub("^--file=", "", intercept_file_arg[[1L]]) else
    "tools/run-lane-b-ordinary-intercept-profile-gate.R", mustWork = TRUE
)
intercept_tools <- dirname(intercept_script)
intercept_root <- normalizePath(file.path(intercept_tools, ".."), mustWork = TRUE)
runner_env <- new.env(parent = globalenv())
sys.source(file.path(intercept_tools, "run-lane-b-ordinary-slope-profile-gate.R"), envir = runner_env)

runner_env$ordinary_slope_profile_cells <- c("mc-0005", "mc-0059")
runner_env$ordinary_slope_profile_script <- intercept_script
runner_env$ordinary_slope_profile_binding_path <- function() {
  file.path(intercept_root, "docs", "dev-log", "interval-campaign-bindings",
            "2026-07-28-ordinary-re-sd-intercept-canonical-registry.tsv")
}
runner_env$ordinary_slope_profile_adapter_path <- function() {
  file.path(intercept_tools, "lane-b-ordinary-intercept-adapters.R")
}
runner_env$ordinary_slope_profile_paths <- function(output_dir, cell_id, seed, rung) {
  stem <- sprintf("lane-b-ordinary-intercept-profile-%s-%s-seed-%d", cell_id, rung, seed)
  list(
    trace = file.path(output_dir, paste0(stem, "-trace.tsv")),
    interval = file.path(output_dir, paste0(stem, "-interval.tsv")),
    receipt = file.path(output_dir, paste0(stem, "-receipt.tsv"))
  )
}

runner_env$ordinary_slope_profile_runner_main(commandArgs(trailingOnly = TRUE))
