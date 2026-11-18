# Native Binomial ordinary and animal SD input equivalence

Command:

```sh
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-ordinary-animal-kernel-equivalence-sd", reporter = "summary", stop_on_failure = TRUE)'
```

Result: exit 0; 11 focused expectations passed. Native Binomial logit fits with ordinary iid plus animal SD regression matched between A-inverse precision and pedigree inputs versus equivalent A covariance in likelihood, SD coefficients, and animal-name-aligned predictions.

Evidence reconciliation passed with 19,678 candidate rows, 116 linked rows, 19,562 unlinked rows, and 138 receipt records. Source manifest and test output are in `docs/dev-log/general-sd-regression/evidence/native-binomial-ordinary-animal-kernel-equivalence-sd-20261027/`. No interval-coverage or Julia-parity claim.
