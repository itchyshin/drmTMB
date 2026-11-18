# Native beta-binomial SD-regression smoke

Ran the existing native beta-binomial predictor-dependent random-effect SD integration test in the `codex/general-sd-regression` candidate worktree.

Command:

```sh
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 \
  Rscript -e 'devtools::test(filter = "beta-binomial-sd-integration")'
```

Result: 15 passed, 0 failed, 0 warnings, 0 skipped; 155.1 seconds. The runner reported that no live Julia tests ran. Scope is a narrow native fitting/recovery/output smoke. It provides no family-wide support evidence and no interval-coverage validation. The Julia beta-binomial SD route remains unverified, and all broader capability rows remain open.

The existing test file was unchanged. No production simulation campaign was run.
