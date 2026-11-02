# Native Binomial animal-intercept SD inputs

Command:

```sh
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-animal-(sd-regression|ainv-sd-regression|pedigree-sd-regression)", reporter = "summary", stop_on_failure = TRUE)'
```

Result: exit 0. The three target native Binomial logit animal-intercept test files passed 33 expectations. An adjacent Beta-binomial test also passed 21 expectations. Two Julia bridge checks matched by the broad filter were skipped because Julia engine paths were not configured and are not counted as live Julia evidence.

Evidence reconciliation passed with 19,678 candidate rows, 125 linked rows, 19,553 unlinked rows, and 147 receipt records. Hashes and console output are in `docs/dev-log/general-sd-regression/evidence/native-binomial-animal-intercept-iid-kernels-20261027/`.
