# After Task: Slice 18 Phylogenetic q4 Recovery and Diagnostics

## Goal

Add the first CRAN-safe recovery evidence for the fitted phylogenetic q=4
location-scale block and give `check_drm()` a q=4-specific diagnostic surface.

## Implemented

- Added `new_biv_phylo_q4_gaussian_data()` in
  `tests/testthat/test-phylo-gaussian.R`.
- Added a broad simulation recovery test for
  `phylo(1 | p | species, tree = tree)` in `mu1`, `mu2`, `sigma1`, and
  `sigma2`.
- Split `check_drm()` phylogenetic covariance diagnostics:
  `biv_phylo_mu_covariance` now applies only to q=2 `mu1`/`mu2` models, while
  `biv_phylo_q4_covariance` reports the fitted q=4 location-scale block.
- Updated `NEWS.md`, `ROADMAP.md`, `docs/dev-log/known-limitations.md`,
  `docs/design/16-phylo-spatial-common-math.md`, and `man/check_drm.Rd`.
- Inspected local `gllvmTMB` and `gllvmTMB-legacy` profile-CI code for future
  inference design; no code was copied.

## Mathematical Contract

The simulation draws a four-column tip effect matrix

```text
U_tip = [U_mu1, U_mu2, U_sigma1, U_sigma2]
```

from the same separable covariance used by the fitted q=4 model:

```text
vec(U) ~ MVN(0, Sigma_phylo %x% A_tip).
```

The first two columns enter the two location predictors. The last two columns
enter `log(sigma1)` and `log(sigma2)`. Residual `rho12` is generated separately
inside the bivariate Gaussian observation model and remains outside
`Sigma_phylo`.

## Files Changed

- `R/check.R`
- `tests/testthat/test-phylo-gaussian.R`
- `NEWS.md`
- `ROADMAP.md`
- `docs/design/16-phylo-spatial-common-math.md`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/check-log.md`
- `man/check_drm.Rd`

## Checks Run

- `air format R/check.R tests/testthat/test-phylo-gaussian.R NEWS.md ROADMAP.md docs/design/16-phylo-spatial-common-math.md docs/dev-log/known-limitations.md`:
  passed.
- `Rscript -e 'devtools::load_all(quiet = TRUE)'`: passed.
- `Rscript -e 'devtools::document()'`: passed.
- `Rscript -e 'devtools::test(filter = "phylo-gaussian|check-drm|profile-targets", reporter = "summary")'`:
  passed.
- `Rscript -e 'devtools::test(reporter = "summary")'`: passed.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed.
- `rg -n 'full phylogenetic q4.*planned|future `mu1`, `mu2`, `sigma1`, and `sigma2` endpoint|planned-pair scaffold records the six future|fitted phylogenetic mean-mean pair remain planned|not a fitted q=4 model|q=4 phylogenetic.*future' NEWS.md ROADMAP.md docs/design docs/dev-log/known-limitations.md vignettes pkgdown-site/articles`:
  returned no current-status stale hits.
- `git diff --check`: passed.

## Tests Of The Tests

The new recovery test would have failed before Slice 17 because the public
all-four phylogenetic q=4 model did not fit. It now combines the q=4 likelihood
with `corpairs()`, `coef()`, `rho12()`, finite-gradient checking, and
`check_drm()`. The diagnostic assertion would also have failed before this
slice because q=4 fits reused the older q=2 phylogenetic diagnostic wording.

## Consistency Audit

Rose scanned current docs, vignettes, and generated article pages for stale
claims that full phylogenetic q=4 was still only planned. Current-facing docs
now say the constant q=4 block is fitted, while the six q=4 correlation
intervals remain derived and not direct profile-ready. Historical after-task
reports were not treated as current status.

## What Did Not Go Smoothly

- The recovery test is deliberately broad. q=4 scale random effects are
  data-hungry, so the test checks finite gradients and broad targets rather than
  all six correlations to tight tolerances.
- The local fit can still report singular or non-positive-definite Hessian
  behavior on small data even when gradients and point estimates are sensible.
  That is why the test treats finite-gradient evidence as the hard numerical
  assertion.
- Fisher's profile-CI reconnaissance confirmed a useful future path but also a
  boundary: direct `TMB::tmbprofile()` is not enough for q=4 derived
  correlations.

## Team Learning

- Ada should keep the slice claim narrow: one CRAN-safe recovery test and q=4
  diagnostics, not full inference.
- Boole should keep q=2 and q=4 diagnostic names distinct so users do not read a
  mean-mean diagnostic as all-six q=4 evidence.
- Gauss should treat finite-gradient checks as first evidence for this q=4
  branch, with Hessian behavior recorded rather than hidden.
- Noether should keep endpoint order identical across simulation, TMB storage,
  `sdpars`, `corpars`, and `corpairs()`.
- Fisher should turn the `gllvmTMB` profile-CI inspection into a later
  `drmTMB` inference design: direct targets first, derived fix-and-refit later.
- Curie should keep routine recovery tests broad and reserve signed
  six-correlation stress tests for optional long simulations.
- Darwin should review whether the q=4 example needs stronger biology before it
  becomes a tutorial centerpiece.
- Pat should check that the q=4 diagnostic message tells users what to inspect
  next when correlations are near the boundary.
- Emmy should keep `summary()`, `profile_targets()`, `check_drm()`, and
  `corpairs()` aligned as the q=4 surface grows.
- Grace should rerun full tests after shared diagnostic changes, as done here.
- Rose should keep stale-wording scans focused on current docs and leave
  historical reports alone unless they are used as current status.

## Known Limitations

- This is one broad CRAN-safe recovery test, not a simulation grid.
- Direct profile intervals remain unavailable for q=4 derived phylogenetic
  correlations.
- Family B `sd_phylo()` and the spatial sibling lane remain planned.

## Next Actions

1. Move to Slice 19 with a real tutorial/pkgdown example only if the q=4 recovery
   and diagnostic wording are stable enough for readers.
2. Keep Fisher's profile-CI notes for a later inference slice.
3. Preserve spatial as the next sibling structured-effect lane after the
   phylogenetic q=4 article pass.
