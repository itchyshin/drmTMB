# After Task: Structured Slope Evidence

## 1. Goal

Bank SR041-SR050 for structured random-effect slope status across `phylo()`,
coordinate `spatial()`, `animal()`, and `relmat()`.

## 2. Implemented

SR041-SR050 are banked in
`docs/dev-log/dashboard/structured-re-balance-100-slices.tsv`.

`docs/design/210-structured-slope-status.md` records the boundary: univariate
Gaussian `mu` supports one independent structured numeric slope, while labelled
or correlated structured-slope covariance, bivariate structured slopes,
residual-scale structured slopes, multiple structured slopes, non-Gaussian
structured slopes, and structured `rho12` remain planned.

## 3. Decisions and Rejected Alternatives

I banked only independent one-slope support. I did not treat `q = 2` in the
internal structured object as a correlated slope covariance block; the tests
expect `fit$corpars` to be empty for these one-slope structured fits.

## 4. Files Created or Changed

- `docs/design/210-structured-slope-status.md`
- `docs/dev-log/dashboard/structured-re-balance-100-slices.tsv`
- `docs/dev-log/after-task/2026-06-22-structured-re-slopes.md`
- `docs/dev-log/check-log.md`

## 5. Checks Run

The focused fitted-model tests were run in the SR011-SR020 tranche and include
the structured slope rows:

```sh
NOT_CRAN=true Rscript -e 'devtools::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-phylo-gaussian.R"); testthat::test_file("tests/testthat/test-spatial-gaussian.R"); testthat::test_file("tests/testthat/test-animal-relmat-gaussian.R"); testthat::test_file("tests/testthat/test-phylo-interaction.R"); testthat::test_file("tests/testthat/test-count-structured-mu.R")'
```

Outcomes:

- `test-phylo-gaussian.R`: 269 pass.
- `test-spatial-gaussian.R`: 144 pass.
- `test-animal-relmat-gaussian.R`: 156 pass.
- `test-phylo-interaction.R`: 55 pass.
- `test-count-structured-mu.R`: 124 pass.
- The focused run had zero failures, warnings, or skips.

Mission-control validation and `git diff --check` are rerun in the closing gate
for this combined structured-balance update.

## 6. Tests of the Tests

The slope tests fit actual models and assert convergence, structured type,
coefficient names, independent SD names, empty correlation-parameter lists,
random-effect extraction, direct profile-target rows, diagnostics, prediction
contributions, and labelled-slope rejection messages.

## 7. Issue Ledger

No GitHub issue was touched. This is local evidence banking.

## 8. Consistency Audit

SR041-SR050 do not promote correlated structured slopes, bivariate structured
slope covariance, residual-scale structured slopes, non-Gaussian structured
slopes, native REML, AI-REML, bridge parity, public optimizer controls, or
coverage.

## 9. What Did Not Go Smoothly

The term "q1 slope" is slightly misleading because a one-slope structured term
has two coefficient fields internally. The important user-facing boundary is
independent intercept and slope fields with no intercept-slope correlation.

## 10. Known Limitations and Next Actions

SR051 starts the native REML tranche. Correlated structured slopes need a
separate coefficient-aware covariance design and simulation recovery before any
support claim.

## 11. Team Learning

For structured slopes, the presence of an intercept and a slope in one term
must not be read as a covariance block. We need to say "independent one-slope
fields" whenever reporting this surface.
