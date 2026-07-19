#!/usr/bin/env Rscript
## Trust Dossier #1 — FULL coverage / type-I / power GRID (Totoro campaign).
## This is the CORE simulation evidence (Wolfgang's "thousands of tests"), the
## calibrated complement to the S4 smoke. It reuses the in-package Phase-18 meta_v
## harness (DGP + fit + Wald-coverage writer) over a broad adversarial grid.
##
## HONEST SCOPE: every effect measure below is fit by the SAME Gaussian marginal
## meta-analysis likelihood  y_i ~ N(theta, v_i + tau^2)  — which is exactly how
## metafor and drmTMB treat SMD / lnRR / logOR / logIRR (the measure enters as an
## effect size y_i with a known sampling variance v_i). The four "measures" here are
## therefore DGP REGIMES (typical effect magnitude x sampling-variance scale), not
## different likelihoods. That is the correct thing to stress-test for this claim.
##
## Compute: Totoro (384 cores, no queue) or a DRAC array. NEVER GitHub Actions (D-50).
## Results stay LOCAL. Config via env:
##   TD_NREP  reps per cell   (default 2000; MCSE ~ 0.005 on 0.95 coverage)
##   TD_CORES parallel workers(default 96; keep <= 100 on shared Totoro)
##   TD_OUT   output dir      (default ./results-grid)
##   TD_SMOKE if set, a tiny grid + few reps to prove the driver locally
## Always run with OPENBLAS_NUM_THREADS=1 (set in the dispatch runbook).

suppressWarnings(suppressMessages(library(drmTMB)))

## ---- locate + source the harness from the source tree (ground truth) ----
args <- commandArgs(trailingOnly = FALSE)
file_arg <- sub("^--file=", "", args[grep("^--file=", args)])
here <- if (length(file_arg)) normalizePath(dirname(file_arg)) else normalizePath(".")
pkg_root <- normalizePath(file.path(here, "..", "..", ".."))
sim_root <- file.path(pkg_root, "inst", "sim")
if (!dir.exists(sim_root)) sim_root <- system.file("sim", package = "drmTMB", mustWork = TRUE)
for (f in c("R/sim_registry.R", "R/sim_utils.R", "R/sim_runner.R", "R/sim_aggregate.R",
            "R/sim_uncertainty.R", "dgp/sim_dgp_meta_v.R", "fit/sim_summarise_meta_v.R",
            "run/sim_run_meta_v_smoke.R", "run/sim_summary_meta_v_smoke.R",
            "run/sim_write_meta_v_grid.R")) {
  source(file.path(sim_root, f))
}

## Three tiers: TD_SMOKE (toy, prove driver) < TD_LOCAL (broad, vector-V, minutes on
## a laptop) < full (calibrated Totoro campaign, the default).
smoke  <- nzchar(Sys.getenv("TD_SMOKE"))
local  <- nzchar(Sys.getenv("TD_LOCAL"))
tier   <- if (smoke) "smoke" else if (local) "local" else "full"
n_rep  <- as.integer(Sys.getenv("TD_NREP", switch(tier, smoke = "3", local = "400", full = "2000")))
cores  <- as.integer(Sys.getenv("TD_CORES", switch(tier, smoke = "2", local = "6", full = "96")))
out    <- Sys.getenv("TD_OUT", file.path(here, "results-grid"))
dir.create(out, recursive = TRUE, showWarnings = FALSE)

## ---- effect-measure regimes: (typical effect theta, sampling-SD scale) ----
## Values chosen to span the realistic (effect, sampling-variance) space each
## measure occupies in ecology/evolution meta-analyses.
measures <- list(
  SMD   = list(beta_mu_intercept = 0.30, beta_mu_x = 0.40, sampling_sd = c(0.12, 0.22)),
  lnRR  = list(beta_mu_intercept = 0.15, beta_mu_x = 0.25, sampling_sd = c(0.08, 0.18)),
  logOR = list(beta_mu_intercept = 0.50, beta_mu_x = 0.60, sampling_sd = c(0.20, 0.40)),
  logIRR= list(beta_mu_intercept = 0.20, beta_mu_x = 0.35, sampling_sd = c(0.15, 0.30))
)
## DGP axes crossed within every measure (widen with tier)
n_study      <- switch(tier, smoke = 40L, local = c(20L, 40L, 80L),        full = c(10L, 20L, 40L, 80L))
sigma_grid   <- switch(tier, smoke = 0.25, local = c(0.0, 0.25, 0.50),      full = c(0.0, 0.10, 0.25, 0.50))
known_v_type <- switch(tier, smoke = "vector", local = "vector",            full = c("vector", "dense"))
sampling_rho <- switch(tier, smoke = 0, local = c(0, 0.25),                 full = c(0, 0.20, 0.50))
if (smoke) measures <- measures[c("SMD", "lnRR")]

manifest <- data.frame()
t0 <- proc.time()[["elapsed"]]
for (m in names(measures)) {
  mp <- measures[[m]]
  conditions <- phase18_meta_v_conditions(
    n_study = n_study, known_v_type = known_v_type,
    sigma = sigma_grid, sampling_sd = mp$sampling_sd, sampling_rho = sampling_rho,
    beta_mu_intercept = mp$beta_mu_intercept, beta_mu_x = mp$beta_mu_x
  )
  ## emit the cell_id -> DGP-conditions map (join key for the coverage CSVs; cell_ids
  ## are assigned in conditions-row order as meta_v_%03d).
  cond_map <- cbind(cell_id = sprintf("meta_v_%03d", seq_len(nrow(conditions))),
                    measure = m, conditions)
  dir.create(file.path(out, m), recursive = TRUE, showWarnings = FALSE)
  write.csv(cond_map, file.path(out, m, "conditions-map.csv"), row.names = FALSE)
  cat(sprintf("[%s] %d cells x %d reps on %d cores ...\n", m, nrow(conditions), n_rep, cores))
  phase18_write_meta_v_grid_outputs(
    output_dir = file.path(out, m), conditions = conditions,
    n_rep = n_rep, master_seed = 20260714L, overwrite = TRUE, cores = cores
  )
  manifest <- rbind(manifest, data.frame(
    measure = m, cells = nrow(conditions), n_rep = n_rep,
    coverage_csv = file.path(m, "tables", "meta-v-wald-coverage.csv"),
    stringsAsFactors = FALSE
  ))
}
write.csv(manifest, file.path(out, "grid-manifest.csv"), row.names = FALSE)
cat(sprintf("\nDONE: %d measures, %d total cells, %d reps each, %.0f s wall.\nOutputs -> %s\n",
            nrow(manifest), sum(manifest$cells), n_rep, proc.time()[["elapsed"]] - t0, out))
cat("Coverage tables: <measure>/tables/meta-v-wald-coverage.csv\n")
