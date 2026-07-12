# DG3 power-arm n-LADDER driver (Curie, 2026-07-12). For the mis-spec cells
# the toy pass flagged as data-size-limited ("constant-vs-x mechanism"
# nuisance-absorption cases + the gamma<->lognormal wrong-family pair),
# rerun JUST that one mis-spec (fit_true = correctly-specified, fit_wrong =
# mis-specified) at n in {1000, 3000} to locate the power>=0.8 crossover.
# n=300/400 (the families' design n) is already covered by the main gated
# campaign (run-gated-shard.R) -- not repeated here.
#
# Reuses harness.R's low-level streaming primitives directly
# (dg3_fit_and_diagnose/dg3_stream_row/dg3_write_header/dg3_heartbeat) rather
# than dg3_run_family(), because dg3_run_family always ALSO fits a separate
# "Arm A" baseline per seed; for a single-cell n-ladder rerun that baseline
# fit is redundant compute we cannot afford under the time budget -- so this
# file calls the same per-fit functions the family-level runner calls,
# introducing no new fitting/diagnostic logic.
#
# Usage:
#   Rscript --no-init-file run-nladder-shard.R <cell_label> <family_name> <mis_spec_index> <n1,n2,...> <nseeds>

if (!identical(Sys.getenv("NOT_CRAN"), "true")) {
  stop("Set NOT_CRAN=true to run the DG3 power-arm n-ladder.")
}

args <- commandArgs(trailingOnly = TRUE)
cell_label <- args[[1]]
fam_name <- args[[2]]
ms_index <- as.integer(args[[3]])
n_values <- as.integer(strsplit(args[[4]], ",", fixed = TRUE)[[1]])
nseeds <- as.integer(args[[5]])

suppressMessages(devtools::load_all(".", quiet = TRUE))
source("inst/dg3-power-arm/harness.R")
source("inst/dg3-power-arm/families.R")

out_dir <- "docs/dev-log/simulation-artifacts/2026-07-12-dg3-power-arm-gated"
tsv <- file.path(out_dir, paste0("nladder_", cell_label, ".tsv"))
log_file <- file.path(out_dir, paste0("nladder_", cell_label, ".log"))
unlink(tsv)
unlink(log_file)
dg3_write_header(tsv)

ms <- dg3_registry_all[[fam_name]]$mis_specs[[ms_index]]
seeds <- seq_len(nseeds)

dg3_heartbeat(log_file, "=== nladder %s (%s / mis_spec[%d]=%s) start %s: n in {%s}, %d seeds ===\n",
  cell_label, fam_name, ms_index, ms$name, format(Sys.time()),
  paste(n_values, collapse = ","), nseeds)

t_all <- Sys.time()
for (n in n_values) {
  t0 <- Sys.time()
  for (seed in seeds) {
    dat_m <- ms$dgp(seed, n)
    res_true <- dg3_fit_and_diagnose(dat_m, ms$fit_true, response = ms$response, resid_seed = seed)
    dg3_stream_row(tsv, paste0(cell_label, "_n", n), ms$name, "true", seed, n, res_true)
    res_wrong <- dg3_fit_and_diagnose(dat_m, ms$fit_wrong, response = ms$response, resid_seed = seed)
    dg3_stream_row(tsv, paste0(cell_label, "_n", n), ms$name, "wrong", seed, n, res_wrong)
    if (seed %% 50 == 0) {
      dg3_heartbeat(log_file, "[%s n=%d] seed=%d/%d done (%.1fs elapsed)\n",
        cell_label, n, seed, nseeds, as.numeric(difftime(Sys.time(), t0, units = "secs")))
    }
  }
  el <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  dg3_heartbeat(log_file, "--- %s n=%d: %.1fs total (%d seeds) ---\n", cell_label, n, el, nseeds)
}
el_all <- as.numeric(difftime(Sys.time(), t_all, units = "secs"))
dg3_heartbeat(log_file, "=== nladder %s done %s (%.1fs total) ===\n", cell_label, format(Sys.time()), el_all)
