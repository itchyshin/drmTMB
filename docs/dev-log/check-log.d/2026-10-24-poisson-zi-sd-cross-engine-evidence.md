# Poisson ZIP SD cross-engine evidence, 2026-10-24

- Candidate pins: drmTMB `425bee81572c625a634b2b083050c5c57c1dc1f1`; DRM.jl `70dbf564eb670144c63c08f61ea099084d95add2`.
- Command: `devtools::test(filter = "julia-poisson-zi-sd-regression", reporter = "summary", stop_on_failure = TRUE)` with `DRMTMB_JULIA_TESTS=true`, `DRM_JL_PATH` set to the paired Julia candidate, and one Julia/OpenBLAS thread.
- Result: exit 0; one live Julia bridge test passed with no failures or skips. Before/after SHA-256 manifests match for 169 source files.
- Evidence: `docs/dev-log/general-sd-regression/evidence/poisson-zi-sd-cross-engine-20261024/`.
- Ledger: 19,118 rows, 45 receipt records, 36 linked, 19,082 unlinked. Two exact ordinary ZIP `mu` intercept rows added; both remain unreviewed.
- Boundary: fixed `zi`, one ordinary mean intercept, no offsets. No claim for other ZIP effects, `hu`, or coverage calibration.
