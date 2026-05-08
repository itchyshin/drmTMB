# After Task: Dense Full-V Plus Phylogenetic And Study Comparators

## Goal

Check that dense known sampling covariance, intercept-only phylogenetic
location effects, and ordinary study random intercepts compose correctly in
Gaussian meta-analysis models.

## Implemented

Added a test in `tests/testthat/test-phylo-gaussian.R` for:

```r
drmTMB(
  bf(
    yi ~ x + meta_known_V(V = V) + phylo(1 | species, tree = tree),
    sigma ~ 1
  ),
  family = gaussian(),
  data = dat
)
```

The first test uses a dense full known covariance matrix `V`, not only a
diagonal variance vector. A second test adds an ordinary `(1 | study)` random
intercept to the same known-`V` plus phylogenetic model.

## Mathematical Contract

For the fitted parameter values, the marginal covariance should be:

```text
Sigma = V_known + sigma^2 I + sd_phylo^2 A_obs
```

where `V_known` is the known sampling covariance, `sigma` is the fitted
residual heterogeneity SD, and `A_obs` is the phylogenetic covariance matrix
indexed to the observed species rows.

The test compares the TMB/Laplace objective to an independent dense Gaussian
negative log likelihood using that covariance.

With a study random intercept, the comparator adds the ordinary study block:

```text
Sigma = V_known + sigma^2 I + sd_study^2 J_study + sd_phylo^2 A_obs
```

where `J_study[i, j] = 1` when rows `i` and `j` share the same study and 0
otherwise.

## Files Changed

- `tests/testthat/test-phylo-gaussian.R`
- `docs/dev-log/check-log.md`

## Checks Run

- `Rscript -e "devtools::test(filter = 'phylo-gaussian')"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

## Tests Of The Tests

These are tests-of-the-tests: they compare fitted objectives to independent
dense marginal likelihood calculations. They exercise covariance composition
that was not covered by the previous diagonal-`V` phylogenetic meta-analysis
comparator.

## Consistency Audit

- No user-facing syntax changed.
- No roxygen or pkgdown navigation changed.
- The test supports the current docs claim that `meta_known_V(V = V)` can be
  combined with intercept-only `phylo(1 | species, tree = tree)` in Gaussian
  models.
- The study-intercept test also supports the design-doc statement that
  meta-analysis is Gaussian regression plus known sampling covariance and, when
  needed, structured and ordinary random effects.
- Targeted tests, the full test suite, and `devtools::check()` passed.

## What Did Not Go Smoothly

No implementation issue. The only process note is that GitHub Actions for the
previous docs commit were still in progress while this test was added, so CI
status for this new test should be checked after it is pushed.

## Team Learning

Composing covariance features deserves direct tests even when each feature has
separate comparator coverage. Small dense likelihood checks are a good way to
keep the result CRAN-safe while testing the mathematical contract.

## Known Limitations

- The test uses a tiny dense matrix, not a large sparse covariance route.
- It does not replace longer simulation recovery studies for phylogenetic
  meta-analysis.

## Next Actions

1. Commit and push the comparator.
2. Watch the GitHub Actions result for the pushed commit.
