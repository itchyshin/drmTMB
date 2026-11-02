# Native Poisson SD-regression smoke

Ran the existing ordinary Poisson and zero-inflated Poisson SD integration tests in the `codex/general-sd-regression` candidate worktree.

```sh
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 \
  Rscript -e 'devtools::test(filter = "poisson-sd-integration")'
```

Result: 58 passed, 0 failed, 0 warnings, 0 skipped; 65.9 seconds. The filter matched both `test-poisson-sd-integration.R` (43 checks, 6.2 seconds) and `test-zi-poisson-sd-integration.R` (15 checks, 59.7 seconds). No live Julia tests ran. These results apply to the tested native fixtures. They provide no claim of full family/provider support or interval-coverage validation.
