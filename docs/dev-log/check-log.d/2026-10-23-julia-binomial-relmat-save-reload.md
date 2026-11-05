# Julia Binomial related-matrix save/reload workflow

- Command: `PATH="/Users/z3437171/.juliaup/bin:$PATH" OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 DRMTMB_JULIA_TESTS=true NOT_CRAN=true DRM_JL_PATH="/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia" JULIA_DEPOT_PATH=/private/tmp/drmTMB-julia-depot:/Users/z3437171/.julia JULIA_NUM_THREADS=4 Rscript -e 'devtools::test(filter = "julia-binomial-relmat-sd-parity", reporter = "summary", stop_on_failure = TRUE)'`
- Result: exit 0, 35 assertions passed, one live Julia bridge test; known non-fatal JuliaCall extension warning.
- New assertions compare SD coefficients, `predict()` values, and `predict_parameters()` estimates across RDS save/reload.
- Evidence receipt: `docs/dev-log/general-sd-regression/evidence/julia-binomial-relmat-rds-20261023/receipt.json`; source manifest covers 199 native and Julia files.
- Reconciliation: 19,118 candidate rows, 26 distinct linked rows, 32 evidence records; reconciler tests 11/11 passed.
- Scope: one synthetic q1 Binomial relmat intercept; no calibrated-interval or broad parity claim.
