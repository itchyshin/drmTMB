# Check log: LogNormal sigma-SD bootstrap workflow

The focused LogNormal `sigma` random-intercept SD test passed after adding a small fixed-seed bootstrap-refit check to the existing informative profile fixture. All three requested refits converged, retained the target label, and contributed draws.

Command:

```sh
NOT_CRAN=true Rscript -e 'devtools::load_all(".", quiet = TRUE); testthat::test_file("tests/testthat/test-lognormal-sigma-sd-regression.R", desc = "lognormal sigma SD slope profile works on an informative smoke fit")'
```

Result: `FAIL 0 | WARN 0 | SKIP 0 | PASS 20`. Julia was not invoked. This test verifies bootstrap dispatch and refit diagnostics for one native LogNormal `sigma` SD slope; it does not evaluate interval coverage.

Source binding:

| Item | Value |
|---|---|
| Native candidate HEAD | `425bee81572c625a634b2b083050c5c57c1dc1f1` |
| Test file SHA-256 | `da0bbe174cca18e7a059a278ef5a048509bcb0f860215e2ef8ff07d7f5128fcd` |

No production code changed. Both native and paired Julia worktrees remain dirty candidate sources.
