# After Task: Structured Native ML q2 Evidence

## 1. Goal

Bank SR021-SR030 for native TMB ML q2 structured random-effect status. The
goal was to separate bivariate location q2 support from scale-side q2 decisions
and from q4 location-scale support.

## 2. Implemented

SR021-SR030 are banked in
`docs/dev-log/dashboard/structured-re-balance-100-slices.tsv`.

`docs/design/208-structured-q2-native-ml-status.md` records the q2 boundary:
`phylo()`, coordinate `spatial()`, `animal()`, and `relmat()` have bivariate
location q2 fit/extractor evidence; `phylo()` also has a q2-plus-q2
block-diagonal fallback for separate mean-mean and scale-scale blocks; pure
scale-only q2 for `spatial()`, `animal()`, and `relmat()` remains rejected as a
partial location-scale block.

## 3. Decisions and Rejected Alternatives

I did not infer scale-side q2 support from q4 tests. q4 all-four support has
scale-scale rows, but it is a different formula contract from a standalone
`sigma1`/`sigma2` q2 block.

I banked the scale-only q2 rows as decisions rather than support claims.

## 4. Files Created or Changed

- `docs/design/208-structured-q2-native-ml-status.md`
- `docs/dev-log/dashboard/structured-re-balance-100-slices.tsv`
- `docs/dev-log/after-task/2026-06-22-structured-re-native-ml-q2.md`
- `docs/dev-log/check-log.md`

## 5. Checks Run

The focused fitted-model tests were run in the SR011-SR020 tranche and also
cover the q2 location rows:

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

A direct scale-only q2 smoke with named `coords` and `Q` objects returned:

```text
spatial  error  Partial spatial location-scale blocks are not implemented.
animal   error  Partial animal-model location-scale blocks are not implemented.
relmat   error  Partial relmat location-scale blocks are not implemented.
```

Mission-control validation and `git diff --check` are rerun in the closing gate
for this combined structured-balance update.

## 6. Tests of the Tests

The q2 location tests check fitted bivariate models, named SD/correlation
parameters, `corpairs()`, `summary(fit)$covariance`, profile-target identities,
diagnostics, prediction contributions, and dense likelihood comparisons where
available. The direct scale-only smoke checked parser/fit rejection with actual
bivariate formulas, not just a text scan.

## 7. Issue Ledger

No GitHub issue was touched. This is local evidence banking.

## 8. Consistency Audit

SR021-SR030 stay inside native TMB ML q2 evidence and decision scope. They do
not promote q4, native REML, AI-REML, R-to-Julia bridge parity, public
optimizer controls, or interval coverage.

## 9. What Did Not Go Smoothly

The first direct scale-only smoke used expressions like `sim$coords` inside
formula markers. The grammar requires object names, so I reran the smoke with
named `coords` and `Q` objects before recording the result.

## 10. Known Limitations and Next Actions

SR031 starts the Native ML q4 tranche. q2 coverage remains unclaimed. Spatial,
animal, and `relmat()` scale endpoints currently need the all-four q4 route if
they are to enter a structured bivariate covariance block.

## 11. Team Learning

For structured covariance dimensions, q2 and q4 are not interchangeable. A q4
test can prove q4 point/extractor behaviour while still leaving the standalone
scale-only q2 route intentionally closed.
