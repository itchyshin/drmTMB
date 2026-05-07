# After Task: Formula, Family, Audience, and Validation Refinements

Date: 2026-05-07

## Task

Fold the user's formula, family, random-correlation, audience, agent-team, and
validation decisions into durable repository documents before moving to the next
modelling feature.

## Created Or Changed

- Updated `DESCRIPTION` to list Shinichi Nakagawa as author, maintainer, and
  copyright holder with ORCID `0000-0002-7765-5182`.
- Updated the vision and formula grammar docs to say `drmTMB` should not copy
  `brms` wholesale.
- Recorded `formula = drm_formula(...)` as the likely canonical long-form
  direction, with `bf()` retained as the prototype helper for now.
- Recorded composed bivariate families such as
  `family = c(gaussian(), gaussian())` and
  `family = c(gaussian(), poisson())` as the public design direction.
- Clarified that every estimated distributional parameter can have a formula,
  but only a staged subset should accept random-effect terms.
- Clarified that residual `rho12` is different from group-level covariance-block
  correlations in O'Dea-style double-hierarchical models.
- Added an O'Dea correlation taxonomy note for personality, plasticity,
  predictability, and malleability.
- Added the two-tier validation strategy: comparator-package smoke tests plus
  simulation recovery.
- Retitled pkgdown tutorial pages toward ecological, evolutionary, and
  environmental audiences.
- Added the current agent-team table and new-conversation handoff instructions
  to `docs/design/07-collaboration-and-site.md`.
- Replaced generic `z`/`w` examples in active docs with `x1`, `x2`, and `x3`
  so users do not infer special predictor namespaces.

## Checks Performed

- `air format .`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- Stale-text scan for placeholder author metadata and old `z`/`w` formula
  examples.

## Outcomes

- Full test suite: 139 passed, 0 failed.
- pkgdown check: no problems found.
- pkgdown site: built successfully.
- R CMD check with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors, 0 warnings,
  0 notes.
- `air format .` was attempted but `air` is not installed locally.
- Stale-text scan found no placeholder maintainer metadata or old `z`/`w`
  formula examples in active docs.

## Consistency Review

- Formula examples now consistently use `x1`, `x2`, and `x3`.
- Meta-analysis remains Gaussian regression with `meta_known_V(V = V)`, not a
  `meta_gaussian()` family.
- `sigma` remains the public scale name, with documentation explaining the
  meta-analysis translation to `tau`.
- `rho12` is reserved for residual correlation between two responses.
- O'Dea-style correlations are documented as group-level covariance-block
  correlations, not `rho12` formulae.
- The pkgdown navigation and vignette titles now use more biological language.

## Remaining Limitations

- `drm_formula()` is a design direction and is not implemented yet.
- `family = c(gaussian(), gaussian())` is a design direction and is not
  implemented yet.
- `biv_gaussian()` remains the current implemented bivariate Gaussian prototype.
- Comparator-package tests are planned but not yet implemented.
- Random slopes, scale random effects, random-effect scale formulae, phylogeny,
  spatial fields, and non-Gaussian families remain future work.

## Next Best Task

The next coherent implementation task is either:

1. add random slopes in the univariate Gaussian `mu` formula; or
2. add the first comparator-package validation tests for Gaussian random
   intercepts against `lme4` and meta-analysis against `metafor`.
