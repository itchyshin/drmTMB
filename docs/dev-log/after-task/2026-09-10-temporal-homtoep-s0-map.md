# After Task: Temporal homogeneous Toeplitz S0 map selection

## Goal

Choose a smooth parameter map that makes every proposed homogeneous temporal
Toeplitz correlation matrix valid before formula or native-likelihood work begins.

## Implemented

`tools/temporal-homtoep-map-study.R` supplies an inverse-Levinson map from
unconstrained partial-autocorrelation coordinates to a Toeplitz correlation matrix.
`tools/temporal-homtoep-gates.R T3-2` independently checks its frozen S0 criteria.
The P2 and master ledgers now record T3-2/P2-parameterisation as passed.

## Mathematical Contract

For finite `eta_m`, `kappa_m = tanh(eta_m)` lies strictly inside `(-1, 1)`.
The inverse Levinson recursion maps these reflection coefficients to lag
correlations and hence to a strictly positive-definite `Toeplitz(R)`. The later
provider will combine this correlation as `sd_temporal^2 * R + sigma^2 * I`.

## Files Changed

The map study, T3-2 runner, test file, S0 decision memo, child source fingerprint,
child/master ledgers, and check log changed. No package `R/` or `src/` file changed.

## Checks Run

- `Rscript --vanilla tools/temporal-homtoep-gates.R T3-2` returned
  `TEMPORAL_HOMTOEP_T3_2_PASS`.
- `testthat::test_file("tests/testthat/test-temporal-homtoep-map.R")` passed.
- The corrected child lane replayed direct-OU G1--G11 and G16; every retained
  temporary receipt contained its expected `TEMPORAL_OU_G*_PASS` marker.
- `git diff --check` is run before the commit.

## Tests Of The Tests

The test was run once before the map existed and failed because its source file was
absent. Its negative controls show the actual two map failures: individually bounded
lag correlations can be indefinite, while generic Cholesky correlations can fail the
Toeplitz equality constraint.

## Consistency Audit

The exact status-inventory search covered `README.md`, `NEWS.md`,
`docs/dev-log/internal-roadmap.md`, `docs/dev-log/known-limitations.md`,
`docs/design/01-formula-grammar.md`, `vignettes/formula-grammar.Rmd`, and
`_pkgdown.yml`. They name only currently implemented AR1/OU routes. That is correct:
S0 adds an internal decision only, so no public capability wording changed.

## GitHub Issue Maintenance

`gh issue list --limit 100 --search "Toeplitz OR temporal"` found only open issue
#1302 for phylogenetically correlated temporal OU series. It does not overlap the
direct Toeplitz map slice. No issue was created or modified.

## What Did Not Go Smoothly

The first child lane came from a planning commit that did not contain the direct-OU
provider or gate runner named by its fingerprint. S0 work was stashed, the lane was
rebased onto the complete direct-OU lineage, the approved receipts were replayed,
and the work was restored before evidence was recorded.

## Team Learning

A child fingerprint must assert executable ancestry, not only name parent commit
hashes in a document. Future child lanes should test for their parent gate runner
before the first owned edit.

## Known Limitations

This is not a fitted covariance provider. It has no formula admission, native
likelihood, extraction, simulation, profile inference, recovery evidence, or public
documentation. Near-boundary partial correlations remain mathematically valid but
will require later weak-information diagnostics.

## Next Actions

Claim the S1 parser/layout files and implement the common complete equally spaced
integer schedule contract. Do not begin TMB provider work until T3-1 passes.
