# Native ordinal and Tweedie SD-regression smokes

Ran the existing cumulative-logit and Tweedie predictor-dependent random-effect SD integration tests in the `codex/general-sd-regression` candidate worktree.

```sh
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 \
  Rscript -e 'devtools::test(filter = "^cumulative-logit-sd-integration$")'
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 \
  Rscript -e 'devtools::test(filter = "^tweedie-sd-integration$")'
```

Results: cumulative-logit, 10 passed in 34.0 seconds; Tweedie, 14 passed in 10.4 seconds. Both had 0 failures, warnings, and skips. No live Julia tests ran. These are focused native fixture checks, not complete family support or interval-coverage validation.
