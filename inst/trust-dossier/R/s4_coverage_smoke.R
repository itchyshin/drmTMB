## S4 — coverage SMOKE for the Normal-Normal meta-analysis (drmTMB meta_V).
## Reuses the mature in-package Phase-18 meta_v simulation harness (inst/sim/): its
## DGP, fit, and replicate-runner. This is a SMOKE that proves the harness runs and
## that Wald coverage sits near nominal on a small rep count — NOT the calibrated
## evidence. The full adversarial grid (4 effect measures SMD/lnRR/OR/IRR x wide DGP
## range x many reps; coverage/type-I/power) is the CORE evidence and is commissioned
## to Totoro/DRAC, never GitHub Actions (D-50). See s4_write_totoro_commission().

## Source the harness from the local tree (NOT the installed package — the worktree
## is ground truth). `sim_root` must point at inst/sim.
s4_source_harness <- function(sim_root) {
  files <- c("R/sim_registry.R", "R/sim_utils.R", "R/sim_runner.R",
             "R/sim_aggregate.R", "R/sim_uncertainty.R",
             "dgp/sim_dgp_meta_v.R", "fit/sim_summarise_meta_v.R",
             "run/sim_run_meta_v_smoke.R")
  for (f in files) source(file.path(sim_root, f), local = FALSE)
  invisible(TRUE)
}

s4_coverage_smoke <- function(sim_root, n_rep = 100L, master_seed = 20260518L,
                              level = 0.95) {
  s4_source_harness(sim_root)
  ## focused Normal-Normal cell: vector known V, moderate heterogeneity
  conditions <- phase18_meta_v_conditions(
    n_study = 40L, known_v_type = "vector",
    sigma = 0.25, sampling_sd = 0.14, sampling_rho = 0
  )
  res <- phase18_run_meta_v_smoke(conditions = conditions, n_rep = n_rep,
                                  master_seed = master_seed)
  s <- res$summary
  s <- s[s$converged & s$pdHess, , drop = FALSE]

  ## Wald coverage per parameter: |estimate - truth| <= z * std.error
  z <- stats::qnorm(1 - (1 - level) / 2)
  s$covered <- abs(s$error) <= z * s$std.error
  by_par <- split(s, s$parameter)
  out <- do.call(rbind, lapply(names(by_par), function(term) {
    x <- by_par[[term]]
    cov <- mean(x$covered)
    data.frame(
      parameter   = term,
      n_rep       = nrow(x),
      coverage    = cov,
      mcse        = sqrt(cov * (1 - cov) / nrow(x)),
      mean_bias   = mean(x$error),
      nominal     = level,
      stringsAsFactors = FALSE
    )
  }))
  rownames(out) <- NULL
  attr(out, "design") <- "Normal-Normal meta-analysis, n_study=40, vector known V, sigma=0.25"
  attr(out, "note") <- sprintf(
    "SMOKE (%d reps) — proves harness; intercept/sigma near nominal, slope may sit low; NOT calibrated evidence. Full grid -> Totoro.",
    n_rep
  )
  out
}

## Write the Totoro commission stub: the manifest for the full adversarial grid
## that is the CORE validation evidence (not run in this lane).
s4_write_totoro_commission <- function(path) {
  txt <- c(
    "# Totoro commission — Trust Dossier #1 coverage/type-I/power GRID",
    "",
    "STATUS: PLANNED (commissioned, not run in the Claude lane). Compute: Totoro",
    "(384 cores, no queue) or DRAC job array. NEVER GitHub Actions (D-50).",
    "",
    "## Scope (the CORE evidence Wolfgang asked for: 'thousands of tests')",
    "- Effect measures: SMD, lnRR, OR, IRR (4).",
    "- DGP range: heterogeneity sigma in {0, 0.1, 0.25, 0.5}; n_study in {10, 20, 40, 80};",
    "  sampling-variance scale wide; known-V type {vector, dense}; sampling_rho in {0, 0.2, 0.5}.",
    "- Metrics: bias, RMSE, Wald + profile interval coverage, type-I error, power, convergence.",
    "- Reps: >= 2000 per cell (MCSE ~ 0.005 on a 0.95 coverage).",
    "- Comparator per cell: metafor::rma / rma.mv where it applies; simulation-from-truth where not.",
    "",
    "## Harness to reuse (already in inst/sim/)",
    "- DGP: inst/sim/dgp/sim_dgp_meta_v.R (phase18_dgp_meta_v)",
    "- fit: inst/sim/run/sim_run_meta_v_smoke.R (phase18_fit_meta_v)",
    "- coverage/type-I engine: inst/sim/R/sim_uncertainty.R, inst/sim/R/sim_power.R",
    "- grid writer: inst/sim/run/sim_write_meta_v_grid.R (emits Wald-coverage CSV)",
    "",
    "## Golden rules (tools/totoro-setup.md, tools/drac-setup.md)",
    "- OPENBLAS_NUM_THREADS=1; cap parallelism <= 96 cores on Totoro (shared lab server).",
    "- Depot/library on /project (DRAC) — never /scratch. Copy keepers off /scratch (~60d purge).",
    "- Results stay LOCAL (D-50); do not store as GitHub artifacts.",
    ""
  )
  writeLines(txt, path)
  invisible(path)
}
