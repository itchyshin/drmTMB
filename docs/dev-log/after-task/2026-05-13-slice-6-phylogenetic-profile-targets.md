# After Task: Slice 6 Phylogenetic Profile Targets

## Goal

Expose and test the direct profile-target inventory for the first fitted
bivariate phylogenetic location covariance slice.

## Implemented

`profile_targets()` now has focused regression coverage for a fitted
`biv_gaussian()` model with matching `mu1` and `mu2`
`phylo(1 | species, tree = tree)` terms. The test checks the two phylogenetic
location SD targets and the phylogenetic mean-mean correlation target.

## Mathematical Contract

The fitted phylogenetic layer has two location SDs and one group-level
phylogenetic correlation:

```text
u_species = [u_mu1, u_mu2]'
u_species ~ MVN(0, Sigma_phylo)
cor(Sigma_phylo[1, 2]) = corpars$phylo
```

This correlation is not residual `rho12`. `rho12` remains the within-observation
residual correlation after location and scale predictors have been accounted
for.

## Files Changed

- `tests/testthat/test-profile-targets.R`
- `NEWS.md`
- `ROADMAP.md`
- `docs/design/12-profile-likelihood-cis.md`
- `docs/design/28-double-hierarchical-endpoint.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `air format tests/testthat/test-profile-targets.R NEWS.md ROADMAP.md docs/design/12-profile-likelihood-cis.md docs/design/28-double-hierarchical-endpoint.md`
- `Rscript -e 'devtools::test(filter = "profile-targets|phylo-gaussian")'`
- `Rscript -e 'devtools::test()'`
- `Rscript -e 'pkgdown::check_pkgdown()'`
- `rg -n 'bivariate phylogenetic|cor:phylo|rho12|spatial' NEWS.md ROADMAP.md docs/design/12-profile-likelihood-cis.md docs/design/28-double-hierarchical-endpoint.md docs/dev-log/known-limitations.md vignettes/model-map.Rmd vignettes/phylogenetic-spatial.Rmd`
- `rg -n 'profile intervals already work|profile-likelihood intervals.*phylogenetic|derived.*phylo|spatial.*implemented|bivariate phylo\(\) syntax remains planned|bivariate phylogenetic.*planned' NEWS.md ROADMAP.md docs vignettes`
- `git diff --check`

The focused tests passed with 283 expectations. The full test suite passed with
2,716 expectations and no failures, warnings, or skips. `pkgdown::check_pkgdown()`
reported no problems.

## Tests Of The Tests

The new test verifies exact target names, TMB parameter names, indices,
response-scale transformations, direct target type, profile readiness, and
`ready_only` filtering. It also checks that residual `rho12` targets remain
separate from phylogenetic covariance targets.

## Consistency Audit

NEWS, ROADMAP, and the profile/design notes now describe the fitted bivariate
phylogenetic `mu1`/`mu2` target inventory. The stale-wording scan confirmed that
spatial remains planned and that current docs do not collapse phylogenetic
correlation into residual `rho12`.

## What Did Not Go Smoothly

One stale-wording `rg` command was first quoted too loosely and shell backticks
tried to evaluate `phylo()`. The scan was rerun with single quotes before
closing the task.

## Team Learning

Ada should keep profile-target claims narrower than profile-interval claims:
this slice proves the target inventory and direct mapping, not a long-running
inference study for the phylogenetic correlation.

## Known Limitations

This slice does not add derived covariance intervals, q=4 phylogenetic
location-scale fitting, phylogenetic `sigma` terms, phylogenetic slopes,
non-phylogenetic species covariance, or spatial models.

## Next Actions

Expose the same fitted bivariate phylogenetic mean-mean layer in
`summary(fit)$covariance`, while keeping residual `rho12` and ordinary
group-level covariance rows separate.
