# Native Bernoulli SD integration test receipt

- Source branch: `codex/general-sd-regression`
- Source HEAD at execution: `425bee81572c625a634b2b083050c5c57c1dc1f1`
- Candidate relation to `origin/main`: 6 commits ahead, 102 behind at execution.
- Command:
  `OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 MAKEFLAGS=-j1 Rscript -e 'devtools::test(filter = "binomial-sd-integration")'`
- Result: 381 expectations passed; 0 failures, warnings, or skips; 300.8 seconds.
- Matched files: `tests/testthat/test-binomial-sd-integration.R` and `tests/testthat/test-beta-binomial-sd-integration.R` (the latter matched the filter by substring).
- The Binomial file covered its focused synthetic SD integration tests, including recovery, likelihood oracles, public outputs, simulation, profiles, bootstrap smoke tests, save/reload, and constant-SD equivalence. The adjacent Beta-binomial file contributed 15 checks.
- The test output reported no live Julia bridge tests in this configuration. This receipt establishes native candidate test execution only; it does not establish Julia parity, source integration on current `main`, broad capability support, or interval calibration.

SHA-256 at execution:

| File | SHA-256 |
|---|---|
| `R/drmTMB.R` | `a8a99c9ea3bcc8af1e824f4a6e71cd62f5d294c9795f5ea88b4ef5713fa80e2b` |
| `src/drmTMB.cpp` | `e42e51c3050bf3c11e000df7966da9ca0db630e5f193ae35f20bc0b40edd8c79` |
| `tests/testthat/test-binomial-sd-integration.R` | `afc4a14d3ec43a1fdae3405384f9fa7262b18b35da7b1668a0373100bfb8bfe9` |
| `tests/testthat/test-beta-binomial-sd-integration.R` | `ad727c9bb9e765f6f5063fafb0f7a5b525dae8bfbe517a70e33d303e99d51cc4` |
| `tests/testthat/helper-binomial-sd-regression.R` | `acd2153d99bc46d4094cbf5d9a1abd05febd00cb9e9e2a3619d3325925df9018` |
