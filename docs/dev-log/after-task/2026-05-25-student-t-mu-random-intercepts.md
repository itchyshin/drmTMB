# After Task: Student-t `mu` Random Intercepts

## Goal

Add the first Student-t mixed-model source slice: ordinary unlabelled `mu`
random intercepts with `bf(y ~ x + (1 | id), sigma ~ z, nu ~ 1)`.

## Implemented

Student-t `mu` random intercepts now enter the identity-location predictor and
are exposed through `sdpars$mu`, `random_effects$mu`, `profile_targets()`,
`predict(dpar = "mu")`, and `check_drm()` replication diagnostics.

## Mathematical Contract

For observation `i` in group `g[i]`,

```text
y_i ~ Student-t(mu_i, sigma_i, nu_i)
mu_i = X_mu[i, ] beta_mu + b_g[i]
b_g = sd_mu * u_g
u_g ~ Normal(0, 1)
sigma_i = exp(X_sigma[i, ] beta_sigma)
nu_i = 2 + exp(X_nu[i, ] beta_nu)
```

The slice does not add Student-t random slopes, labelled covariance blocks,
`sigma` random effects, `nu` random effects, structured effects, known
covariance, or bivariate Student-t models.

## Files Changed

- `R/drmTMB.R`
- `R/check.R`
- `R/family.R`
- `src/drmTMB.cpp`
- `tests/testthat/test-student-location-scale.R`
- `README.md`
- `ROADMAP.md`
- `NEWS.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/02-family-registry.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/known-limitations.md`
- `vignettes/formula-grammar.Rmd`
- `man/drmTMB.Rd`
- `man/student.Rd`

## Checks Run

```sh
Rscript -e "files <- c('R/drmTMB.R','R/check.R','R/family.R','tests/testthat/test-student-location-scale.R'); invisible(lapply(files, parse)); cat('ok parse\n')"
Rscript -e "devtools::test(filter = 'student-location-scale', reporter = 'summary')"
Rscript -e "devtools::test(filter = '^(student-location-scale|check-drm|profile-targets)$', reporter = 'summary')"
Rscript -e "devtools::document()"
air format R/drmTMB.R R/check.R R/family.R src/drmTMB.cpp tests/testthat/test-student-location-scale.R README.md ROADMAP.md NEWS.md docs/design/01-formula-grammar.md docs/design/02-family-registry.md docs/design/46-pre-simulation-readiness-matrix.md docs/dev-log/known-limitations.md docs/dev-log/check-log.md vignettes/formula-grammar.Rmd
rg --pcre2 -n 'Student-t.*fixed-effect only|student\\(\\).*fixed-effect only|Student-t random effects|Student-t.*random effects.*later|Student-t.*mu.*planned|ordinary Student-t.*source-test|Student-t/zero-truncated|Student-t random slopes|nu random effects|student\\(\\).*random intercept' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests man -g '!*.html'
git diff --check
```

All listed checks passed. The stale-wording scan returned only intentional
boundary statements about Student-t random slopes, `sigma` random effects,
`nu` random effects, structured effects, known covariance, and bivariate
Student-t models that remain planned.

## Tests Of The Tests

The new recovery test fits simulated grouped Student-t data and checks
convergence, positive-definite Hessian status, fixed effects, random-effect SD,
conditional random-effect correlation with the simulated group effects, direct
`log_sd_mu` profile-target exposure, `predict(dpar = "mu")` random-effect
contributions, `check_drm()` replication rows, and Student-t `nu` diagnostics.
Neighbouring malformed formulas check that random slopes, labelled covariance,
and `sigma` random effects still fail before fitting.

## Consistency Audit

The implementation, formula grammar, family registry, readiness matrix, README,
ROADMAP, NEWS, known limitations, generated Rd files, and formula-grammar
vignette now agree that only ordinary Student-t `mu` random intercepts are
fitted.

## GitHub Issue Maintenance

No GitHub issue was updated in this slice. This work is a stacked continuation
of the Phase 18 common-family family-coverage PR lane rather than a separate
issue closeout.

## What Did Not Go Smoothly

The first stale-wording scan correctly caught `vignettes/formula-grammar.Rmd`
still saying "Student-t random effects" broadly. The vignette now distinguishes
ordinary `mu` random intercepts from the still-planned slope, scale, shape, and
structured neighbours.

## Team Learning

Ada kept the branch stacked and narrow. Boole checked syntax boundaries. Gauss
and Noether checked the identity-location predictor contract. Curie and Fisher
kept the recovery test source-level rather than formal-grid evidence. Grace
verified parse, tests, documentation, formatting, stale wording, and diff
hygiene. Rose checked that nearby Student-t surfaces remain explicitly planned.
No spawned subagents were running.

## Known Limitations

Student-t random slopes, labelled covariance blocks, `sigma` random effects,
`nu` random effects, structured effects, known covariance, and bivariate
Student-t models remain planned or unsupported.

## Next Actions

Continue the family-coverage stack with bounded-response `mu` random-intercept
evidence, likely `beta()` before `beta_binomial()`, unless the maintainer
prefers to pause for PR review.
