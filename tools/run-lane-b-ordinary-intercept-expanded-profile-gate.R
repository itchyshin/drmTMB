#!/usr/bin/env Rscript
# Run one of the nine source-bound expanded ordinary RE-SD intercept gates.
#
# This is a narrow configuration of the shared fail-closed receipt runner. It
# does not alter profile acceptance semantics or any existing two-cell receipt.

`%||%` <- function(x, y) if (is.null(x) || !length(x)) y else x

expanded_file_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
expanded_script <- normalizePath(
  if (length(expanded_file_arg)) sub("^--file=", "", expanded_file_arg[[1L]]) else
    "tools/run-lane-b-ordinary-intercept-expanded-profile-gate.R", mustWork = TRUE
)
expanded_tools <- dirname(expanded_script)
expanded_root <- normalizePath(file.path(expanded_tools, ".."), mustWork = TRUE)
runner_env <- new.env(parent = globalenv())
sys.source(file.path(expanded_tools, "run-lane-b-ordinary-slope-profile-gate.R"), envir = runner_env)

runner_env$ordinary_slope_profile_cells <- c(
  "mc-0225", "mc-0265", "mc-0267", "mc-0401", "mc-0403", "mc-0429",
  "mc-0463", "mc-0538", "mc-0567"
)
runner_env$ordinary_slope_profile_script <- expanded_script
runner_env$ordinary_slope_profile_binding_path <- function() {
  file.path(expanded_root, "docs", "dev-log", "interval-campaign-bindings",
            "2026-07-28-ordinary-re-sd-intercept-expanded-canonical-registry.tsv")
}
runner_env$ordinary_slope_profile_adapter_path <- function() {
  file.path(expanded_tools, "lane-b-ordinary-intercept-expanded-adapters.R")
}
runner_env$ordinary_slope_profile_paths <- function(output_dir, cell_id, seed, rung) {
  stem <- sprintf("lane-b-ordinary-intercept-expanded-profile-%s-%s-seed-%d", cell_id, rung, seed)
  list(
    trace = file.path(output_dir, paste0(stem, "-trace.tsv")),
    interval = file.path(output_dir, paste0(stem, "-interval.tsv")),
    receipt = file.path(output_dir, paste0(stem, "-receipt.tsv"))
  )
}

runner_env$ordinary_slope_profile_runner_main(commandArgs(trailingOnly = TRUE))
