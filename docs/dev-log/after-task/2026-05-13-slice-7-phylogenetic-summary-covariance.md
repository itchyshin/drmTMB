# After Task: Slice 7 Phylogenetic Summary Covariance

## Goal

Expose the fitted bivariate phylogenetic `mu1`/`mu2` mean-mean layer in
`summary(fit)$covariance`.

## Implemented

`summary(fit)$covariance` now reports a phylogenetic row for the fitted
`biv_gaussian()` slice with matching `mu1` and `mu2`
`phylo(1 | species, tree = tree)` terms. The row uses the same columns as
ordinary covariance summaries: component SD targets, correlation target,
variance point estimates, covariance point estimate, scale labels, and interval
status columns.

## Mathematical Contract

For the fitted slice,

```text
u_species = [u_mu1, u_mu2]'
u_species ~ MVN(0, Sigma_phylo)
cov(u_mu1, u_mu2) = sd_mu1 * sd_mu2 * cor_phylo
```

This is a phylogenetic random-effect covariance. It is separate from residual
`rho12`, which remains the within-observation residual correlation.

## Files Changed

- `R/methods.R`
- `tests/testthat/test-summary.R`
- `man/summary.drmTMB.Rd`
- `NEWS.md`
- `ROADMAP.md`
- `docs/design/28-double-hierarchical-endpoint.md`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `air format R/methods.R tests/testthat/test-summary.R NEWS.md ROADMAP.md docs/design/28-double-hierarchical-endpoint.md docs/dev-log/known-limitations.md`
- `Rscript -e 'devtools::document()'`
- `Rscript -e 'devtools::test(filter = "summary|phylo-gaussian|corpairs|profile-targets")'`
- `Rscript -e 'devtools::test()'`
- `Rscript -e 'pkgdown::check_pkgdown()'`
- `rg -n 'summary\(fit\)\$covariance|summary\(\).*phylogenetic|bivariate phylogenetic.*covariance|rho12.*summary|spatial.*implemented' NEWS.md ROADMAP.md docs/design/28-double-hierarchical-endpoint.md docs/dev-log/known-limitations.md vignettes/model-map.Rmd vignettes/phylogenetic-spatial.Rmd R/methods.R tests/testthat/test-summary.R man/summary.drmTMB.Rd`
- `rg -n 'summary\(fit\)\$covariance.*registry-backed|registry-backed.*summary\(fit\)\$covariance|covariance component.*registry-backed|spatial.*implemented' NEWS.md ROADMAP.md docs/design docs/dev-log/known-limitations.md vignettes man/summary.drmTMB.Rd`
- `git diff --check`

The focused tests passed with 484 expectations. The full test suite passed with
2,749 expectations and no failures, warnings, or skips. `pkgdown::check_pkgdown()`
reported no problems.

## Tests Of The Tests

The new regression test fits a small bivariate phylogenetic Gaussian model and
checks exact row metadata, response labels, SD targets, correlation target,
identity scales, covariance arithmetic, interval status, and the absence of
`rho12` from the covariance-row target.

## Consistency Audit

NEWS, ROADMAP, known limitations, the double-hierarchical endpoint note, and the
generated `summary()` reference documentation now describe the phylogenetic row
without claiming q > 2, phylogenetic scale, random slopes, non-phylogenetic
species covariance, or spatial support.

## What Did Not Go Smoothly

The main implementation detail was avoiding a registry-only early return in the
summary helper. The fix keeps a small phylogenetic row builder beside the
registry-backed builder and combines their outputs only when rows are present.

## Team Learning

Emmy should keep covariance-reporting surfaces column-stable as new covariance
sources are added. The source of the covariance row can vary, but users should
not need a different table shape for phylogenetic rows.

## Known Limitations

This slice reports point summaries only. Derived covariance intervals, q=4
phylogenetic location-scale rows, phylogenetic scale terms, phylogenetic slopes,
non-phylogenetic species covariance, and spatial covariance remain planned.

## Next Actions

Add a focused profile/confint smoke check for the direct bivariate phylogenetic
correlation target, if the small fixture is numerically stable enough to support
it without slowing the suite too much.
