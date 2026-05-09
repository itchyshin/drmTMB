# After Task: High rho12 Recovery and Site Consistency

## Goal

Harden the bivariate Gaussian residual-correlation tests and remove current
documentation/site drift after the count-family expansion.

## Implemented

- Added a bivariate Gaussian recovery test for `rho12 = 0.8` and
  `rho12 = -0.8`.
- Updated the testing strategy and testing-likelihoods vignette so high
  `rho12` is an explicit required case.
- Updated DESCRIPTION and the main vignette so ZIP and ZINB2 are implemented
  work, not future work.
- Added implemented `lognormal()` rows and syntax to the formula-grammar design
  note and vignette.
- Reworded the distribution-family vignette from placeholder future language to
  present-tense documentation.
- Added `tools/fix-pkgdown-favicon-mime.R` and called it from the pkgdown
  workflow after `pkgdown::build_site()`.

## Mathematical Contract

For the new bivariate edge test:

```text
(y1_i, y2_i)' | mu1_i, mu2_i, sigma1_i, sigma2_i, rho12
  ~ MVN(mu_i, Sigma_i)

Sigma_i =
  [ sigma1_i^2                         rho12 sigma1_i sigma2_i ]
  [ rho12 sigma1_i sigma2_i            sigma2_i^2              ]

eta_rho12 = beta_rho12
rho12 = tanh(eta_rho12)
```

The implementation uses the guarded response transform
`rho12 = 0.99999999 * tanh(eta_rho12)`, so the test checks recovery while also
checking that response-scale predictions stay inside the correlation boundary.

## Files Changed

- `.github/workflows/pkgdown.yaml`
- `DESCRIPTION`
- `docs/design/01-formula-grammar.md`
- `docs/design/05-testing-strategy.md`
- `docs/dev-log/check-log.md`
- `tests/testthat/test-biv-gaussian.R`
- `tools/fix-pkgdown-favicon-mime.R`
- `vignettes/distribution-families.Rmd`
- `vignettes/drmTMB.Rmd`
- `vignettes/formula-grammar.Rmd`
- `vignettes/testing-likelihoods.Rmd`

## Checks Run

- `Rscript -e "devtools::test(filter = 'biv-gaussian')"`
- `Rscript -e "devtools::test()"`
- `air format .` failed because `air` is not installed locally.
- `git diff --check`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`
- `Rscript -e "devtools::check()"`

Results:

- targeted bivariate tests: 94 passed, 0 failed, 0 warnings, 0 skips;
- full tests: 981 passed, 0 failed, 0 warnings, 0 skips;
- pkgdown check: no problems found;
- pkgdown build: successful;
- R CMD check: 0 errors, 0 warnings, 0 notes;
- whitespace check: clean;
- generated local site has no remaining malformed smart-quote favicon MIME
  strings after the post-processing script.

## Tests Of The Tests

- The new test covers both high positive and high negative residual
  correlations.
- It checks convergence, Hessian status, response-scale recovery, and the
  guarded response transform.
- It would fail if the sign of `rho12`, the atanh/tanh mapping, or the
  covariance construction were reversed.

## Consistency Audit

Searches run:

```sh
rg -n 'type="”|later .*zero-inflation|zero-inflation, and additional|This article will help|current planning reference' DESCRIPTION vignettes docs/design pkgdown-site/index.html pkgdown-site/articles/drmTMB.html pkgdown-site/articles/distribution-families.html pkgdown-site/articles/formula-grammar.html pkgdown-site/articles/testing-likelihoods.html
rg -n 'lognormal\(\).*Implemented|family = lognormal\(\)|high positive and high negative|\+/-0\.8|drmTMB-logo\.png|man/figures/logo\.png' docs/design/01-formula-grammar.md docs/design/05-testing-strategy.md vignettes/formula-grammar.Rmd vignettes/testing-likelihoods.Rmd README.md _pkgdown.yml pkgdown-site/index.html pkgdown-site/articles/formula-grammar.html pkgdown-site/articles/testing-likelihoods.html
```

Active docs now describe the implemented count-family surface and lognormal
syntax consistently. Historical after-task notes were not rewritten; they
remain a time-stamped record and are superseded by newer after-task reports.

## What Did Not Go Smoothly

- `pkgdown::check_pkgdown()` reported no problems even though generated HTML had
  a malformed smart-quote MIME type for the SVG favicon.
- The malformed line comes from the installed `pkgdown 2.1.3` template, so the
  project needs a post-build fixer until the upstream template is corrected or
  the build environment uses a fixed release.
- `air` is still unavailable locally.

## Team Learning

- Boundary-style tests are worth adding even when moderate recovery tests
  already pass, because `rho12` is central to the package identity.
- Generated web artifacts need direct scans; successful pkgdown checks are not
  enough.
- Rose-style audits should continue after every phase because wording drift is
  now the main source of small inconsistencies.

## Known Limitations

- High-`rho12` coverage is fixed-effect bivariate Gaussian only.
- Bivariate random effects, non-Gaussian bivariate responses, and structured
  correlation components remain later phases.

## Next Actions

- Add a count-family after-phase roll-up that states the current Poisson, ZIP,
  NB2, and ZINB2 surface in one place.
- Make a beta/proportion design decision before implementing `beta()`.
