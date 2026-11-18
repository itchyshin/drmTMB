# Native Gamma and NB2 SD-regression smoke

Ran the existing Gamma and NB2 predictor-dependent random-effect SD integration tests in the `codex/general-sd-regression` candidate worktree.

```sh
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 \
  Rscript -e 'devtools::test(filter = "^(gamma|nbinom2)-sd-integration$")'
```

Result: 75 passed, 0 failed, 0 warnings, 0 skipped; 148.9 seconds. The filter ran Gamma (23 checks, 7.4 seconds) and NB2 (52 checks, 141.5 seconds). No live Julia tests ran. This is focused native evidence for the tested fixtures, not full family/provider support and not interval-coverage validation.
