# Bernoulli ledger receipt refresh, 2026-10-24

- Exact candidate pins: drmTMB `425bee81572c625a634b2b083050c5c57c1dc1f1`; DRM.jl `70dbf564eb670144c63c08f61ea099084d95add2`.
- Command: `DRMTMB_JULIA_TESTS=true NOT_CRAN=true OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 JULIA_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "julia-binomial-sd", reporter = "summary", stop_on_failure = TRUE)'` with the paired Julia worktree configured.
- Result: exit 0; five live Julia bridge tests; no failures or skips. Two variance-boundary singular-Hessian diagnostics remain visible.
- Before/after SHA-256 manifests match for 167 source files. Full console and JSON receipt are in `docs/dev-log/general-sd-regression/evidence/julia-bridge-source-bound-20261024-rerun/`.
- `python3 tools/general-sd-regression/reconcile_evidence.py`: PASS, 19,118 rows, 43 receipt records, 34 linked rows, 19,084 unlinked rows.
- Scope: refreshed three Bernoulli evidence links only. No row promotion, programme gate closure, or coverage-calibration claim.
