# Julia Binomial correlated q2 bridge across links

- Added the logit live bridge case to the existing q2 correlated intercept-and-slope fixture; probit and cloglog remain included.
- The opt-in focused test passed one live JuliaCall test with 50 expectations, no failures or skips. Julia 1.10.0, one Julia thread, and one BLAS/OMP thread.
- Source snapshot, source hashes, and console are saved under `docs/dev-log/general-sd-regression/evidence/julia-binomial-correlated-q2-all-links-bridge-20261029/`.
- Evidence reconciliation passed: 20,350 candidate rows, 209 linked, 20,141 unlinked, 236 evidence records. New row is unreviewed focused-test evidence; no support promotion or interval coverage claim.
- Full report: `docs/dev-log/after-task/2026-10-29-julia-binomial-correlated-q2-all-links-bridge.md`.
