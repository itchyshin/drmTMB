# After Task: Adding Families Developer Guide

## Goal

Replace the placeholder `adding-families` developer article with a practical
guide for adding distribution families to `drmTMB`.

## Implemented

- Expanded `vignettes/adding-families.Rmd` into a full workflow.
- Defined the package scope for families: one response or two responses, one
  formula per distributional parameter, and no family treated as complete
  without tests and documentation.
- Defined location, scale, shape, and coscale at first use.
- Used the implemented Student-t and bivariate Gaussian patterns to show:
  - symbolic equations;
  - matching `drmTMB` syntax;
  - registry fields;
  - builder responsibilities;
  - TMB likelihood requirements;
  - simulation and method support;
  - recovery, independent likelihood, comparator, and rejection tests;
  - documentation and after-task closure.

## Mathematical Contract

The article uses the same family contract expected from implementation work:

```text
family = symbolic model + registry + builder + TMB likelihood + simulation +
         tests + docs + after-task audit
```

The main worked univariate example is the implemented Student-t model:

```text
y_i | mu_i, sigma_i, nu_i ~ Student-t(mu_i, sigma_i, nu_i)
mu_i = X_mu[i, ] beta_mu
log(sigma_i) = X_sigma[i, ] beta_sigma
nu_i = 2 + exp(X_nu[i, ] beta_nu)
```

The main worked bivariate example is the implemented Gaussian location-coscale
model:

```text
[y1_i, y2_i]' ~ MVN([mu1_i, mu2_i]', Omega_i)
Omega_i[1,2] = rho12_i sigma1_i sigma2_i
rho12_i = tanh(eta_rho12_i)
```

## Files Changed

- `vignettes/adding-families.Rmd`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-08-adding-families-developer-guide.md`

## Checks Run

- `Rscript -e "rmarkdown::render('vignettes/adding-families.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `git diff --check`
- `rg -n 'This developer article will|rho ~|tau ~|meta_gaussian|family = c\\(gaussian\\(\\), poisson\\(\\)\\)|skew_normal\\(\\)|bivariate random effects|bivariate Student-t|sparse known covariance|not implemented|planned' vignettes/adding-families.Rmd`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results:

- direct vignette render: passed;
- `git diff --check`: clean;
- prose-style review: passed with no follow-up edits needed; the article names
  contributors as the reader, leads with the family contract, and pairs
  equations with supported syntax;
- stale/unsupported-syntax scan: no old placeholder text, no `rho ~`, no
  `tau ~`, no `meta_gaussian`, no mixed composed-family runnable example, and
  no skew-normal runnable example. Remaining hits are intentional planned-syntax
  or rejection-message wording;
- `pkgdown::check_pkgdown()`: no problems found;
- full `devtools::test()`: 642 passed, 0 failed;
- `pkgdown::build_site()`: rebuilt successfully;
- `devtools::check(...)`: 0 errors, 0 warnings, 0 notes.

## Tests Of The Tests

No package code changed. The article itself now points contributors to the
existing test patterns that future family changes must use:

- Student-t independent likelihood checks;
- simulation recovery;
- method checks for prediction, simulation, residuals, summaries, and
  diagnostics;
- unsupported-combination rejection tests;
- comparator checks where established software has an overlapping
  parameterization.

## Consistency Audit

- The article does not present mixed composed families, bivariate Student-t,
  sparse known covariance, bivariate random effects, or skew-normal as runnable
  implemented syntax.
- `rho12` is used for residual bivariate correlation; `rho ~` is not introduced.
- `tau` appears only as the second canonical shape parameter name, not as
  meta-analysis heterogeneity syntax.
- `meta_gaussian()` is not introduced.
- No `NEWS.md` update was needed because this was developer documentation, not a
  user-facing API or fitted-model behaviour change.

## What Did Not Go Smoothly

Nothing major. The main risk was accidentally teaching planned syntax as
implemented syntax, so the stale-wording scan explicitly checked for those
terms.

## Team Learning

The family article should be the bridge between the `add-family` skill and the
human-readable pkgdown site. It gives future contributors the checklist without
requiring them to know the agent skill system.

## Known Limitations

- This task did not add a new family.
- The article does not yet include a complete line-by-line patch example for a
  future family; it describes the required workflow and uses existing
  implemented families as patterns.

## Next Actions

- Add a source-map note that points from each implemented family to its builder,
  TMB branch, tests, methods, and docs.
- When the next family is added, update this article with a compact before/after
  patch map from the real implementation.
