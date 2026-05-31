# After Task: Bivariate Slope-Only Extractor Gate

## Goal

Advance #440 by adding a low-risk regression gate for the fitted bivariate
Gaussian matching slope-only `mu1`/`mu2` covariance route. The claim is narrow:
the existing `(0 + x | p | id)` fit exposes one `slope-slope` row through
`corpairs()` and one through `summary(fit)$covariance`, and both report the
same correlation as `fit$corpars$mu`.

## Implemented

The existing bivariate Gaussian slope-only test now extracts
`summary(fit)$covariance`, filters `class == "slope-slope"`, and checks that
there is exactly one row. The test also checks that the `corpairs()` estimate
and the summary covariance correlation match `fit$corpars$mu`.

`corpairs()` roxygen and `man/corpairs.Rd` now say that matched bivariate
`mu1`/`mu2` slope-only covariance blocks are reported. The bivariate Gaussian
entry in `docs/design/03-likelihoods.md` now names the slope-only ordinary
`mu1`/`mu2` covariance block and adds an example that keeps the row separate
from residual `rho12`.

## Mathematical Contract

For matching terms such as `(0 + x | p | id)` in both `mu1` and `mu2`, the
fitted latent row is one group-level slope-slope correlation,
`cor(mu1:x,mu2:x | p | id)`. This correlation is a covariance-block parameter,
not the residual bivariate coscale parameter `rho12`. This task did not change
the likelihood, parser, or formula grammar.

## Files Changed

- `tests/testthat/test-biv-gaussian.R`
- `R/methods.R`
- `man/corpairs.Rd`
- `docs/design/03-likelihoods.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-30-bivariate-slope-only-extractor-gate.md`

## Checks Run

```sh
air format R/methods.R tests/testthat/test-biv-gaussian.R
Rscript --vanilla -e "devtools::document()"
Rscript --vanilla -e "devtools::test(filter = '^biv-gaussian$', reporter = 'summary')"
rg -n -F -e 'slope-only covariance' -e 'matching slope-only ordinary `mu1`/`mu2` covariance block' -e 'matched bivariate \\code{mu1}/\\code{mu2} random-intercept and slope-only covariance' R/methods.R man/corpairs.Rd docs/design/03-likelihoods.md
rg -n -F -e 'Planned double-hierarchical bivariate syntax with random slopes and scale random effects' -e 'matched bivariate `mu1`/`mu2` and `sigma1`/`sigma2` random-intercept' -e 'matched bivariate \\code{mu1}/\\code{mu2} and \\code{sigma1}/\\code{sigma2} random-intercept' R/methods.R man/corpairs.Rd docs/design/03-likelihoods.md
git diff --check
```

`air format`, `devtools::document()`, `devtools::test(filter = '^biv-gaussian$')`,
the fixed-string stale-wording scan, and `git diff --check` passed. The
attempted `testthat::test_file(..., filter = ...)` command failed because this
installed `testthat` interface does not accept a `filter` argument for
`test_file()`. A first regex stale scan also failed on escaped braces, so the
final audit used the `rg -F` command above. The file-filtered
`devtools::test()` command covered the Phase 18 bivariate slope smoke tests
whose file name contains `biv-gaussian`.

## Tests Of The Tests

The new assertion connects three existing extractor surfaces: `corpairs()`,
`summary(fit)$covariance`, and `fit$corpars$mu`. A regression that drops the
summary row, changes its `class`, duplicates the row, or reports a correlation
that no longer matches the fitted correlation parameter should fail.

## Consistency Audit

The touched docs now use the same boundary: matching slope-only `mu1`/`mu2`
covariance is fitted and extractor-visible, while broader bivariate random
slopes and residual-scale slope covariance remain planned. The stale scan
covered the touched R, Rd, and design files for old wording that treated only
random-intercept bivariate covariance as implemented.

## GitHub Issue Maintenance

No issue comment was posted from this workspace. #440 should stay conservative:
this patch supports the extractor gate but does not promote simulation recovery,
coverage, or a broader bivariate random-slope support claim.

## What Did Not Go Smoothly

Earlier roxygen attempts in this sprint had produced unrelated generated-file
churn, so this slice explicitly checked the worktree after documentation
regeneration and kept only the `man/corpairs.Rd` change needed for the
`corpairs()` roxygen update. The first targeted test command and first stale
scan used interfaces too optimistically; both were replaced with commands that
ran cleanly in this workspace.

## Team Learning

Curie should prefer the repo-standard `devtools::test(filter = ...)` command
for focused package tests unless the installed `testthat` API is confirmed.
Rose should continue separating extractor evidence from simulation recovery
evidence in #440.

## Known Limitations

This task does not add simulation recovery, coverage, cross-platform CI
evidence, predictor-dependent slope correlations, intercept-plus-slope q4
bivariate covariance, residual-scale bivariate slopes, or random effects in
`rho12`.

## Next Actions

Use #440 to decide whether the bivariate slope-only grid should stay
artifact-ready or advance to recovery evidence after a separate simulation
run. Keep any broader bivariate random-slope syntax behind its existing parser
errors until likelihood, extractor, and simulation evidence agree.
