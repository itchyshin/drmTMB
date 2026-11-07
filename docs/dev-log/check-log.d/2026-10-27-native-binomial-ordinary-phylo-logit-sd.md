# Native Binomial ordinary plus phylogenetic logit SDs

Command:

```sh
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-ordinary-phylo-sd", reporter = "summary", stop_on_failure = TRUE)'
```

Result: exit 0; 18 expectations passed without warnings. The existing test covers both SD-slope recovery checks, simulation, save/reload predictions, and constant-SD equivalence for ordinary iid plus phylogenetic q1 intercepts.

Evidence reconciliation passed with 19,678 candidate rows, 114 linked rows, 19,564 unlinked rows, and 136 records. Source hashes and console output are in `docs/dev-log/general-sd-regression/evidence/native-binomial-ordinary-phylo-logit-sd-20261027/`. No interval-coverage or Julia-parity claim.
