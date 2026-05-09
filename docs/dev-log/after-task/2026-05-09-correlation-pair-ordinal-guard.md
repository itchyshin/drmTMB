# After Task: Correlation-Pair and Ordinal Guard Design

## Goal

Clarify two planned areas before implementation: bivariate
double-hierarchical correlation pairs and ordinal location-scale models.

## Implemented

- Added `docs/design/20-coscale-correlation-pairs.md`.
- Improved the bivariate random-effect error path so future syntax such as
  `(1 | id)` or `(1 + x | p | id)` in `mu1`/`mu2` is rejected as planned
  bivariate covariance-block syntax, not as a vague formula failure.
- Added bivariate malformed-syntax tests for unlabelled and labelled future
  random-effect blocks.
- Added the Ortega et al. (2026) seabird nest-success manuscript to
  `REFERENCES.bib` and the reference programme.
- Updated ordinal roadmap text to distinguish public ordinal `sigma` from a
  reported discrimination summary `zeta = 1 / sigma`.
- Synchronized README, ROADMAP, design docs, vignettes, known limitations,
  check log, and generated pkgdown site.

## Mathematical Contract

The currently implemented bivariate Gaussian coscale model remains:

```text
[y1_i, y2_i]' ~ MVN([mu1_i, mu2_i]', Omega_i)
Omega_i[1,2] = rho12_i sigma1_i sigma2_i
rho12_i = 0.99999999 tanh(X_rho12[i, ] beta_rho12)
```

Residual `rho12` is a within-row response-response correlation.

Future double-hierarchical covariance blocks should instead identify
correlation pairs such as:

```text
cor(mu1:(Intercept), mu2:(Intercept) | ID)
cor(mu1:x, mu2:x | ID)
cor(sigma1:(Intercept), sigma2:(Intercept) | ID)
cor(mu1:(Intercept), sigma1:(Intercept) | ID)
```

Those are group-level covariance parameters, not residual `rho12`.

For ordinal location-scale models, the current design candidate is:

```text
Pr(y_i <= k) = logit^{-1}((theta_k - mu_i) / sigma_i)
mu_i = X_mu[i, ] beta_mu
log(sigma_i) = X_sigma[i, ] beta_sigma
theta_1 < theta_2 < ... < theta_{K-1}
```

With this convention, larger `sigma_i` means more diffuse ordinal outcomes.
A discrimination or consistency summary can be reported as
`zeta_i = 1 / sigma_i`.

## Files Changed

- `R/drmTMB.R`
- `README.md`
- `REFERENCES.bib`
- `ROADMAP.md`
- `docs/design/04-random-effects.md`
- `docs/design/06-distribution-roadmap.md`
- `docs/design/11-reference-programme.md`
- `docs/design/15-location-coscale-phylogenetic-extension.md`
- `docs/design/19-family-link-contract.md`
- `docs/design/20-coscale-correlation-pairs.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/known-limitations.md`
- `tests/testthat/test-biv-gaussian.R`
- `vignettes/distribution-families.Rmd`
- `vignettes/formula-grammar.Rmd`
- generated `pkgdown-site/` pages

## Checks Run

- `Rscript -e "devtools::test(filter = 'biv-gaussian')"`
- `Rscript -e "devtools::test(filter = 'formula-grammar|gaussian-random-intercepts|gaussian-random-effect-scale')"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "devtools::check()"`
- `git diff --check`
- `air format .`

Results:

- bivariate Gaussian tests: 95 passed, 0 failed;
- formula/random-effect neighbouring tests: 234 passed, 0 failed;
- full `devtools::test()`: 1162 passed, 0 failed;
- pkgdown checks: no problems found;
- pkgdown build: completed successfully;
- `git diff --check`: clean;
- `devtools::check()`: 0 errors, 0 warnings, 0 notes;
- `air format .`: failed because `air` is not installed locally.

## Tests Of The Tests

The new bivariate guard tests exercise malformed future syntax. They verify
that the error message names planned bivariate random-effect covariance blocks
and does not imply that residual `rho12` is the correct target for group-level
correlations.

## Consistency Audit

Searches run:

```sh
rg -n "Bivariate random-effect syntax is planned|correlation-pair|corpairs|zeta|cumulative_logit|O.Dea-style|O'Dea-style|biological data|rho ~|tau ~|meta_gaussian" README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests REFERENCES.bib

rg -n "Bivariate random-effect syntax is planned|correlation-pair|corpairs|zeta|cumulative_logit|O.Dea-style|O'Dea-style|biological data|rho ~|tau ~|meta_gaussian" pkgdown-site README.md ROADMAP.md docs/design docs/dev-log/known-limitations.md vignettes R tests REFERENCES.bib
```

The searches found expected planned ordinal/correlation-pair wording and
existing meta-analysis policy text. No `O'Dea-style` wording or narrow
"biological data" framing was found in the scanned source files.

## What Did Not Go Smoothly

The first instinct was to describe the ordinal scale as discrimination. The
design now avoids that ambiguity by treating public `sigma` as ordinal scale
and reserving `zeta = 1 / sigma` as a reported discrimination summary unless a
later grammar decision exposes `zeta` directly.

The local formatter still cannot run because `air` is not installed.

## Team Learning

- Ada should keep pausing before large likelihood jumps when the naming
  surface is unclear.
- Boole and Emmy should use the correlation-pair table as the future API
  constraint.
- Noether should require symbolic equations, R syntax, and extractor labels
  for every new pair class.
- Fisher should insist on simulation recovery and comparator checks before any
  bivariate covariance-block implementation is called fitted.
- Pat should review the ordinal nest-success explanation for whether an
  applied user understands `sigma` and `zeta`.
- Rose should continue checking whether terms such as `rho12`, `sigma`,
  `sd(group)`, and `corpair` drift across docs.

## Known Limitations

- No new bivariate random-effect likelihood was added.
- No `corpairs()` function was exported.
- No ordinal likelihood was added.
- The public `sigma` versus possible `zeta` ordinal interface remains a design
  decision for the ordinal implementation phase.

## Next Actions

1. Review `docs/design/20-coscale-correlation-pairs.md` with Boole, Noether,
   Fisher, Pat, and Rose before implementing a `corpairs()` helper.
2. Decide whether ordinal models should expose public `sigma` only, public
   `zeta`, or both `sigma` plus a reporting alias.
3. Add a small `corpairs()` design-only helper for existing `rho12` and
   `corpars$mu` output before fitting bivariate group-level covariance blocks.
