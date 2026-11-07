# Structured random-effect SD target identity

**Lane:** `codex/general-sd-regression`  
**Source pin:** `425bee81572c625a634b2b083050c5c57c1dc1f1`  
**Scope:** shared SD-target identity resolution only; no structured likelihood admission.

## Checks

- `bash ~/shinichi-brain/tools/lane_preflight.sh "$PWD" --file R/random-effect-targets.R`: no missing path work reported; current lane lease covers the source.
- `bash ~/shinichi-brain/tools/lane_preflight.sh "$PWD" --file tests/testthat/test-structured-sd-targets.R`: new test path, no other-ref work reported.
- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "random-effect-targets|structured-sd-targets|parse-formula", reporter = "summary")'`: passed; parser, ordinary-target resolver, and structured-target resolver tests completed with no failures.
- `git diff --check -- R/random-effect-targets.R tests/testthat/test-structured-sd-targets.R`: passed.

The test-first run failed on all four initial structured-target cases with the previous structured-resolver refusal. After implementation, the expanded tests pass. They assert explicit level selection, ambiguity between ordinary and structured targets, ambiguity between two structured providers, and an actionable no-match error. The fixtures use the package's `provider = "phylo", level = "phylogenetic"` metadata.

Independent architecture review found that the initial fixture used `provider = "phylogenetic"`, unlike package metadata. The fixture now uses `provider = "phylo"`; an additional test verifies ambiguity between `phylo` and `spatial` candidates and resolution by level. The reviewer found no path by which this identity resolver admits structured fitting; likelihood admission remains with callers.

No fitting or simulation was run. This evidence does not establish a supported structured SD model, likelihood correctness, recovery, uncertainty calibration, or Julia parity.
