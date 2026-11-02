# Native Binomial phylo plus animal pedigree

Command:

```sh
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-phylo-animal-pedigree-sd", reporter = "summary", stop_on_failure = TRUE)'
```

Result: exit 0; seven expectations passed without warnings. The phylo plus animal pedigree logit fit matched the A-covariance fit in likelihood, SD coefficients, and animal-named predictions.

Evidence reconciliation passed with 19,678 candidate rows, 109 linked rows, 19,569 unlinked rows, and 131 records. Source hashes and output are in `docs/dev-log/general-sd-regression/evidence/native-binomial-phylo-animal-pedigree-sd-20261027/`. No interval-coverage or Julia-parity claim.
