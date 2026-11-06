# Native Binomial phylo plus animal A-inverse

Command:

```sh
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-phylo-animal-ainv-sd", reporter = "summary", stop_on_failure = TRUE)'
```

Result: exit 0; seven expectations passed without warnings. The phylo plus animal A-inverse logit fit matched the animal A-covariance fit in likelihood, SD coefficients, and animal-named predictions.

Evidence reconciliation passed with 19,678 candidate rows, 108 linked rows, 19,570 unlinked rows, and 130 records. Source hashes and console output are in `docs/dev-log/general-sd-regression/evidence/native-binomial-phylo-animal-ainv-sd-20261027/`. No interval-coverage or Julia-parity claim.
