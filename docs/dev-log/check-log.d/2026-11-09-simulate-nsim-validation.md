# Check log: validate `nsim` in `simulate.drmTMB()` (#1696)

## Change

- `R/methods.R`: refuse invalid `nsim` with `cli::cli_abort()`, matching
  `simulate.drmTMB_julia()` and coercing valid input with `as.integer()`.
- `tests/testthat/test-fix-1696-simulate-nsim.R`: regression for invalid and
  valid `nsim`.

## Evidence

```text
testthat::test_file("tests/testthat/test-fix-1696-simulate-nsim.R")
```

Pre-fix (main): failure on `nsim = 0` with base-R `'names' attribute` error;
`nsim = 1.5` returned one column (silent truncation).

Post-fix: file passes; invalid `nsim` raises `rlang_error` with
`one positive whole number`; `nsim = 1` and `nsim = 3` unchanged.
