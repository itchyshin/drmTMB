# After Task: Slice 8 Phylogenetic Profile Smoke

## Goal

Add direct profile-likelihood smoke coverage for the fitted bivariate
phylogenetic `mu1`/`mu2` mean-mean correlation.

## Implemented

`tests/testthat/test-profile-targets.R` now profiles
`cor:phylo:cor(mu1:(Intercept),mu2:(Intercept) | phylo | species)` for a stable
deterministic bivariate phylogenetic Gaussian fixture. The test checks that
`confint()` maps the target to `eta_cor_phylo`, transforms the interval back
through the bounded tanh correlation scale, and matches an independent
`TMB::tmbprofile()` calculation.

## Mathematical Contract

The profiled internal parameter is the transformed phylogenetic correlation:

```text
rho_phylo = 0.999999 * tanh(eta_cor_phylo)
```

The reported interval is on the bounded response correlation scale, not on the
unconstrained internal scale and not on residual `rho12`.

## Files Changed

- `tests/testthat/test-profile-targets.R`
- `R/profile.R`
- `man/confint.drmTMB.Rd`
- `NEWS.md`
- `ROADMAP.md`
- `docs/design/12-profile-likelihood-cis.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `air format tests/testthat/test-profile-targets.R NEWS.md ROADMAP.md docs/design/12-profile-likelihood-cis.md R/profile.R`
- `Rscript -e 'devtools::document()'`
- `Rscript -e 'devtools::test(filter = "profile-targets|phylo-gaussian")'`
- `Rscript -e 'devtools::test()'`
- `Rscript -e 'pkgdown::check_pkgdown()'`
- `rg -n 'eta_cor_phylo|bivariate phylogenetic.*profile|confint\(\).*phylogenetic|phylogenetic.*confint|rho12.*phylogenetic|spatial.*implemented' NEWS.md ROADMAP.md docs/design/12-profile-likelihood-cis.md docs/dev-log/known-limitations.md R/profile.R tests/testthat/test-profile-targets.R man/confint.drmTMB.Rd`
- `rg -n 'profile.*bivariate phylogenetic|bivariate phylogenetic.*planned|spatial.*implemented' NEWS.md ROADMAP.md docs vignettes man`
- `git diff --check`

The focused tests passed with 292 expectations. The full test suite passed with
2,758 expectations and no failures, warnings, or skips. `pkgdown::check_pkgdown()`
reported no problems.

## Tests Of The Tests

The smoke test compares `confint.drmTMB()` against a manual `TMB::tmbprofile()`
lincomb for `eta_cor_phylo`. It checks exact target metadata, lower and upper
transforms, and bounded correlation-scale endpoints.

## Consistency Audit

NEWS, ROADMAP, and the profile-likelihood design note now include the direct
bivariate phylogenetic correlation profile target. The stale-wording scan did
not find a current claim that spatial profiling or spatial fitting is
implemented.

## What Did Not Go Smoothly

The first attempt reused the tiny target-inventory fixture and produced a
missing upper endpoint with TMB profile interpolation warnings. That fixture is
still appropriate for labels, but not for interval geometry. The committed test
uses more tips, more repeated observations, larger phylogenetic SDs, and smaller
residual SDs.

## Team Learning

Fisher should treat profile-interval tests as numerical tests, not just API
tests. A target can be direct and profile-ready while a small fixture still
fails to bracket both interval endpoints.

## Known Limitations

This slice covers one direct bivariate phylogenetic correlation target. It does
not add derived covariance intervals, phylogenetic scale profiles, q=4 endpoint
profiles, non-phylogenetic species covariance profiles, or spatial profiles.

## Next Actions

Add a reader-facing example or status snippet showing how to read the fitted
bivariate phylogenetic correlation layer without confusing it with residual
`rho12` or future spatial covariance.
