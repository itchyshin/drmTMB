# Native Binomial animal A-inverse plus relmat K

Command:

```sh
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-animal-ainv-relmat-sd", reporter = "summary", stop_on_failure = TRUE)'
```

Result: exit 0; seven expectations passed without warnings. The animal A-inverse plus relmat K logit fit matched the A-covariance fit in likelihood, SD coefficients, and named predictions.

Evidence reconciliation passed with 19,678 candidate rows, 112 linked rows, 19,566 unlinked rows, and 134 records. Source hashes and console output are in `docs/dev-log/general-sd-regression/evidence/native-binomial-animal-ainv-relmat-sd-20261027/`. No interval-coverage or Julia-parity claim.
