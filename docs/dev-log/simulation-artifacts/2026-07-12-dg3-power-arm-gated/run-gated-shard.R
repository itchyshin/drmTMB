# DG3 power-arm GATED local campaign, per-family SHARD driver (Curie,
# 2026-07-12). Reuses inst/dg3-power-arm/harness.R + families.R verbatim
# (no new machinery) -- see the toy pass
# (docs/dev-log/simulation-artifacts/2026-07-12-dg3-power-arm/run-toy-pass.R)
# for the validated end-to-end pipeline. This driver just widens the seed
# grid to 400 and runs a NAMED SUBSET of dg3_registry_all (a "shard") so
# several shards can run as parallel Rscript processes on this 20-core box,
# each streaming its own per-family TSV/LOG immediately (2026-07-05 lesson).
#
# Usage:
#   R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 \
#     OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 Rscript --no-init-file \
#     run-gated-shard.R <shard_label> <comma,separated,family,names>

if (!identical(Sys.getenv("NOT_CRAN"), "true")) {
  stop("Set NOT_CRAN=true to run the DG3 power-arm gated campaign.")
}

args <- commandArgs(trailingOnly = TRUE)
shard_label <- args[[1]]
fam_names <- strsplit(args[[2]], ",", fixed = TRUE)[[1]]

suppressMessages(devtools::load_all(".", quiet = TRUE))
source("inst/dg3-power-arm/harness.R")
source("inst/dg3-power-arm/families.R")

out_dir <- "docs/dev-log/simulation-artifacts/2026-07-12-dg3-power-arm-gated"
seeds <- 1:400

stopifnot(all(fam_names %in% names(dg3_registry_all)))
for (fam_name in fam_names) {
  unlink(file.path(out_dir, paste0(fam_name, ".tsv")))
  unlink(file.path(out_dir, paste0(fam_name, ".log")))
}

run_log <- file.path(out_dir, paste0("shard-", shard_label, ".log"))
cat(sprintf("=== shard %s start %s (seeds 1:%d, families: %s) ===\n",
  shard_label, format(Sys.time()), length(seeds), paste(fam_names, collapse = ", ")),
  file = run_log, append = TRUE)

t_all <- Sys.time()
for (fam_name in fam_names) {
  t0 <- Sys.time()
  dg3_run_family(dg3_registry_all[[fam_name]], seeds, out_dir)
  el <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  cat(sprintf("--- shard %s: %s total: %.1fs ---\n", shard_label, fam_name, el),
    file = run_log, append = TRUE)
  cat(sprintf("--- shard %s: %s total: %.1fs ---\n", shard_label, fam_name, el))
  flush(stdout())
}
el_all <- as.numeric(difftime(Sys.time(), t_all, units = "secs"))
cat(sprintf("=== shard %s done %s (%.1fs total) ===\n", shard_label, format(Sys.time()), el_all),
  file = run_log, append = TRUE)
cat(sprintf("=== shard %s done %s (%.1fs total) ===\n", shard_label, format(Sys.time()), el_all))
