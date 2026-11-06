# Check log: lognormal sigma-endpoint SD regression (2026-10-21)

- Added an independent synthetic test for predictor-dependent SD of an existing lognormal `sigma` random intercept, including a constant-SD equivalence case.
- Focused command: `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "^lognormal-sigma-sd-regression$", reporter = "summary", stop_on_failure = TRUE)'`.
- Result: expected red test-first discovery. Both tests stop in `parse_sd_lhs()` because `dpar = "sigma"` remains reserved; no likelihood fit ran.
- Source changes are pending cross-ref reconciliation for the shared formula parser, then a complete target/design/TMB/output implementation. No Julia, compute campaign, or interval coverage claim.
- Detail: `LOOP/lanes/general-sd-regression/checkpoint.md`, section `2026-10-21 Lognormal sigma-endpoint SD: test-first discovery`.
