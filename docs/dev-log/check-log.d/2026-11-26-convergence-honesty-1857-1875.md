# Check log — convergence honesty (#1857, #1875)

**Slice:** Classify student all-zero `se = FALSE` as degenerate; warn on `logLik`/`AIC`/`BIC` when `convergence_status()` is not `"converged"`; warn on infinite `confint` endpoints; residual `sigma` lower clamp → `boundary` when not already degenerate.

**Tests:** `tests/testthat/test-convergence-honesty-1857-1875.R` (11 assertions); `tests/testthat/test-mle-existence.R` (regression).

**Command:**

```sh
Rscript -e 'library(testthat); library(drmTMB); test_file("tests/testthat/test-convergence-honesty-1857-1875.R"); test_file("tests/testthat/test-mle-existence.R")'
```

**Outcome:** PASS (2026-11-26, cloud agent).