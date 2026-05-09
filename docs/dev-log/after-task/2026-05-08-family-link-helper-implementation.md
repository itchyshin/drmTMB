# After Task: Family Link Helper Implementation

## Goal

Make the family-link contract real in the internal post-fit method code before
adding more non-Gaussian families.

## Implemented

- `fitted.drmTMB()` now delegates to `drm_fitted_response()`.
- `predict.drmTMB(type = "response")` now delegates to `drm_inverse_link()`.
- `drm_dpar_link()` records the implemented link table for Gaussian,
  Student-t, lognormal, and bivariate Gaussian model paths.
- Added `tests/testthat/test-family-link-contract.R` for link mappings,
  inverse links, family-specific fitted summaries, and malformed internal
  routing.
- Updated the family-link contract design note, source-map article, roadmap,
  and generated `predict()` manual page.

## Mathematical Contract

For every implemented distributional parameter,

```text
eta_d,i = X_d[i, ] beta_d
theta_d,i = inverse_link_d(eta_d,i)
```

where `theta_d,i` is the native response-scale distributional parameter. The
current table is:

```text
Gaussian:           mu = eta_mu; sigma = exp(eta_sigma)
Student-t:          mu = eta_mu; sigma = exp(eta_sigma); nu = 2 + exp(eta_nu)
Lognormal:          mu = eta_mu on log(y); sigma = exp(eta_sigma)
Bivariate Gaussian: mu1 = eta_mu1; mu2 = eta_mu2
                    sigma1 = exp(eta_sigma1); sigma2 = exp(eta_sigma2)
                    rho12 = 0.99999999 * tanh(eta_rho12)
```

`fitted()` is not simply `predict(mu)` for every family. It returns the
family-specific fitted response summary:

```text
Gaussian:           fitted_i = mu_i
Student-t:          fitted_i = mu_i for the current finite-variance contract
Lognormal:          fitted_i = exp(mu_i + sigma_i^2 / 2)
Bivariate Gaussian: fitted_i = (mu1_i, mu2_i)
```

## Files Changed

- `R/methods.R`
- `tests/testthat/test-family-link-contract.R`
- `docs/design/19-family-link-contract.md`
- `vignettes/source-map.Rmd`
- `ROADMAP.md`
- `man/predict.drmTMB.Rd`
- `docs/dev-log/check-log.md`

## Checks Run

- `Rscript -e "devtools::test(filter = 'family-link-contract')"`: 14 passed.
- `Rscript -e "devtools::test(filter = 'family-link-contract|gaussian-location-scale|student-location-scale|lognormal-location-scale|biv-gaussian')"`:
  208 passed.
- `Rscript -e "devtools::document()"`: regenerated `predict.drmTMB.Rd`.
- `Rscript -e "devtools::test()"`: 700 passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- `Rscript -e "pkgdown::build_site()"`: completed successfully.
- `_R_CHECK_SYSTEM_CLOCK_=FALSE Rscript -e "devtools::check(document = FALSE, manual = FALSE, args = '--no-manual')"`:
  0 errors, 0 warnings, 0 notes.
- `git diff --check`: clean.

## Tests Of The Tests

- The lognormal fitted-response test compares `fitted()` with
  `exp(mu + sigma^2 / 2)`, so it would fail if lognormal inherited the Gaussian
  fitted-value rule.
- The Student-t inverse-link test checks `nu = 2 + exp(eta_nu)`, so it would
  catch accidental replacement by a plain log link.
- The malformed-routing tests mutate fake internal model objects, so the
  helper failure paths are exercised without needing unsupported public syntax.

## Consistency Audit

- Rose reviewed the slice and found no code-level blocker.
- Rose's P1 closure finding was addressed by this after-task report and the
  matching check-log entry.
- Rose's stale pkgdown concern was addressed by rebuilding the local pkgdown
  site and confirming the generated `predict()` page and source-map article
  contain the new text.
- Rose's roadmap concern was addressed by changing Phase 7 to say the
  implemented helper table must be extended before new families are added.
- Stale-wording scan used:

```sh
rg -n "Implement the family-link contract before|hard-coded.*dpar|dpar == \"mu\"|response scale\\. For positive|Post-fit response-scale transforms|distributional parameter" README.md ROADMAP.md NEWS.md docs vignettes man pkgdown-site/reference/predict.drmTMB.html pkgdown-site/articles/source-map.html --glob '!pkgdown-site/search.json'
```

## What Did Not Go Smoothly

- `air format` was not installed, so formatting had to be checked manually with
  `git diff --check`.
- The first implementation pass updated code and tests before updating the
  closure artifacts; Rose caught this, which is the process working as intended.

## Team Learning

- A small internal method refactor can still change the project status story.
  Rose should audit these slices before commit, not only larger family or TMB
  changes.
- Future family work should start by naming parameter meanings, links,
  inverse links, fitted-response rule, and variance rule before adding C++.

## Known Limitations

- The helper table is internal and currently mirrors implemented families
  rather than the full future family registry.
- Family objects do not yet expose `native_parameter_meaning`,
  `fitted_response_rule`, or `variance_rule` as programmatic fields.
- No new family likelihood was added in this slice.

## Next Actions

- Commit and push this helper slice.
- Watch GitHub Actions after push.
- Continue with the next staggered phase: likely either distribution-family
  groundwork for Gamma/counts or deeper math-plus-R documentation for the
  current Gaussian location-scale and bivariate location-coscale paths.
