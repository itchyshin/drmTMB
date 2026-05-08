# After Task: Formula Constructor and Composed Gaussian Family API

## Goal

Make the user-facing API more memorable by promoting `drm_formula()` as the
primary formula constructor, retaining `bf()` as a short alias, and routing the
all-Gaussian composed-family syntax to the existing bivariate Gaussian engine.

## Implemented

- Added exported `drm_formula()` and kept `bf()` as an alias on the same help
  topic.
- Updated `drmTMB()` documentation and errors to refer to `drm_formula()` or
  `bf()`.
- Routed `family = c(gaussian(), gaussian())` and
  `family = list(gaussian(), gaussian())` to the existing fixed-effect
  bivariate Gaussian location-coscale likelihood.
- Added clear errors for mixed composed families and for composed families with
  more than two responses.
- Updated README, NEWS, ROADMAP, design docs, vignettes, man pages, and
  pkgdown reference configuration.

## Mathematical Contract

No likelihood mathematics changed in this task. The composed all-Gaussian
family is only a public API route to the already implemented model:

```text
(y1_i, y2_i)' ~ MVN((mu1_i, mu2_i)', Omega_i)
log(sigma1_i) = X_sigma1[i, ] beta_sigma1
log(sigma2_i) = X_sigma2[i, ] beta_sigma2
atanh(rho12_i) = X_rho12[i, ] beta_rho12
```

The one-response/two-response project boundary was made explicit for composed
families. Mixed-response bivariate likelihoods remain future work.

## Files Changed

- `R/bf.R`, `R/drmTMB.R`, `R/parse-formula.R`
- `tests/testthat/test-package-skeleton.R`,
  `tests/testthat/test-biv-gaussian.R`
- `README.md`, `NEWS.md`, `ROADMAP.md`, `_pkgdown.yml`
- `docs/design/00-vision.md`, `docs/design/01-formula-grammar.md`,
  `docs/design/02-family-registry.md`, `docs/design/03-likelihoods.md`,
  `docs/design/06-distribution-roadmap.md`,
  `docs/design/15-location-coscale-phylogenetic-extension.md`,
  `docs/design/18-random-effect-scale-models.md`
- `vignettes/bivariate-coscale.Rmd`,
  `vignettes/distribution-families.Rmd`, `vignettes/drmTMB.Rmd`,
  `vignettes/formula-grammar.Rmd`, `vignettes/which-scale.Rmd`
- generated roxygen files: `NAMESPACE`, `man/drmTMB.Rd`,
  `man/drm_formula.Rd`; removed obsolete `man/bf.Rd`

## Checks Run

- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test(filter = 'package-skeleton|biv-gaussian')"`:
  67 passed, 0 failed, 0 warnings, 0 skipped.
- Manual smoke fit for `family = c(gaussian(), gaussian())`: routed to
  `biv_gaussian`.
- Manual smoke rejection for `family = c(gaussian(), poisson())`: clear
  mixed-family error.
- `Rscript -e "devtools::test()"`: 389 passed, 0 failed, 0 warnings, 0
  skipped.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- `Rscript -e "pkgdown::build_site()"`: completed successfully.
- `Rscript -e "devtools::check(env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'), manual = FALSE)"`:
  0 errors, 0 warnings, 0 notes.
- Stale-wording scans over source docs and generated `pkgdown-site`.

`air format .` was attempted, but `air` is not installed locally.

## Tests Of The Tests

- New positive tests fit the bivariate Gaussian likelihood through both
  `c(gaussian(), gaussian())` and `list(gaussian(), gaussian())`.
- New negative tests reject mixed two-response families and three-response
  composed families.
- Constructor tests verify `drm_formula()` directly and `bf()` as an alias.

## Consistency Audit

- Source docs and generated pkgdown now agree that `drm_formula()` is primary
  and `bf()` is a short alias.
- `pkgdown-site/reference/bf.html` is a redirect to
  `pkgdown-site/reference/drm_formula.html`, so old links keep working without
  maintaining a separate alias page.
- README, NEWS, ROADMAP, design docs, and vignettes now describe the
  all-Gaussian composed family as implemented rather than future.
- Historical after-task notes that were true when written were left untouched;
  this report supersedes their design-only status.

## What Did Not Go Smoothly

- The first implementation tested `list(gaussian(), gaussian())` but did not
  document it. Franklin caught this before commit.
- Three-response composed families initially fell into the mixed-family error
  rather than the project-scope error. A scope guard and tests now cover this.
- Generated pkgdown lagged behind source docs until the site was rebuilt and
  searched explicitly.

## Team Learning

- Boole/Huygens' naming advice is now reflected in code: `drm_formula()` is the
  primary explicit constructor, and `bf()` remains ergonomic shorthand.
- Herschel's family-routing advice was correct: avoid defining `c.family`;
  instead, parse composed family objects locally in `drmTMB()`.
- Rose's audit pattern caught the hidden API/documentation mismatch. Future API
  tasks should ask: is this spelling public, incidental, or rejected?

## Known Limitations

- Mixed response families such as `c(gaussian(), poisson())` are not
  implemented.
- Bivariate random effects and `mvbind()` shorthand remain future work.
- The composed all-Gaussian family currently routes to the existing
  fixed-effect bivariate Gaussian engine; it does not add new likelihood
  capabilities.

## Next Actions

- Continue hardening the Gaussian path before expanding families.
- Keep equation-plus-R-syntax pairing in vignettes as features move from design
  to implementation.
- Decide later whether `biv_gaussian()` should remain exported indefinitely or
  become a developer/helper alias once composed family syntax is mature.
