# 2026-05-25 - Positive-Continuous `mu` Random Intercepts

Goal:

- Add the next positive-continuous mixed-model slice:
  `lognormal()` and `Gamma(link = "log")` with
  `bf(y ~ x + (1 | id), sigma ~ z)`.

Changes:

- Wired ordinary unlabelled `mu` random intercepts through the lognormal and
  Gamma builders, TMB data, likelihood branches, starts/maps, `sdpars`,
  `random_effects`, direct profile targets, and `check_drm()`.
- Added focused deterministic recovery tests for convergence, fixed effects,
  random-effect SDs, conditional random effects, in-sample prediction
  contributions, profile-target rows, and replication diagnostics.
- Added guardrail tests that keep positive-continuous random slopes, labelled
  covariance blocks, `sigma` random effects, random-effect scale formulae,
  structured effects, known covariance, and bivariate or mixed
  positive-continuous models out of the fitted surface.
- Updated the family registry, Phase 18 core map, readiness matrix, `NEWS.md`,
  `drmTMB()` roxygen, and `lognormal()` roxygen.

Member-group review:

- Ada kept the slice stacked on the zero-truncated NB2 random-intercept lane.
- Boole checked that the admitted syntax is only ordinary `(1 | id)` in
  positive-continuous `mu` formulas.
- Gauss and Noether checked that the latent effect is added on the log-response
  location for lognormal and the log-mean predictor for Gamma.
- Curie and Fisher checked that the source tests recover fixed effects,
  random-effect SDs, and conditional random effects without claiming a formal
  grid.
- Grace checked parse, focused tests, documentation generation, formatting,
  and diff hygiene.
- Rose checked that stale fixed-effect-only claims were narrowed without
  promoting slopes, `sigma` effects, structured positive responses, or
  bivariate positive-continuous models.
- No spawned subagents were running.

Validation:

```sh
Rscript -e "files <- c('R/drmTMB.R','R/check.R','R/family.R','tests/testthat/test-lognormal-location-scale.R','tests/testthat/test-gamma-location-scale.R'); invisible(lapply(files, parse)); cat('ok parse\n')"
Rscript -e "devtools::test(filter = '^(lognormal-location-scale|gamma-location-scale)$', reporter = 'summary')"
Rscript -e "devtools::test(filter = '^(lognormal-location-scale|gamma-location-scale|check-drm|profile-targets)$', reporter = 'summary')"
Rscript -e "devtools::document()"
air format R/drmTMB.R R/check.R R/family.R src/drmTMB.cpp tests/testthat/test-lognormal-location-scale.R tests/testthat/test-gamma-location-scale.R README.md ROADMAP.md NEWS.md docs/design/01-formula-grammar.md docs/design/02-family-registry.md docs/design/41-phase-18-simulation-programme.md docs/design/46-pre-simulation-readiness-matrix.md docs/design/109-phase-18-core-family-completion-map-slices-1279-1288.md docs/design/111-phase-18-positive-continuous-fixed-effect-artifacts-slices-1299-1308.md docs/dev-log/check-log.md docs/dev-log/known-limitations.md docs/dev-log/after-task/2026-05-25-positive-continuous-mu-random-intercepts.md
rg --pcre2 -n 'positive-continuous.*fixed-effect only|lognormal.*fixed-effect only|Gamma.*fixed-effect only|positive-continuous random effects.*remain excluded|lognormal.*random effects.*later|Gamma.*random effects.*later|lognormal/Gamma/Student-t follow only|positive-response random effects(?! beyond)' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests man -g '!*.html'
git diff --check
```

Results:

- The parse check passed before and after formatting.
- Focused lognormal/Gamma tests passed.
- Broader focused tests for lognormal/Gamma, `check_drm()`, and
  `profile_targets()` passed.
- `devtools::document()` regenerated `man/drmTMB.Rd` and
  `man/lognormal.Rd`.
- Formatting completed without output.
- The stale-wording scan returned only intentional boundary statements about
  `sigma` random effects, random slopes, and positive-continuous neighbours
  that remain planned.
- `git diff --check` was clean.
