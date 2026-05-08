# After Task: Bivariate Meta-Analysis Covariance Helper

## Goal

Implement the first small user-facing helper for bivariate meta-analysis:
constructing known within-study sampling covariance matrices without changing
the bivariate likelihood yet.

## Implemented

- Added `meta_vcov_bivariate()` in `R/meta-vcov.R`.
- Exported and documented the helper through roxygen2.
- Added `_pkgdown.yml` reference index entry.
- Added tests for covariance input, correlation input, independent defaults,
  and malformed inputs.
- Updated the meta-analysis vignette, distribution roadmap, and meta-analysis
  design note.
- Added a `NEWS.md` bullet.

## Mathematical Contract

The helper constructs a dense matrix for row-paired stacking:

```text
y_stack = [y1_1, y2_1, y1_2, y2_2, ..., y1_n, y2_n]'
```

For study `i`, the known sampling covariance block is:

```text
S_i =
  [v1_i,    cov12_i;
   cov12_i, v2_i]
```

If users provide a known sampling correlation, the helper uses:

```text
cov12_i = cor12_i * sqrt(v1_i * v2_i)
```

The helper checks that each block is positive semidefinite by requiring
`abs(cov12_i) <= sqrt(v1_i * v2_i)`.

## Files Changed

- `R/meta-vcov.R`
- `tests/testthat/test-meta-vcov.R`
- `man/meta_vcov_bivariate.Rd`
- `NAMESPACE`
- `_pkgdown.yml`
- `NEWS.md`
- `vignettes/meta-analysis.Rmd`
- `docs/design/06-distribution-roadmap.md`
- `docs/design/08-meta-analysis.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-08-bivariate-meta-vcov-helper.md`

## Checks Run

- `Rscript -e "devtools::load_all(); V <- meta_vcov_bivariate(c(0.04, 0.03), c(0.05, 0.02), cor12 = c(0.4, 0.2)); stopifnot(all(dim(V) == c(4, 4))); print(V)"`
- `Rscript -e "testthat::test_file('tests/testthat/test-meta-vcov.R')"` failed because the direct test-file call did not load the package namespace.
- `Rscript -e "devtools::test(filter = 'meta-vcov')"`: 17 passed.
- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test()"`: 589 passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- `Rscript -e "pkgdown::build_site()"`: succeeded.
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`: 0 errors, 0 warnings, 0 notes.
- `git diff --check`: clean.
- `air format .`: unavailable on this machine.

## Tests Of The Tests

- The first `devtools::test(filter = 'meta-vcov')` run failed because
  validation stripped study names before row and column names were assigned.
  The code was fixed to preserve vector names through validation.
- Tests include failure paths for unequal vector lengths, missing variances,
  negative variances, simultaneous `cov12` and `cor12`, invalid vector length,
  correlations outside `[-1, 1]`, and non-positive-semidefinite blocks.
- The generated pkgdown reference page was inspected after build; a first
  version rendered text code fences as empty boxes, so the roxygen details were
  rewritten as plain mathematical prose and regenerated.

## Consistency Audit

- No `meta_gaussian()` family was introduced.
- No `tau ~` grammar was introduced.
- The helper constructs known sampling covariance `V`; it does not estimate
  residual or between-study covariance.
- The design docs and vignette state that bivariate fitting with known `V`
  remains the next likelihood task.
- The generated pkgdown reference index includes `meta_vcov_bivariate()`.

## What Did Not Go Smoothly

- Direct `testthat::test_file()` was the wrong invocation because it does not
  load the package namespace in this workflow.
- The first implementation accidentally dropped study names during validation.
- Roxygen text code fences rendered poorly in pkgdown for this reference page.
- `air` is still not installed, so formatting could not be run.

## Team Learning

- Boole: helper names and matrix stacking must be explicit before the formula
  parser accepts bivariate known `V`.
- Noether: preserving the `S_i` block equation in docs made it clear that this
  is known sampling covariance, not fitted residual `rho12`.
- Fisher: the next simulation target must separate known sampling correlation
  in `V` from fitted residual or between-study `rho12`.
- Rose: generated documentation needs visual inspection, not only successful
  `R CMD check`.

## Known Limitations

- `meta_vcov_bivariate()` currently returns a dense matrix only.
- Bivariate `drmTMB()` fits with `meta_known_V(V = V)` are still rejected until
  the bivariate known-`V` likelihood is implemented and tested.
- Missing bivariate outcomes remain a later design decision.
- Unknown within-study correlations should be explored by sensitivity analysis,
  not silently estimated.

## Next Actions

- Implement a bivariate Gaussian known-`V` likelihood for complete row-paired
  bivariate responses.
- Add simulation recovery tests where known sampling correlation and residual
  `rho12` are distinct.
- Decide whether to add a small sensitivity helper for unknown within-study
  correlations.
