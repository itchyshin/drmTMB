# Native Binomial animal plus related-matrix Q under probit and cloglog

Command:

```sh
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-animal-relmat-q-nonlogit-sd", reporter = "summary", stop_on_failure = TRUE)'
```

Result: exit 0; 16 focused expectations passed. For each of probit and cloglog, same-data native fits using animal A plus related-matrix K or Q matched in likelihood, SD coefficients, and label-aligned predictions.

Evidence reconciliation passed with 19,678 candidate rows, 127 linked rows, 19,551 unlinked rows, and 149 receipt records. Source manifest and console output are in `docs/dev-log/general-sd-regression/evidence/native-binomial-animal-relmat-q-nonlogit-20261027/`. No interval-coverage or Julia-parity claim.
