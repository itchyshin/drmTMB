# 2026-11-09 coverage D1: opt-in group-SD ADREPORT bodies in src/drmTMB.cpp

Batch D1 from the coverage plan. Tests only. No edits under `R/`, `src/`, or `.github/`.

`report_group_sd` is 0 unless `drm_control(se_group_sd = TRUE)`. The full suite already
evaluated the surrounding `if` for most families and left the two-line `ADREPORT`
body at zero hits. These tests turn the report on for small fits and check the
reported group SD against the R transform of its own log predictor:

`drm_exp_sd_logscale_guarded(drm_softclamp_log_sd(eta, tmb_data))`.

`sdreport()$value` and `obj$report()` for the same symbol can differ by about
5e-4, because they are not evaluated at the same parameter vector. Each vector
is compared with the transform of its own log predictor, at tolerance 1e-12.
The log predictor is also compared with `sd_mu_group_log_values()`,
`sd_sigma_group_log_values()`, or `sd_phylo_group_log_values()` where that
helper indexes the coefficient vector. The bivariate `sd1()` / `sd2()` layout
is the exception: `sd_phylo_group_log_values()` returned `NA` while the template
log predictor was finite, so that test checks the transform and the
intercept-only repetition (one value per response, repeated across four tips).

The Tweedie phylogenetic fits use one fixed 4-tip tree and one fixed count
vector. Other coalescent draws either failed to converge or spent tens of
seconds in the optimizer.

## Files

New tests, radix order, one file per coverage shard (`(i - 1) %% 4`):

| File | Shard | Uninstrumented time | Result |
| --- | --- | --- | --- |
| `tests/testthat/test-coverage-d1-a-group-sd.R` | 1 | 0.49s | FAIL 0, WARN 0, SKIP 0, PASS 14 |
| `tests/testthat/test-coverage-d1-b-group-sd.R` | 2 | 1.78s | FAIL 0, WARN 0, SKIP 0, PASS 70 |
| `tests/testthat/test-coverage-d1-c-structured.R` | 3 | 0.86s | FAIL 0, WARN 0, SKIP 0, PASS 50 |
| `tests/testthat/test-coverage-d1-d-structured.R` | 4 | 0.35s | FAIL 0, WARN 0, SKIP 0, PASS 18 |

They sort between `test-covariance-block-registry.R` and
`test-cran-lane-filter.R`. Four new files shift later files by 4, so existing
shard membership is unchanged. The CRAN allowlist does not name these files.

## Coverage of src/drmTMB.cpp

Baseline is the merged cobertura from the green 4-shard run
[42646500498](https://github.com/itchyshin/drmTMB/actions/runs/42646500498)
(head `16e50683`, same `src/drmTMB.cpp` as `1e0f545`). After is the union of
that baseline with `covr::package_coverage(type = "none")` on these four files
only. That local run, including the `-O0` rebuild, took 150.9s and the tests
passed inside it.

| | Lines covered | Instrumented | Percent |
| --- | ---: | ---: | ---: |
| Before | 5159 | 5344 | 96.54% |
| After | 5206 | 5344 | 97.42% |

47 previously missed lines are now hit. No other file under `src/` gained a
hit. `drm_logspace_sum` was already covered.

99% of 5344 lines is 5291 covered lines. The 138 lines that remain at zero
include about 111 that a test cannot reach without an R or C++ edit: dead
callers, formula gates, defensive `error()` bodies, and gcov lines whose true
branch is already counted. Covering the other 27 would still leave the file
under 99%. Those lines are listed as flags in the pull request, not encoded
as expectations.

## Commands

```sh
Rscript -e 'testthat::test_file("tests/testthat/test-coverage-d1-a-group-sd.R")'
Rscript -e 'testthat::test_file("tests/testthat/test-coverage-d1-b-group-sd.R")'
Rscript -e 'testthat::test_file("tests/testthat/test-coverage-d1-c-structured.R")'
Rscript -e 'testthat::test_file("tests/testthat/test-coverage-d1-d-structured.R")'
```

`covr::package_coverage()` with `type = "none"` and `testthat::test_file()`
on the same four paths. Union against the four shard cobertura files from run
42646500498.
