# Check log: Native Binomial crossed non-logit SD regression

- Command: `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-crossed-nonlogit-sd", reporter = "summary", stop_on_failure = TRUE)'`.
- Result: exit 0; 18 expectations passed, 0 failures, 0 warnings, 0 skips.
- Two crossed synthetic fits (probit and cloglog) checked convergence, both SD slope directions and broad recovery bounds, named group predictions, and binary simulation output.
- Evidence reconciliation passed: 149 linked / 19,678 candidate rows / 169 evidence records. Both new rows remain unreviewed.
- No full package test suite, live Julia bridge, or interval-coverage validation was run.
