# After Task: Equation And Syntax Pairing

## Task Goal

Make the first public teaching layer more faithful to Shinichi's modelling
workflow: write the symbolic model, then show the exact `drmTMB` syntax that
fits it. This task focused on documentation and design consistency, not new
model-fitting code.

## Files Changed

- `vignettes/location-scale.Rmd`
  - Added a model-first explanation for Gaussian location-scale regression.
  - Added a symbol-to-R-syntax mapping for `mu` and residual `sigma`.
  - Added equations for one and two location random-intercept terms.
  - Clarified that `sigma` is residual scale, while random-effect scales should
    be named as group-level standard deviations such as `sd_mu_site`.
  - Added meta-analysis equations for diagonal known sampling variance:
    `yi_i ~ Normal(mu_i, v_i + sigma_i^2)`.
- `vignettes/bivariate-coscale.Rmd`
  - Added the full implemented fixed-effect bivariate Gaussian equations for
    `mu1`, `mu2`, `sigma1`, `sigma2`, and `rho12`.
  - Added a symbol-to-R-syntax mapping for bivariate location-coscale models.
  - Added future group-level random-intercept and random-slope equations to
    distinguish covariance-block correlations from residual `rho12`.
- `vignettes/drmTMB.Rmd`
  - Added the package-level documentation principle that equations should be
    paired with R syntax.
  - Cleaned the meta-analysis example indentation.
- `docs/design/13-gaussian-location-scale-math.md`
  - Added the source-of-truth documentation mapping table.
  - Added explicit random-intercept scale equations for two grouping factors.
  - Added the meta-analysis naming rule: `sigma` is the extra heterogeneity SD,
    traditionally called `tau` in meta-analysis prose.
- `docs/design/03-likelihoods.md`
  - Added the bivariate linear predictors to the likelihood specification.
  - Added future group-level covariance-block equations and clarified that
    their correlations are not residual `rho12`.
- `docs/dev-log/check-log.md`
  - Added this task's checks and outcomes.

## Checks Run

- `git diff --check`
- `rg` scans for stale or risky wording:
  - `O'Dea-style`
  - `biological data`
  - `meta_gaussian()`
  - `tau ~`
  - `rho ~`
  - `biv_gaussian()` prototype mentions
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`
- `air format .`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `rg` checks over generated `pkgdown-site/articles` for the new equation
  section headings.

## Exact Outcomes

- `git diff --check`: passed.
- Stale-wording scan: no accidental `O'Dea-style`, `biological data`,
  `meta_gaussian()`, `tau ~`, or `rho ~` examples in active public docs.
  Remaining `meta_gaussian()` and `tau ~` matches are intentional guardrails in
  design/dev-log notes. Remaining `biv_gaussian()` matches are intentional
  because it is the implemented bivariate prototype.
- `devtools::test()`: 148 passed, 0 failed, 0 warnings, 0 skips.
- `pkgdown::check_pkgdown()`: no problems found.
- `pkgdown::build_site()`: completed successfully.
- `air format .`: unavailable locally (`zsh:1: command not found: air`).
- `devtools::check(...)`: 0 errors, 0 warnings, 0 notes.
- Generated pkgdown HTML contains:
  - `Model equations and matching R syntax`;
  - `Meta-analysis as Gaussian regression`;
  - `Equations for the implemented model`;
  - `Future group-level equations`.

## Consistency Audit

- The location-scale tutorial, `docs/design/13-gaussian-location-scale-math.md`,
  and `docs/design/03-likelihoods.md` now use the same roles for `mu`,
  residual `sigma`, and group-level standard deviations.
- The bivariate tutorial and likelihood design note now use the same residual
  covariance equation:
  `Omega_i[1,2] = rho12_i * sigma1_i * sigma2_i`.
- `rho12` remains reserved for residual response-response correlation.
  Group-level correlations are documented as entries of covariance blocks such
  as `Sigma_mu_ID`, not as `rho12`.
- Meta-analysis remains Gaussian regression with `meta_known_V(V = vi)` and
  `family = gaussian()`, not a separate `meta_gaussian()` family.
- The public site framing remains broad: examples lean ecological/evolutionary,
  but the package is not described as only for biological data.

## Tests Of The Tests

No new tests were added because this was a documentation/design task. The test
suite was still run in full to ensure the examples and package state remained
coherent. `devtools::check()` also rebuilt vignettes and reran examples, which
is the relevant test that the revised R Markdown is syntactically valid and the
package can still be checked end to end.

## Design-Doc Updates

The main source-of-truth updates are in:

- `docs/design/13-gaussian-location-scale-math.md`
- `docs/design/03-likelihoods.md`

These were updated in the same task as the vignettes so the public tutorials
and design notes do not drift apart.

## Pkgdown Updates

No navigation changes were needed. The existing pkgdown build now renders the
expanded equation sections in:

- `articles/location-scale.html`
- `articles/bivariate-coscale.html`
- `articles/drmTMB.html`

## Known Limitations And Next Actions

- This task did not implement new model code.
- Random slopes, bivariate random effects, full or block-diagonal
  `meta_known_V(V = V)`, phylogenetic A-inverse, and spatial SPDE remain future
  implementation tasks.
- A later task should add the same equation-plus-syntax pattern to the
  meta-analysis, phylogenetic/spatial, and distribution-family roadmap pages.
- Once `drm_formula()` and `family = c(gaussian(), gaussian())` are implemented,
  examples should be revised so the planned public grammar and actual
  implementation no longer diverge.
