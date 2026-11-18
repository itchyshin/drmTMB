# Julia Poisson animal-slope raw A/Ainv evidence registration, 2026-10-24

- Candidate pins: drmTMB `425bee81572c625a634b2b083050c5c57c1dc1f1`; DRM.jl `70dbf564eb670144c63c08f61ea099084d95add2`.
- Existing Julia receipt: 25/25 passed in 21.6 seconds; source hashes in the copied receipt matched the current Julia source and test.
- Current local rerun: `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 JULIA_NUM_THREADS=1 /Users/z3437171/.juliaup/bin/julia --project=. -e 'include("test/test_poisson_animal_slope_sd_regression.jl")'`; 25/25 passed in 21.8 seconds. Before/after hashes matched for four source/test files.
- Reconciler: `python3 tools/general-sd-regression/reconcile_evidence.py --summary docs/dev-log/general-sd-regression/direct-sd-evidence-summary.md` passed: 19,118 candidate rows, 50 records, 41 distinct linked rows.
- Exact rows added: Julia Poisson log-link animal numeric slope with `A_covariance` and `Ainv_precision`; both remain unreviewed focused-test evidence.
- Evidence: `docs/dev-log/general-sd-regression/evidence/poisson-animal-slope-raw-a-20261024/`.
- Boundary: no native TMB or R bridge parity, broader Poisson support, or interval-coverage claim. No programme gate closes.
- After-task validator: structure passed; acceptance state `UNKNOWN` because no runnable gate node/check was present.
