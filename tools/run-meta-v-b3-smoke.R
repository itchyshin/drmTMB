#!/usr/bin/env Rscript
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 3L) stop("Usage: run-meta-v-b3-smoke.R <contract.rds> <result-dir> <output-dir>", call. = FALSE)
if (!requireNamespace("drmTMB", quietly = TRUE)) stop("The installed drmTMB package is required.", call. = FALSE)
suppressPackageStartupMessages(library(drmTMB))
for (path in c("sim/R/sim_utils.R", "sim/R/sim_registry.R", "sim/R/sim_runner.R", "sim/R/sim_uncertainty.R", "sim/dgp/sim_dgp_meta_v.R", "sim/fit/sim_summarise_meta_v.R", "sim/run/sim_run_meta_v_smoke.R", "sim/run/sim_summary_meta_v_smoke.R", "sim/run/sim_meta_v_b3_contract.R")) source(system.file(path, package = "drmTMB", mustWork = TRUE), local = TRUE)
contract <- readRDS(args[[1L]])
smoke <- phase18_run_meta_v_b3_smoke(contract, result_dir = args[[2L]])
phase18_write_meta_v_b3_smoke_outputs(smoke, args[[3L]])
