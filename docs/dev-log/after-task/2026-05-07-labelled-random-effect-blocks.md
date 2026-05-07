# After Task: Labelled Gaussian Mu Random-Effect Blocks

Date: 2026-05-07

## Goal

Add the first labelled covariance-block syntax for Gaussian location random
effects while keeping the mathematical claim narrow and testable.

## Implemented

- `bf(y ~ x + (1 | p | id), sigma ~ z)` now accepts a labelled Gaussian `mu`
  random intercept.
- `bf(y ~ x + (1 + x | p | id), sigma ~ z)` now accepts a labelled Gaussian
  `mu` correlated random intercept-slope block.
- The middle name is retained in fitted object names as a covariance-block
  label, for example `cor((Intercept),x | p | ID)`.
- Labelled and unlabelled blocks currently have the same likelihood. The label
  is metadata for naming and for future cross-formula/cross-parameter matching.
- Group-level correlations remain under `corpars$mu`; residual bivariate
  response correlation remains `rho12`.
- Unsupported labelled uses still fail clearly, including non-symbol labels,
  reserved distributional parameter labels such as `rho12`, `q > 2` blocks,
  factor slopes, duplicate overlapping terms, and labelled random effects in
  `sigma`.

## Mathematical Contract

For the currently implemented labelled one-slope block:

```text
y_ij | mu_ij, sigma_ij ~ Normal(mu_ij, sigma_ij^2)
mu_ij = X_mu[ij, ] beta_mu + b_0j + x_ij b_1j
log(sigma_ij) = X_sigma[ij, ] beta_sigma

[b_0j, b_1j]' ~ MVN(0, Sigma_id,p)
Sigma_id,p =
  [sd0^2,          rho_re sd0 sd1;
   rho_re sd0 sd1, sd1^2]

u_j ~ Normal([0, 0]', I)
b_0j = sd0 * u_0j
b_1j = sd1 * (rho_re u_0j + sqrt(1 - rho_re^2) u_1j)
rho_re = 0.999999 * tanh(eta_cor)
```

The label `p` names the group-level covariance block. It is not a predictor, is
not looked up in `data`, and is not the residual bivariate parameter `rho12`.
In the present implementation, `(1 + x | p | id)` and `(1 + x | id)` therefore
fit the same statistical model but produce different group-level output names.
Reserved distributional parameter names such as `rho12` are rejected as labels
so group-level covariance names cannot masquerade as residual correlations.

## Files Changed

- `R/drmTMB.R`
- `tests/testthat/test-gaussian-random-intercepts.R`
- `tests/testthat/test-comparators.R`
- `tests/testthat/test-gaussian-location-scale.R`
- `README.md`
- `NEWS.md`
- `ROADMAP.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/03-likelihoods.md`
- `docs/design/04-random-effects.md`
- `docs/design/05-testing-strategy.md`
- `docs/design/13-gaussian-location-scale-math.md`
- `docs/design/17-correlated-random-effect-blocks.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/known-limitations.md`
- `man/drmTMB.Rd`
- `vignettes/bivariate-coscale.Rmd`
- `vignettes/drmTMB.Rmd`
- `vignettes/formula-grammar.Rmd`
- `vignettes/location-scale.Rmd`

No TMB C++ file changed in this task. The existing non-centered `q = 2`
Gaussian random-effect machinery already covers the labelled block once the R
parser records the label as metadata.

## Checks Run

```text
Rscript -e "devtools::test(filter = 'gaussian-random-intercepts')"
Rscript -e "devtools::test(filter = 'comparators')"
Rscript -e "devtools::test(filter = 'gaussian-location-scale')"
Rscript -e "devtools::document()"
Rscript -e "devtools::test()"
Rscript -e "pkgdown::check_pkgdown()"
Rscript -e "pkgdown::build_site()"
Rscript -e "devtools::check(env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"
```

Results:

