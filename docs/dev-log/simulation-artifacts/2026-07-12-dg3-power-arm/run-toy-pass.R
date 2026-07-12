# DG3 power-arm TOY-SCALE local pass (Curie, 2026-07-12). Validates
# inst/dg3-power-arm/harness.R + families.R end-to-end, ALL 18 model types,
# on a small (n = 20) seed grid -- see the 2026-07-05 empty-60-min-run lesson
# (stream+flush per fit, fast decisive fit first, heartbeat to a .log).
# NOTE this is still a TOY-SCALE pass for harness validation + preliminary
# numbers: the GATED campaign (>=400 seeds/family, verification-spec.md's
# compute directive) belongs on Totoro/DRAC, not here -- see the after-task
# report for the exact job spec.
#
# Run: R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 \
#   OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 Rscript --no-init-file \
#   docs/dev-log/simulation-artifacts/2026-07-12-dg3-power-arm/run-toy-pass.R

if (!identical(Sys.getenv("NOT_CRAN"), "true")) {
  stop("Set NOT_CRAN=true to run the DG3 power-arm toy pass.")
}

suppressMessages(devtools::load_all(".", quiet = TRUE))
source("inst/dg3-power-arm/harness.R")
source("inst/dg3-power-arm/families.R")

out_dir <- "docs/dev-log/simulation-artifacts/2026-07-12-dg3-power-arm"
seeds <- 1:20

# Clear any stale per-family TSV/LOG from earlier incremental development
# runs (unlink(), not shell rm, so a fresh full pass never silently appends
# behind an old header or mixes pre-DGP-fix rows with post-fix rows).
for (fam_name in names(dg3_registry_all)) {
  unlink(file.path(out_dir, paste0(fam_name, ".tsv")))
  unlink(file.path(out_dir, paste0(fam_name, ".log")))
}

run_log <- file.path(out_dir, "run-toy-pass.log")
cat(sprintf("=== toy pass start %s (seeds 1:%d, %d families) ===\n",
  format(Sys.time()), length(seeds), length(dg3_registry_all)),
  file = run_log, append = TRUE)

t_all <- Sys.time()
for (fam_name in names(dg3_registry_all)) {
  t0 <- Sys.time()
  dg3_run_family(dg3_registry_all[[fam_name]], seeds, out_dir)
  el <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  cat(sprintf("--- %s total: %.1fs ---\n", fam_name, el), file = run_log, append = TRUE)
  cat(sprintf("--- %s total: %.1fs ---\n", fam_name, el))
}
el_all <- as.numeric(difftime(Sys.time(), t_all, units = "secs"))
cat(sprintf("=== toy pass done %s (%.1fs total) ===\n", format(Sys.time()), el_all),
  file = run_log, append = TRUE)
cat(sprintf("=== toy pass done %s (%.1fs total) ===\n", format(Sys.time()), el_all))
