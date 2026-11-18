# Native Beta SD-regression smoke

Ran the existing Beta predictor-dependent random-effect SD integration test in the `codex/general-sd-regression` candidate worktree.

```sh
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 \
  Rscript -e 'devtools::test(filter = "^beta-sd-integration$")'
```

Result: 13 passed, 0 failed, 0 warnings, 0 skipped; 17.6 seconds. No live Julia tests ran. This is focused native evidence for the tested fixture, not full family/provider support and not interval-coverage validation.
