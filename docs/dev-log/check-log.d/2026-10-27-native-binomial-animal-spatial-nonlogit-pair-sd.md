# Check log: Native Binomial animal plus spatial non-logit pair

- Test command: `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-animal-spatial-nonlogit-pair-sd", reporter = "summary", stop_on_failure = TRUE)'`.
- Initial harness run stopped at `expect_lt(..., info=...)`, which is unsupported by the installed testthat. No model assertion failed in that run.
- Corrected run: exit 0; 16 expectations passed, 0 failures, 0 warnings, 0 skips.
- Probit and cloglog synthetic fits checked convergence, both SD slope directions and broad recovery bounds, named provider SD predictions, and binary simulation output.
- Evidence reconciliation passed: 147 linked / 19,678 candidate rows / 167 evidence records. The two rows remain unreviewed.
- No full package suite, live Julia bridge, or interval-coverage validation was run.
