# 2026-11-27 — summary `ci_parm = "rho12"` (#1932)

- **Change:** When `summary(..., conf.int = TRUE, method = "wald", ci_parm = "rho12")`, attach companion `fixef:rho12:*` Wald rows to the coefficient table (parameter table still uses the direct `rho12` target).
- **Tests:** `tests/testthat/test-summary.R` (seed `271127803` repro from #1932).
- **Local:** `pkgload::load_all()` + inline test_that expectations on cloud VM (R 4.3.x, TMB installed).