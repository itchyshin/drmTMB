# Native Binomial animal plus relmat Q precision

Command:

```sh
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-animal-relmat-q-precision-sd", reporter = "summary", stop_on_failure = TRUE)'
```

Result: exit 0; eight expectations passed without warnings. Animal A-covariance plus relmat Q-precision matched the K-covariance fit in likelihood, SD coefficients, and name-aligned predictions.

Evidence reconciliation passed with 19,678 candidate rows, 105 linked rows, 19,573 unlinked rows, and 127 records. Source hashes and console output are retained in `docs/dev-log/general-sd-regression/evidence/native-binomial-animal-relmat-q-sd-20261027/`. No interval-coverage or Julia-parity claim.
