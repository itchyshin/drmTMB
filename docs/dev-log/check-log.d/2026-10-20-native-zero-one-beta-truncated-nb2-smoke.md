# Native zero-one Beta and truncated NB2 SD smokes

Ran existing predictor-dependent random-effect SD integration tests in the `codex/general-sd-regression` candidate worktree.

```sh
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 \
  Rscript -e 'devtools::test(filter = "^zero-one-beta-sd-integration$")'
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 \
  Rscript -e 'devtools::test(filter = "^truncated-nbinom2-sd-integration$")'
```

Results: zero-one Beta, 13 passed in 188.0 seconds; truncated NB2, 10 passed in 65.4 seconds. Both had 0 failures, warnings, and skips. Total runtime was 253.4 seconds, within the five-minute estimate. No live Julia tests ran. These are focused native fixture checks, not complete family support or interval-coverage validation.
