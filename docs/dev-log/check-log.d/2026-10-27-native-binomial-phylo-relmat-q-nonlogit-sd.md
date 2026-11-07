# Native Binomial phylo plus relmat probit/cloglog Q inputs

Command:

```sh
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-phylo-relmat-q-nonlogit-sd", reporter = "summary", stop_on_failure = TRUE)'
```

Result: exit 0; 14 expectations passed without warnings. Probit and cloglog phylo plus relmat fits matched between K covariance and Q precision in likelihood, SD coefficients, and population-named predictions.

Evidence reconciliation passed with 19,678 candidate rows, 107 linked rows, 19,571 unlinked rows, and 129 records. Source hashes and output are in `docs/dev-log/general-sd-regression/evidence/native-binomial-phylo-relmat-q-nonlogit-sd-20261027/`. No interval-coverage or Julia-parity claim.