- targeted Gaussian random-effect tests: 141 passed, 0 failed;
- targeted comparator tests: 26 passed, 0 failed;
- targeted Gaussian location-scale tests: 40 passed, 0 failed;
- full `devtools::test()`: 299 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: completed successfully;
- `devtools::check(env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))`: 0
  errors, 0 warnings, 0 notes.

## Tests Of The Tests

- The labelled/unlabelled equivalence test checks fixed effects, residual
  scale, random-effect standard deviations, group-level correlation, and
  log-likelihood. This is the correct comparator because labels are metadata
  in the current implementation.
- The labelled `lme4` comparator checks that `(1 + x | p | ID)` has the same
  fitted-model semantics as `lme4::lmer(y ~ x + f + (1 + x | ID), REML =
  FALSE)`.
- Malformed-input tests now cover non-symbol labels, factor slopes, `q > 2`
  labelled blocks, duplicate labelled/unlabelled overlap, duplicate same-group
  blocks with different labels, reserved labels such as `rho12`, and labelled
  random effects in `sigma`.
- Simulation and stability tests cover moderate covariance, near-zero
  correlation, high positive and high negative correlation, small residual
  scale, large residual scale, and missingness.

## Consistency Audit

- Formula grammar, README, vignettes, roadmap, NEWS, known limitations, and
  generated Rd all now describe labelled Gaussian `mu` blocks as implemented.
- Symbolic equations explicitly state that the label names the covariance block
  but does not change the current univariate likelihood.
- Bivariate documentation now states that shared labelled covariance across
  `mu1` and `mu2` remains future work.
- The group-level correlation naming examples use `corpars$mu`, not `rho12`.
- Formula grammar documentation now separates current fixed-effect bivariate
  syntax from future bivariate random-effect syntax.
- pkgdown was rebuilt so the preview site reflects the new implementation
  status.

## What Did Not Go Smoothly

- The first small-residual-scale recovery tolerance was too tight for a
  CRAN-safe finite-sample variance-component test. The test failed, the
  empirical behavior was inspected, and the tolerance was relaxed to a level
  that still catches gross breakage without pretending small-sample scale
  recovery is exact.
- It was easy to overstate what labelled blocks mean. The final docs therefore
  say repeatedly that labels are metadata now and cross-formula covariance
  sharing is a future phase.
- Because this change touched grammar, tests, README, vignettes, generated Rd,
  and design notes, the main risk was stale wording rather than C++ numerical
  behavior.
- A read-only reviewer caught two active consistency problems before commit:
  `rho12` could be used as a misleading covariance-block label, and the formula
  grammar vignette made future bivariate random effects look current. Both were
  fixed in this task.

## Team Learning

- Boole should keep defending a strict grammar distinction between covariance
  labels, data variables, and residual correlation names.
- Gauss confirmed that no C++ likelihood change was needed for this task, which
  kept the implementation smaller and safer.
- Curie's test pattern for grammar changes should combine metadata-equivalence,
  external comparator, simulation recovery, and malformed-input checks.
- Rose's after-task audit should always search both source docs and generated
  pkgdown pages after user-facing wording changes.
- Ada should keep using parallel agents for review and test design while
  preserving one integrator for tightly coupled parser/test/doc edits.

## Known Limitations

- Labels do not yet connect covariance blocks across `mu1`, `mu2`, `sigma`, or
  other distributional parameters.
- Random effects in `sigma` remain unsupported.
- Bivariate group-level random effects remain unsupported.
- Phylogenetic A-inverse and spatial SPDE random effects remain planned.
- Factor random slopes, multi-column random slopes, and `q > 2` correlated
  Gaussian blocks remain unsupported.
- Profile-likelihood confidence intervals for variance components and
  correlations remain a roadmap item.

## Next Actions

- Decide whether the next mixed-model phase is cross-formula labelled covariance
  sharing or random effects in the scale model.
- Add formal accessors for group-level standard deviations and correlations if
  we want users to avoid reading `sdpars` and `corpars` slots directly.
- Add longer optional simulation scripts for boundary and weak-identification
  behavior outside the CRAN-safe test suite.
