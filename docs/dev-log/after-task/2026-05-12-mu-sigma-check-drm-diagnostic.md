# After Task: Mu/Sigma check_drm Diagnostic

## Goal

Add a first-pass `check_drm()` diagnostic for the implemented univariate
Gaussian labelled `mu`/`sigma` random-intercept covariance block.

## Implemented

`check_drm()` now adds a `mu_sigma_random_effect_covariance` row when a
univariate Gaussian fit contains matching labelled `mu` and `sigma` random
intercepts such as:

```r
bf(y ~ x + (1 | p | id), sigma ~ z + (1 | p | id))
```

The diagnostic reports:

- the number of fitted groups;
- the smallest fitted group replication count;
- the number of singleton groups;
- the fitted `mu` random-intercept SD relative to mean residual `sigma`;
- the fitted `sigma` random-intercept SD on the log-scale.

Rows are `ok` when groups are replicated and both component SDs are
non-negligible. Rows are `note` when a group has fewer than two fitted
observations or either component SD is tiny on its interpretation scale.

## Mathematical Contract

The diagnostic follows the same model slice as the likelihood:

```text
mu_i = X_mu[i, ] beta_mu + b_j
log(sigma_i) = X_sigma[i, ] beta_sigma + a_j
cor(b_j, a_j) = rho_mu_sigma
```

It does not add a new likelihood or a new covariance parameter. It only checks
replication and scale evidence for the already fitted group-level mean-scale
correlation.

## Files Changed

- `R/check.R`
- `tests/testthat/test-check-drm.R`
- `NEWS.md`
- `man/check_drm.Rd`
- `docs/design/16-phylo-spatial-common-math.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-12-mu-sigma-check-drm-diagnostic.md`

## Checks Run

- `air format R/check.R tests/testthat/test-check-drm.R NEWS.md docs/design/16-phylo-spatial-common-math.md`:
  passed.
- `Rscript -e "devtools::test(filter = 'check-drm')"`: passed with 96
  expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e "devtools::document()"`: passed and regenerated
  `man/check_drm.Rd`.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.

## Tests Of The Tests

The test fits a model with the labelled `mu`/`sigma` covariance block and
checks that the new row is `ok`, reports the expected group count and minimum
replication, and describes non-negligible component SDs.

The same test mutates the fitted object twice: once to create a singleton
group in the diagnostic structure, and once to make the fitted sigma
random-effect SD tiny. Both mutations must return `note` while leaving the
overall diagnostic object acceptable for programmatic checks.

## Consistency Audit

The user-facing roxygen text, generated `man/check_drm.Rd`, `NEWS.md`, and
`docs/design/16-phylo-spatial-common-math.md` now describe the univariate
`mu`/`sigma` diagnostic alongside the existing bivariate `mu1`/`mu2`
diagnostic.

The exact status scans were:

```sh
rg -n 'mu_sigma_random_effect_covariance|mu/sigma.*diagnostic|mean-scale covariance diagnostics|bivariate `mu1`/`mu2` random-intercept covariance diagnostics|check_drm\(\).*mu.*sigma' R/check.R tests/testthat/test-check-drm.R NEWS.md docs/design docs/dev-log/known-limitations.md vignettes README.md ROADMAP.md man/check_drm.Rd
rg -n 'component SD|interpretation scale|univariate .*mu.*sigma|mean-scale covariance block|mu/sigma group-level covariance|mu/sigma covariance' R/check.R man/check_drm.Rd docs/design/16-phylo-spatial-common-math.md tests/testthat/test-check-drm.R NEWS.md
```

## What Did Not Go Smoothly

One first attempt at a stale-wording scan used shell backticks inside a
double-quoted pattern, so the shell tried to execute `mu1` and `mu2`. The scan
was rerun with single quotes and recorded correctly in the check log.

## Team Learning

- Ada kept this as a diagnostic slice, not a second likelihood change.
- Curie made the test exercise both the ordinary fitted path and two diagnostic
  note branches.
- Rose kept the wording specific to the intercept-only `mu`/`sigma`
  mean-scale covariance block.

## Known Limitations

- The diagnostic uses a first-pass `0.05` threshold for both `mu` SD relative
  to residual `sigma` and the `sigma` random-effect SD on the log-scale.
- It covers only the currently implemented single intercept-only labelled
  `mu`/`sigma` covariance block.
- It does not diagnose random slopes, multiple covariance blocks, bivariate
  `sigma1`/`sigma2` blocks, phylogenetic covariance, or spatial covariance.

## Next Actions

1. Add an independent likelihood or simulation comparator for the
   `mu`/`sigma` covariance block if this feature becomes release-critical.
2. Keep future bivariate and structured covariance diagnostics separate so
   residual `rho12`, group-level mean-scale covariance, and phylogenetic or
   spatial covariance remain distinct.
