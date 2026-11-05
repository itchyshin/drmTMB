# Julia Binomial animal-slope Ainv evidence registration, 2026-10-24

- Candidate pins: drmTMB `425bee81572c625a634b2b083050c5c57c1dc1f1`; DRM.jl `70dbf564eb670144c63c08f61ea099084d95add2`.
- Julia test command from the receipt: `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 JULIA_NUM_THREADS=1 /Users/z3437171/.juliaup/bin/julia --project=. -e 'include("test/test_binomial_animal_ainv_slope_sd_regression.jl")'`.
- Recorded result: exit 0, 10/10 passed in 15.3 seconds. The evidence registration copied the test and checked all four recorded source hashes; it did not rerun the fit.
- Reconciler: `python3 tools/general-sd-regression/reconcile_evidence.py --summary docs/dev-log/general-sd-regression/direct-sd-evidence-summary.md` passed: 19,118 candidate rows, 48 receipt records, 39 distinct linked rows.
- Evidence: `docs/dev-log/general-sd-regression/evidence/julia-binomial-animal-ainv-slope-20261024/`.
- Boundary: one Julia Binomial logit animal numeric-slope `Ainv_precision` cell; no R/TMB parity, broad support, or interval-coverage claim. The exact row remains unreviewed and no programme gate closes.
- After-task validator: structure passed; acceptance state `UNKNOWN` because the report checker found no runnable ledger node/check. This is not gate evidence.
