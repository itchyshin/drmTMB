# Native Binomial phylogenetic and relatedness SD pair

Command:

```sh
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-phylo-relmat-sd", reporter = "summary", stop_on_failure = TRUE)'
```

Result: exit 0; 12 focused expectations passed with no failures or warnings. The test covers convergence, point recovery of both SD slopes, target names, group-named predictions, and structured-effect labels for the native q1 phylo-tree plus relmat K-covariance Binomial logit pair.

The red run reproduced the builder refusal before implementation. After admission, the focused test passed. Evidence reconciliation reports 19,678 candidate rows, 97 linked rows, 19,581 unlinked rows, and 119 evidence records. This is one-seed point-recovery evidence only; it does not establish Julia parity or interval coverage. See `docs/dev-log/general-sd-regression/evidence/native-binomial-phylo-relmat-sd-20261027/`.
