# After Task: Random-Effect Scale Design And Equation Pairing

## Goal

Prepare the next modelling phase by writing a design-first contract for
`sd(id) ~ x_group` and by making the active documentation pair symbolic
equations with R syntax.

## Implemented

This was a design/documentation phase, not a likelihood implementation phase.

- Added `docs/design/18-random-effect-scale-models.md`.
- Added `vignettes/which-scale.Rmd`.
- Added the new tutorial to `_pkgdown.yml`.
- Corrected stale implementation-status wording in design docs and vignettes.
- Corrected `bf()` examples so generated help shows implemented bivariate
  fixed-effect syntax, not future bivariate random-effect syntax.
- Updated `CLAUDE.md` so Claude Code sees the same syntax boundary.
- Expanded the correlation roadmap to include future phylogenetic,
  non-phylogenetic species, spatial, study/site, and other group-level
  correlations, separate from residual `rho12`.

## Mathematical Contract

Implemented residual scale:

```text
y_i | mu_i, sigma_i ~ Normal(mu_i, sigma_i^2)
mu_i = X_mu[i, ] beta_mu
log(sigma_i) = X_sigma[i, ] beta_sigma
```

Implemented residual-scale random intercept:

```text
log(sigma_ij) = X_sigma[ij, ] beta_sigma + a_j
a_j = sd_sigma_id v_j
v_j ~ Normal(0, 1)
```

Planned random-effect scale model:

```text
mu_ij = X_mu[ij, ] beta_mu + b_j
b_j = sd_mu_id,j u_j
u_j ~ Normal(0, 1)
log(sd_mu_id,j) = W_id[j, ] alpha_id
```

Planned bivariate structured correlations:

```text
rho12_i                 # residual response-response correlation
cor(a_mu1, a_mu2)       # phylogenetic or structured mean-mean correlation
cor(c_mu1, c_mu2)       # non-phylogenetic species/group mean-mean correlation
cor(a_sigma1, a_sigma2) # structured scale-scale correlation
```

The public namespace should keep these levels separate. Residual `rho12` is
not the only correlation drmTMB should eventually estimate.

## Files Changed

- `CLAUDE.md`
- `R/bf.R`
- `man/bf.Rd`
- `README.md`
- `ROADMAP.md`
- `_pkgdown.yml`
- `docs/design/01-formula-grammar.md`
- `docs/design/02-family-registry.md`
- `docs/design/05-testing-strategy.md`
- `docs/design/10-after-task-protocol.md`
- `docs/design/13-gaussian-location-scale-math.md`
- `docs/design/15-location-coscale-phylogenetic-extension.md`
- `docs/design/16-phylo-spatial-common-math.md`
- `docs/design/18-random-effect-scale-models.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/known-limitations.md`
- `vignettes/bivariate-coscale.Rmd`
- `vignettes/location-scale.Rmd`
- `vignettes/phylogenetic-spatial.Rmd`
- `vignettes/which-scale.Rmd`

## Checks Run

- `gh run list --branch main --limit 6`
  - Latest remote R-CMD-check and pkgdown runs for `44e86be` were successful.
- `Rscript -e "devtools::document()"`
  - Completed and regenerated `man/bf.Rd`.
- `Rscript -e "devtools::test()"`
  - 326 passed, 0 failed, 0 warnings, 0 skipped.
- `Rscript -e "pkgdown::check_pkgdown()"`
  - No problems found.
- `Rscript -e "pkgdown::build_site()"`
  - Completed and rendered `articles/which-scale.html`.
- `Rscript -e "devtools::check(env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
  - 0 errors, 0 warnings, 0 notes.
- `Rscript -e "pkgdown::build_site()"`
  - Re-run after the `CLAUDE.md` consistency edit; completed successfully.

## Tests Of The Tests

No model code changed, so no new simulation tests were added. Existing tests
were still run in full to verify that documentation and roxygen changes did
not disturb the current Gaussian, meta-analysis, bivariate, or parser
behaviour.

The generated pkgdown site was rebuilt and searched for the new tutorial title,
`sd(population)`, and stale implementation-status wording. The site now links
to "Which scale are you modelling?" from the Tutorials menu and article index.

## Consistency Audit

Corrected live stale wording caught by Rose:

- `docs/design/01-formula-grammar.md` now states that univariate Gaussian
  residual-scale random intercepts in `sigma` are implemented.
- `docs/design/13-gaussian-location-scale-math.md` now maps
  `random_effects$sigma`, `log_sd_sigma`, and `u_sigma`.
- `docs/design/02-family-registry.md` now describes implemented correlated
  `mu` blocks and residual-scale `sigma` random intercepts.
- `docs/design/16-phylo-spatial-common-math.md` now describes the actual
  current Gaussian baseline before phylogenetic and spatial terms.
- `vignettes/location-scale.Rmd` now mentions residual-scale random intercepts
  in its opening.
- `R/bf.R` and `man/bf.Rd` no longer show future bivariate random effects as
  if they were the current example.

Intentional remaining matches:

- `meta_gaussian()` and `tau ~` remain as guardrails against unwanted syntax.
- `sd(id) ~ x` and `sd(group)` appear only as planned random-effect scale
  syntax, not as implemented syntax.
- Historical after-task notes still contain wording that was true when written.

## What Did Not Go Smoothly

The previous residual-scale random-intercept after-task report claimed the
docs were fully synchronized, but Rose found live design files that still
underreported implemented `sigma` random intercepts. The implementation and
tests were correct; the forest-and-trees audit was incomplete.

This phase fixed the missed files and added stronger stale-wording searches to
`docs/design/10-after-task-protocol.md`.

## Team Learning

- Pat emphasized that users need a side-by-side guide before seeing many
  formulas.
- Noether emphasized that future `sd(id) ~ x` syntax requires explicit
  equations before implementation.
- Rose caught the stale status-table problem and improved the audit loop.
- Shinichi's Ortega et al. protocol reminder clarified that the correlation
  roadmap must include phylogenetic and non-phylogenetic correlations, not only
  residual `rho12`.

## Known Limitations

- `sd(id) ~ x_group` is not implemented.
- The first implementation should target exactly one univariate Gaussian `mu`
  random intercept.
- Group-level predictors for `sd(id) ~ x_group` must be checked for
  within-group constancy.
- Exact public naming for structured correlations such as phylogenetic,
  non-phylogenetic species, spatial, and study/site correlations remains a
  design task before implementation.

## Next Actions

1. Implement the first `sd(id) ~ x_group` MVP after this design is accepted.
2. Add simulation recovery and malformed-input tests for the random-effect
   scale model.
3. Keep the new "Which scale are you modelling?" article synchronized with
   code as each scale component becomes implemented.
4. Ask Noether/Gauss to review the TMB parameterization before coding the
   `sd(id)` likelihood path.
