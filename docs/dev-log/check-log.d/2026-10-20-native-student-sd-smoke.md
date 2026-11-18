# Native Student SD-regression smoke

Ran the existing Student predictor-dependent random-effect SD integration test in the `codex/general-sd-regression` candidate worktree.

```sh
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 \
  Rscript -e 'devtools::test(filter = "^student-sd-integration$")'
```

Result: 30 passed, 0 failed, 0 warnings, 0 skipped; 46.2 seconds. No live Julia tests ran. This is focused native evidence for the tested fixture, not full family/provider support and not interval-coverage validation.
