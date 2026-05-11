# After Task: Bivariate Mu Covariance `check_drm()` Diagnostics

## Goal

Add first-pass diagnostics for the implemented bivariate Gaussian
`mu1`/`mu2` random-intercept covariance block, so users see weak replication or
near-zero group-level SDs before interpreting group-level correlations.

## Implemented

- Added a `biv_mu_random_effect_covariance` row to `check_drm()` for
  `biv_gaussian()` fits with matching labelled `mu1`/`mu2` random intercepts.
- The diagnostic reports the number of groups, the minimum fitted observation
  count per group, the number of singleton groups, and the smallest fitted
  group-level SD relative to its matching residual scale.
- The row returns `note` when any group has fewer than two fitted observations
  or when either fitted group-level SD is less than 5% of the matching residual
  scale.
- Updated the `check_drm()` reference text, `NEWS.md`, the bivariate coscale
  vignette, and the structured-effect diagnostic design note.
- Marked the diagnostic item as completed in the parent bivariate covariance
  after-task report.

## Mathematical Contract

For the fitted block

```text
mu1_ij = X_mu1[ij, ] beta_mu1 + b_1j
mu2_ij = X_mu2[ij, ] beta_mu2 + b_2j
```

the diagnostic does not change the likelihood. It inspects the already-fitted
group-level SDs in `sdpars$mu`, compares each to the mean residual scale for
the matching response, and inspects group replication from the fitted random
effect index. Residual `rho12` remains checked by the separate
`rho12_boundary` row.

## Files Changed

- `R/check.R`
- `tests/testthat/test-check-drm.R`
- `man/check_drm.Rd`
- `NEWS.md`
- `vignettes/bivariate-coscale.Rmd`
- `docs/design/16-phylo-spatial-common-math.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-11-bivariate-mu-random-intercept-covariance.md`

## Checks Run

- `air format R/check.R tests/testthat/test-check-drm.R NEWS.md vignettes/bivariate-coscale.Rmd docs/design/16-phylo-spatial-common-math.md`:
  passed.
- `Rscript -e "devtools::test(filter = 'check-drm')"`: passed with 73
  expectations.
- `Rscript -e "devtools::document()"`: passed and regenerated
  `man/check_drm.Rd`.
- `air format R/check.R tests/testthat/test-check-drm.R NEWS.md vignettes/bivariate-coscale.Rmd docs/design/16-phylo-spatial-common-math.md man/check_drm.Rd`:
  passed.
- `Rscript -e "devtools::test(filter = 'check-drm|biv-gaussian')"`: passed
  with 196 expectations.
- `Rscript -e "devtools::test()"`: passed with 1681 expectations.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed and regenerated
  `reference/check_drm.html`, `articles/bivariate-coscale.html`, and
  `news/index.html`.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `_R_CHECK_SYSTEM_CLOCK_=FALSE Rscript -e "devtools::check(document = FALSE, manual = FALSE, args = '--no-tests')"`:
  passed with 0 errors, 0 warnings, and 0 notes.
- `git diff --check`: passed.

## Tests Of The Tests

- The new test fits a real bivariate Gaussian `mu1`/`mu2` labelled
  random-intercept covariance model and checks that the diagnostic row is `ok`
  for replicated groups with non-negligible fitted SDs.
- The same fitted object is mutated to create one singleton group, verifying
  the poor-replication `note` branch without adding an unstable tiny-data fit.
- The fitted object is also mutated to make one group-level SD tiny relative to
  the fitted residual scale, verifying the weak-SD `note` branch.

## Consistency Audit

- `rg -n "biv_mu_random_effect_covariance|tiny relative|mu1.*mu2.*random-intercept covariance diagnostics|group-level SD is tiny|non-negligible fitted SDs" R/check.R tests/testthat/test-check-drm.R NEWS.md vignettes/bivariate-coscale.Rmd docs/design/16-phylo-spatial-common-math.md man/check_drm.Rd pkgdown-site/reference/check_drm.html pkgdown-site/articles/bivariate-coscale.html pkgdown-site/news/index.html --glob '!pkgdown-site/search.json'`:
  confirmed the new source, generated reference, generated article, and news
  wording.
- `rg -n "ordinary random-effect replication, ordinary random-slope design variation, and phylogenetic species replication|random-effect replication, and random-slope design variation\\. If" README.md docs vignettes man pkgdown-site --glob '!pkgdown-site/search.json'`:
  passed with no stale standalone diagnostic-list wording.

## What Did Not Go Smoothly

- The first implementation used `min(sd_ratios, na.rm = TRUE)` directly. That
  would be harmless for valid bivariate covariance fits, but could emit an R
  warning for a malformed object with no available SD ratio. The helper now
  computes finite ratios first.

## Team Learning

- Diagnostic tests can cheaply cover note branches by mutating a stable fitted
  object after verifying the real fitted path once. This avoids fragile
  deliberately underpowered model fits.

## Known Limitations

- The 5% relative-SD threshold is a first-pass heuristic, not an identifiability
  proof.
- The diagnostic covers only the implemented matching labelled `mu1`/`mu2`
  random-intercept covariance block.
- It does not yet assess bivariate random slopes, residual-scale random
  effects, phylogenetic or spatial bivariate covariance, or formal
  separability from residual `rho12`.

## Next Actions

- Add profile-target coverage for the new bivariate group-level SD and
  correlation labels if the existing inventory does not expose the exact names
  users need.
- Keep bivariate random slopes as the next covariance expansion only after a
  separate simulation plan is written.
