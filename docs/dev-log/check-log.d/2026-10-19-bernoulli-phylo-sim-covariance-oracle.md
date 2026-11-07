# Bernoulli phylogenetic SD simulation covariance oracle

**Lane:** `codex:general-sd-regression-phylo-sim-test`  
**Change:** strengthen the native phylogenetic SD simulation test with a non-unit-height tree and an inverse-precision covariance oracle.

**Checks:**

- `NOT_CRAN=true OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MAKEFLAGS=-j1 R_PROFILE_USER=/dev/null Rscript -e 'devtools::test(filter = "binomial-phylo-sd-simulation", reporter = "summary")'` — PASS; 11 expectations, no failures or skips.
- `git diff --check` — PASS.

The check establishes that the fitted augmented precision implies the normalized tip covariance at tree height 2.5 and differs from the raw-height covariance. It does not establish Julia parity, interval calibration, or broader structured-effect support.
