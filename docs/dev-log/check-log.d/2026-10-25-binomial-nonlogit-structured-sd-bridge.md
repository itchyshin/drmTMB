# Check log: non-logit Binomial structured SD bridge

Final focused checks on 2026-10-26:

- Fit-free R tests for `test-julia-binomial-nonlogit-structured-sd-bridge.R`, `test-julia-binomial-relmat-sd-parity.R`, and `test-julia-binomial-phylo-sd.R` passed. The opt-in live tests were skipped in this run.
- Live Julia bridge command:

  ```sh
  DRMTMB_JULIA_TESTS=true DRMODELS_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' JULIA_HOME='/Users/z3437171/.juliaup/bin' JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=4 Rscript -e 'devtools::load_all(); testthat::test_file("tests/testthat/test-julia-binomial-nonlogit-structured-sd-bridge.R", reporter = "summary")'
  ```

  Result: passed; two live test cases ran through JuliaCall/Julia 1.10.0, covering probit and cloglog animal-slope and relmat-intercept structured SD routes. The cases check convergence, SD coefficient recovery, prediction consistency, and native/Julia log-likelihood agreement. This is focused point evidence, not interval calibration.
- `git diff --check -- R/julia-bridge.R tests/testthat/test-julia-binomial-nonlogit-structured-sd-bridge.R` passed.
- Final SHA-256: `R/julia-bridge.R` `bfbf785014bfc1228ae94795e254f9b8237305f8c7fdfa90180b90ad200e5925`; test file `860a4bee1be5e79a4b1f5a1120ffdb5c6a646dcf72555bf08ed8f6a7c8637431`.

The fit-free neighbor run caught and prompted a compatibility fix: callers omitting the optional `link` argument now retain the previous default behavior instead of hitting a zero-length conditional. The final live bridge run passed after that fix.
