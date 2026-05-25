# After-Task Report: Truncated NB2 `mu` Random Intercept

Date: 2026-05-25

Branch: `codex/truncated-nb2-mu-random-intercept`

## Purpose

Add the next count-adjacent family slice toward ordinary location random
intercepts across fitted one-response families. This slice admits only
ordinary zero-truncated NB2 `mu` random intercepts:

```r
drmTMB(
  bf(count ~ x + (1 | id), sigma ~ z),
  family = truncated_nbinom2(),
  data = dat
)
```

The fitted positive-count component remains

```text
y_i | y_i > 0 ~ NB2(mu_i, sigma_i) truncated at zero
log(mu_i) = x_i beta_mu + b_id[i]
log(sigma_i) = z_i beta_sigma
b_j ~ Normal(0, sd_id^2)
```

## Scope Boundary

This task did not add hurdle NB2 random effects, zero-truncated random slopes,
labelled covariance blocks, structured effects, overdispersion-side random
effects, or zero-inflated count random effects. Those remain separate
likelihood, extractor, diagnostic, interval, and simulation gates.

## Implementation Notes

- `drm_build_truncated_nbinom2_spec()` now extracts and validates ordinary
  `mu` random-intercept terms for non-hurdle zero-truncated NB2 fits.
- The TMB `model_type == 11` branch now adds the `u_mu` contribution to
  `eta_mu` before evaluating the zero-truncated NB2 likelihood.
- `sdpars`, `random_effects`, and `check_drm()` now see the admitted
  zero-truncated NB2 `mu` random-intercept surface.
- Family docs, the family registry, the Phase 18 family map, the readiness
  matrix, and NEWS were updated to keep the claim narrow.

## Review Roles

- Ada kept the implementation stacked on the common-family artifact lane.
- Boole checked that only the ordinary `(1 | id)` location syntax was admitted.
- Curie added focused deterministic recovery and boundary tests.
- Fisher checked that the test is source-level evidence, not a formal grid.
- Grace checked parse, focused tests, documentation generation, and diff
  hygiene.
- Rose kept hurdle, slope, sigma, and structured neighbors out of the fitted
  claim.
- No spawned subagents were running in this session.

## Validation

```sh
Rscript -e "files <- c('R/drmTMB.R','R/check.R','tests/testthat/test-truncated-nbinom2-location-scale.R'); invisible(lapply(files, parse)); cat('parse ok\n')"
Rscript -e "devtools::test(filter = '^truncated-nbinom2-location-scale$', reporter = 'summary')"
Rscript -e "devtools::test(filter = '^(truncated-nbinom2-location-scale|check-drm|profile-targets)$', reporter = 'summary')"
Rscript -e "devtools::document()"
air format R/drmTMB.R R/check.R R/family.R src/drmTMB.cpp tests/testthat/test-truncated-nbinom2-location-scale.R NEWS.md docs/design/02-family-registry.md docs/design/46-pre-simulation-readiness-matrix.md docs/design/109-phase-18-core-family-completion-map-slices-1279-1288.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-25-truncated-nb2-mu-random-intercept.md
git diff --check
```

## Next Gate

The next ordinary location random-intercept candidates are positive-continuous
`lognormal()` and `Gamma(link = "log")`, followed by `student()`, bounded
`beta()` / `beta_binomial()`, and then ordinal `cumulative_logit()` once the
cutpoint/random-intercept identifiability gate is explicitly designed.
