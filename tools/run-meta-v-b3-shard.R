#!/usr/bin/env Rscript

# Run one already-frozen B3 shard.  This entry point is intentionally
# sequential: Totoro concurrency is obtained by launching distinct shard
# processes, never by nesting the Phase 18 in-process multicore backend.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 3L) {
  stop(
    "Usage: run-meta-v-b3-shard.R <contract.rds> <shard-id> <result-dir>",
    call. = FALSE
  )
}
if (!requireNamespace("drmTMB", quietly = TRUE)) {
  stop("The installed drmTMB package is required.", call. = FALSE)
}
suppressPackageStartupMessages(library(drmTMB))

for (path in c(
  "sim/R/sim_utils.R",
  "sim/R/sim_registry.R",
  "sim/R/sim_runner.R",
  "sim/dgp/sim_dgp_meta_v.R",
  "sim/fit/sim_summarise_meta_v.R",
  "sim/run/sim_run_meta_v_smoke.R",
  "sim/run/sim_summary_meta_v_smoke.R",
  "sim/run/sim_meta_v_b3_contract.R"
)) {
  source(system.file(path, package = "drmTMB", mustWork = TRUE), local = TRUE)
}

contract <- readRDS(args[[1L]])
shard_id <- suppressWarnings(as.integer(args[[2L]]))
if (is.na(shard_id)) {
  stop("`shard-id` must be a positive whole number.", call. = FALSE)
}
phase18_run_meta_v_b3_shard(
  contract = contract,
  shard_id = shard_id,
  result_dir = args[[3L]],
  overwrite = FALSE
)
