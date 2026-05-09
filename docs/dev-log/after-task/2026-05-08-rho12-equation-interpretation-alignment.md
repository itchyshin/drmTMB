# After Task: rho12 Equation and Interpretation Alignment

## Goal

Make the symbolic `rho12` equations, R family metadata, TMB implementation, and
user interpretation prose say the same thing.

## Implemented

- Replaced active idealized `rho12_i = tanh(...)` and
  `atanh(rho12_i) = ...` equations with the implemented guarded transform:
  `rho12_i = 0.99999999 * tanh(eta_rho12_i)`.
- Updated `biv_gaussian()` metadata so `rho12` records the
  `"atanh_guarded"` link.
- Added a test that checks `biv_gaussian()$links["rho12"]` matches the
  internal helper route.
- Added interpretation prose after the runnable bivariate example explaining
  `coef(fit, "rho12")`, `rho12(fit)`, and positive `x3` effects.
- Clarified that `tau` is future second-shape syntax only, not current formula
  grammar or meta-analysis heterogeneity syntax.
- Moved the bivariate phylogenetic aspirational warning before unsupported
  example code.

## Mathematical Contract

The implemented bivariate residual correlation route is:

```text
eta_rho12_i = X_rho12[i, ] beta_rho12
rho12_i = 0.99999999 * tanh(eta_rho12_i)
Omega_i[1, 2] = rho12_i sigma1_i sigma2_i
```

The small multiplier keeps response-scale correlations strictly inside
`(-1, 1)` for numerical stability. The linear predictor is Fisher-z-like, but
the exact inverse transform is guarded.

## Files Changed

- `R/family.R`
- `R/methods.R`
- `README.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/02-family-registry.md`
- `docs/design/08-meta-analysis.md`
- `docs/design/09-phylogenetic-and-spatial-speed.md`
- `docs/design/11-reference-programme.md`
- `docs/design/15-location-coscale-phylogenetic-extension.md`
- `docs/design/16-phylo-spatial-common-math.md`
- `docs/design/18-random-effect-scale-models.md`
- `man/biv_gaussian.Rd`
- `man/rho12.Rd`
- `tests/testthat/test-family-link-contract.R`
- `vignettes/adding-families.Rmd`
- `vignettes/bivariate-coscale.Rmd`
- `vignettes/drmTMB.Rmd`
- `vignettes/location-scale.Rmd`
- `vignettes/testing-likelihoods.Rmd`
- `vignettes/which-scale.Rmd`
- `docs/dev-log/check-log.md`

## Checks Run

- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test(filter = 'family-link-contract|biv-gaussian')"`:
  99 passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- Selected vignette render for `bivariate-coscale`, `which-scale`, `drmTMB`,
  and `testing-likelihoods`: passed.
- `Rscript -e "devtools::test()"`: 701 passed.
- `Rscript -e "pkgdown::build_site()"`: completed successfully.
- `_R_CHECK_SYSTEM_CLOCK_=FALSE Rscript -e "devtools::check(document = FALSE, manual = FALSE, args = '--no-manual')"`:
  0 errors, 0 warnings, 0 notes.
- `git diff --check`: clean.

## Tests Of The Tests

- The new family-link test would fail if `biv_gaussian()` returned the older
  `rho12 = "atanh"` metadata while post-fit methods used `atanh_guarded`.
- Existing bivariate tests still check the link-scale and response-scale
  `rho12` extractors after the metadata change.
- Rendering `which-scale` caught the risk of multiline equations inside a
  markdown table cell.

## Consistency Audit

- Noether/Fisher found the original P1 mismatch between documentation and the
  implementation; active docs now use `eta_rho12` and the guarded transform.
- Pat's suggested interpretation block is now included, adjusted to describe
  the exact guarded response transform rather than a plain `atanh()` scale.
- Stale-wording scan used:

```sh
rg -n 'atanh\(rho12|rho12_i = tanh|rho12 = tanh|rho12 = "atanh"|atanh-scale|atanh link internally|`nu`, `tau`|tau ~|explicit parameter names such as `mu`, `sigma`, `nu`, `tau`' README.md R man tests vignettes docs/design --glob '!docs/dev-log/**'
```

Remaining hits are intentional: future `skew_t()` shape vocabulary, explicit
anti-`tau ~` meta-analysis wording, and the after-task protocol's stale-wording
search pattern.

## What Did Not Go Smoothly

- Earlier docs used the cleaner mathematical transform and missed the numerical
  guard in the implementation.
- The first replacement pass created a multiline markdown table cell in the
  scale-choice vignette; the vignette render check caught this.

## Team Learning

- Symbolic equations should be checked against both `src/drmTMB.cpp` and
  `R/methods.R` before we publish or expand examples.
- Interpretation paragraphs should distinguish coefficient scale from
  response scale whenever a link is nonlinear.
- Future manuscript prose can present the ideal transform, but package docs
  must state the exact implementation.

## Known Limitations

- `rho12` random effects and phylogenetic/spatial effects in the `rho12`
  predictor are still future work.
- `tau` is not current formula syntax; it remains reserved for future
  second-shape families.

## Next Actions

- Commit and push this documentation/math-alignment slice.
- Watch GitHub Actions.
- Continue with either more equation-plus-syntax documentation or the next
  carefully bounded family-design step.
