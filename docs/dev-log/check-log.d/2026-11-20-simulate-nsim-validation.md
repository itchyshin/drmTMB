# Check log: validate `nsim` in `simulate.drmTMB()` (#1696)

## Change

- `R/methods.R`: refuse invalid `nsim` with `cli::cli_abort()`, coercing valid
  input with `as.integer()`.
- `tests/testthat/test-fix-1696-simulate-nsim.R`: regression for invalid and
  valid `nsim`.

## Evidence

```text
export R_LIBS_USER=/home/ubuntu/R/library
Rscript -e 'pkgload::load_all(".'); testthat::test_file("tests/testthat/test-fix-1696-simulate-nsim.R")'
```

Pre-fix (main): `nsim = 0` leaks base-R `'names' attribute` error; `nsim = 1.5`
silently truncates to one column.

Post-fix: invalid `nsim` raises `rlang_error` with `one positive whole number`;
`nsim = 1` and `nsim = 3` unchanged.