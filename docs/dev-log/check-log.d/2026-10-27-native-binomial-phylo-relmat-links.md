# Native Binomial phylo plus relmat link expansion

Command:

```sh
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-phylo-relmat-sd", reporter = "summary", stop_on_failure = TRUE)'
```

Result: exit 0; 24 expectations passed without warnings. Existing logit checks retain K/Q equivalence; new probit and complementary-log-log fits use K covariance and check convergence, both SD-slope recovery bounds, coefficient targets, and named predictions.

Evidence reconciliation passed with 19,678 candidate rows, 102 linked rows, 19,576 unlinked rows, and 124 records. Source hashes and console output are in `docs/dev-log/general-sd-regression/evidence/native-binomial-phylo-relmat-sd-20261027/`. No interval-coverage or Julia-parity claim.
