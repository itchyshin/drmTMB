# Totoro commission — Trust Dossier #1 coverage/type-I/power GRID

STATUS: PLANNED (commissioned, not run in the Claude lane). Compute: Totoro
(384 cores, no queue) or DRAC job array. NEVER GitHub Actions (D-50).

## Scope (the CORE evidence Wolfgang asked for: 'thousands of tests')
- Effect measures: SMD, lnRR, OR, IRR (4).
- DGP range: heterogeneity sigma in {0, 0.1, 0.25, 0.5}; n_study in {10, 20, 40, 80};
  sampling-variance scale wide; known-V type {vector, dense}; sampling_rho in {0, 0.2, 0.5}.
- Metrics: bias, RMSE, Wald + profile interval coverage, type-I error, power, convergence.
- Reps: >= 2000 per cell (MCSE ~ 0.005 on a 0.95 coverage).
- Comparator per cell: metafor::rma / rma.mv where it applies; simulation-from-truth where not.

## Harness to reuse (already in inst/sim/)
- DGP: inst/sim/dgp/sim_dgp_meta_v.R (phase18_dgp_meta_v)
- fit: inst/sim/run/sim_run_meta_v_smoke.R (phase18_fit_meta_v)
- coverage/type-I engine: inst/sim/R/sim_uncertainty.R, inst/sim/R/sim_power.R
- grid writer: inst/sim/run/sim_write_meta_v_grid.R (emits Wald-coverage CSV)

## Golden rules (tools/totoro-setup.md, tools/drac-setup.md)
- OPENBLAS_NUM_THREADS=1; cap parallelism <= 96 cores on Totoro (shared lab server).
- Depot/library on /project (DRAC) — never /scratch. Copy keepers off /scratch (~60d purge).
- Results stay LOCAL (D-50); do not store as GitHub artifacts.

