# Native Binomial ordinary plus phylo probit/cloglog SDs

Command:

```sh
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-ordinary-phylo-nonlogit-sd", reporter = "summary", stop_on_failure = TRUE)'
```

Result: exit 0; 20 expectations passed without warnings for ordinary iid plus phylogenetic q1 intercepts under probit and cloglog. Checks cover both SD-slope recovery bounds, coefficient names, predictions, convergence, and effect labels.

Evidence reconciliation passed with 19,678 candidate rows, 111 linked rows, 19,567 unlinked rows, and 133 records. Source hashes and console output are in `docs/dev-log/general-sd-regression/evidence/native-binomial-ordinary-phylo-nonlogit-sd-20261027/`. No interval-coverage or Julia-parity claim.
