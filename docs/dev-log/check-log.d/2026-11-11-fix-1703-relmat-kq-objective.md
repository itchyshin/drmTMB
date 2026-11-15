# Check log: relmat K versus Q objective at a fixed parameter vector (#1703)

**Date:** 2026-11-11
**Branch:** `cursor/fix-1703-relmat-kq-objective-7133`

## Change

Shinichi chose option 1 on 10 Nov 2026: compare the TMB objective at one
fixed parameter vector. Option 2, making the maximised log-likelihoods agree,
is not this change. The 1e-5 tolerance is unchanged. No likelihood,
optimizer, or formula code moved. The capability-ledger watchlist
(`R/drmTMB.R`, `R/methods.R`, `src/drmTMB.cpp`,
`tests/testthat/test-zero-one-beta.R`,
`tools/run-lane-c-c17c1-c14-model15-compatibility.R`) was not edited, and the
ledger was not re-recorded.

## Reproduction before the assertion change

OpenBLAS 0.3.26, R 4.3.3, TMB 1.9.10, drmTMB 0.8.1 at `3f45ade61`.
The partial q4 test in `tests/testthat/test-animal-relmat-gaussian.R` failed:

- `logLik(relmat(K))` = -75.9816, `nlminb` relative convergence, max |gradient| 3.7e-7, with `theta_phylo` out to about 1382
- `logLik(relmat(Q = solve(K)))` = -75.98487, BFGS fallback after `nlminb` false convergence
- absolute gap 0.00326555, outside tolerance 1e-5

At one shared parameter vector the objectives already agreed: difference 0 at an interior vector (`u` at 0, moderate `theta_phylo`), and about 2e-8 at the K fit's reported parameters. The precision matrices from `K` and `solve(K)` differ by at most 4e-16.

## Verification

```sh
R_LIBS_USER=~/R/library Rscript -e '
.libPaths(c(path.expand("~/R/library"), .libPaths()))
library(drmTMB)
testthat::test_file(
  "tests/testthat/test-fix-1703-relmat-kq-objective.R",
  reporter = "summary"
)
testthat::test_file(
  "tests/testthat/test-animal-relmat-gaussian.R",
  desc = "bivariate Gaussian known-matrix one-slope location blocks expose partial q4 members",
  reporter = "summary"
)
'
```

Post-fix, both files passed. The new file reported six passing expectations. The partial q4 test, which failed on the maximised log-likelihood before this change, passed after the shared-parameter comparison replaced that assertion.
