# Tweedie related-matrix TMB/Julia bridge rerun

- Command: `PATH="/Users/z3437171/.juliaup/bin:$PATH" OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 DRMTMB_JULIA_TESTS=true NOT_CRAN=true DRM_JL_PATH="/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia" JULIA_DEPOT_PATH=/private/tmp/drmTMB-julia-depot:/Users/z3437171/.julia JULIA_NUM_THREADS=4 Rscript -e 'devtools::test(filter = "julia-tweedie-relmat-sd", reporter = "summary", stop_on_failure = TRUE)'`
- Result: exit 0, 24 assertions passed, one live Julia bridge test. One non-fatal JuliaCall `LogExpFunctionsInverseFunctionsExt` warning (`loglogistic` undefined).
- Source-bound receipt: `docs/dev-log/general-sd-regression/evidence/tweedie-relmat-parity-20261023-current-v2/receipt.json`; 199 source files, both candidate HEADs, test and console hashes recorded.
- Evidence reconciliation: 19,118 candidate rows, 25 distinct linked rows, 31 receipt records. Reconciler tests: 11/11 passed.
- Scope: one synthetic Tweedie q1 related-matrix intercept point-parity fixture. No recovery distribution or calibrated-interval evidence.
- First attempt could not locate Julia; a second was interrupted early after a mistaken elapsed-time estimate. Both logs are retained separately from the final successful run.
