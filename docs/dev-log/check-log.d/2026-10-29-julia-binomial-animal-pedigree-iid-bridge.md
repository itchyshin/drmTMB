# Julia Binomial pedigree animal plus IID site bridge

- Added a synthetic logit bridge test joining a pedigree-based animal intercept and an IID site intercept, each with a predictor-dependent SD.
- The focused test file passed with two live Julia bridge tests, no failures or skips. It checks covariance marshalling, convergence, target labels, likelihood and SD prediction agreement, and marginal binary simulation.
- Exact test snapshot, console, source manifest and receipt are under `docs/dev-log/general-sd-regression/evidence/julia-binomial-animal-pedigree-iid-bridge-20261029/`.
- Evidence reconciliation passed: 20,350 candidate rows, 210 linked rows, 20,140 unlinked rows, 237 records. The new exact row remains unreviewed; no support status changed. No coverage claim.
- Full report: `docs/dev-log/after-task/2026-10-29-julia-binomial-animal-pedigree-iid-bridge.md`.
