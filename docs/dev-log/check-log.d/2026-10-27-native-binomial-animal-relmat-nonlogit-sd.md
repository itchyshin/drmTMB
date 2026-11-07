# Native Binomial animal plus relmat probit/cloglog SD pair

Command:

```sh
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-animal-relmat-nonlogit-sd", reporter = "summary", stop_on_failure = TRUE)'
```

Result: exit 0; 14 focused expectations passed without warnings for animal A covariance plus relmat K covariance under probit and cloglog. Checks include convergence, both SD-slope recovery bounds, coefficient target names, and group-named predictions.

Evidence reconciliation passed with 19,678 candidate rows, 104 linked rows, 19,574 unlinked rows, and 126 evidence records. Source hashes and console output are retained in `docs/dev-log/general-sd-regression/evidence/native-binomial-animal-relmat-nonlogit-sd-20261027/`. No interval-coverage or Julia-parity claim.
